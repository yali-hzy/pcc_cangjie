package pcc_cangjie.check

import pcc_cangjie.defs.{Context, ContextChangeType}
import pcc_cangjie.collection.{Links, Link, LinkType}
import pcc_cangjie.logger.LOGGER
import std.collection.ArrayList
import std.sort.sort
import std.time.MonoTime
import pcc_cangjie.defs.DebugInfo
import pcc_cangjie.defs.{maxUsedHeapSize, maxAllocatedHeapSize}
import std.runtime.{getUsedHeapSize, getAllocatedHeapSize}

interface PccEvaluatorListener <: Evaluator {
    func exitForall(node: ForallNode, newNode: CctNode): Unit
    func exitExists(node: ExistsNode, newNode: CctNode): Unit
}

interface PccGeneratorListener <: Generator {
    func exitForall(node: ForallNode, newNode: CctNode): Unit
    func exitExists(node: ExistsNode, newNode: CctNode): Unit
}

class PccListener <: CheckListener<PccEvaluatorListener, PccGeneratorListener> {
    init() {
        super(PccEvaluator(), PccGenerator())
    }

    public func exitForall(node: ForallNode, newNode: CctNode): Unit {
        evaluator.exitForall(node, newNode)
        generator.exitForall(node, newNode)
    }

    public func exitExists(node: ExistsNode, newNode: CctNode): Unit {
        evaluator.exitExists(node, newNode)
        generator.exitExists(node, newNode)
    }
}

class PccMethod <: CheckMethod {
    let pccAdjuster: PccAdjuster

    init(checker: CctChecker) {
        this.pccAdjuster = PccAdjuster(CctBuilder(checker))
    }

    public func handleAdd(cct: Cct, nodeList: ArrayList<Int>, contextId: Int, context: Context): Unit {
        DebugInfo.reset()
        let time = MonoTime.now()
        let sortedNodeList = nodeList.clone()
        sort(sortedNodeList, key: {nodeId => cct.syntaxTree.nodes[nodeId].depth}, descending: true)
        for (nodeId in sortedNodeList) {
            pccAdjuster.handleAdd(cct, nodeId, contextId, context)
        }
        let elapsed = MonoTime.now() - time
        let result = cct.link
        for (link in result) {
            LOGGER.getOrThrow().log(link)
        }
        LOGGER.getOrThrow().addDuration(elapsed)
        if (elapsed > Duration.millisecond * 100) {
            println("Warning: Handling add for context ${contextId} in constraint ${cct.syntaxTree.name} with nodeList ${nodeList} took ${elapsed}, which may indicate a performance issue.")
            println(DebugInfo())
        }
        maxUsedHeapSize = max(maxUsedHeapSize, getUsedHeapSize())
        maxAllocatedHeapSize = max(maxAllocatedHeapSize, getAllocatedHeapSize())
    }

    public func handleDelete(cct: Cct, nodeList: ArrayList<Int>, contextId: Int): Unit {
        DebugInfo.reset()
        let time = MonoTime.now()
        let sortedNodeList = nodeList.clone()
        sort(sortedNodeList, key: {nodeId => cct.syntaxTree.nodes[nodeId].depth})
        for (nodeId in sortedNodeList) {
            pccAdjuster.handleDelete(cct, nodeId, contextId)
        }
        let elapsed = MonoTime.now() - time
        let result = cct.link
        for (link in result) {
            LOGGER.getOrThrow().log(link)
        }
        LOGGER.getOrThrow().addDuration(elapsed)
        if (elapsed > Duration.millisecond * 100) {
            println("Warning: Handling delete for context ${contextId} in constraint ${cct.syntaxTree.name} with nodeList ${nodeList} took ${elapsed}, which may indicate a performance issue.")
            println(DebugInfo())
        }
        maxUsedHeapSize = max(maxUsedHeapSize, getUsedHeapSize())
        maxAllocatedHeapSize = max(maxAllocatedHeapSize, getAllocatedHeapSize())
    }
}

class PccAdjuster {
    let listener = PccListener()
    var affected: Array<Bool> = []
    var syntaxTreeNodeId: Int = -1
    var contextId: Int = -1
    var context: Context = Context.POISON_CONTEXT
    var contextChangeType: ContextChangeType = ContextChangeType.Add

    PccAdjuster(let cctBuilder: CctBuilder) {}

    private func initAdjust(syntaxTree: SyntaxTree, nodeId: Int, changeType: ContextChangeType, contextId: Int) {
        this.syntaxTreeNodeId = nodeId
        this.contextId = contextId
        this.contextChangeType = changeType
        let nodeCount = syntaxTree.nodes.size
        affected = Array(nodeCount, repeat: false)
        var currentNode: ?SyntaxTreeNode = syntaxTree.nodes[nodeId]
        while (let Some(node) <- currentNode) {
            affected[node.dfn] = true
            currentNode = node.parent
        }
    }

    private func initAdjust(syntaxTree: SyntaxTree, dfn: Int, changeType: ContextChangeType, contextId: Int,
        context: Context) {
        this.context = context
        initAdjust(syntaxTree, dfn, changeType, contextId)
    }

    private func adjustHelper(node: CctNode): Unit {
        if (!affected[node.syntaxTreeNode.dfn]) {
            return
        }
        if (syntaxTreeNodeId == node.syntaxTreeNode.dfn) {
            match (node) {
                case node: QuantifierNode => match (contextChangeType) {
                    case ContextChangeType.Add =>
                        let newNode = cctBuilder.build(node.syntaxTreeNode.children[0], parent: node, ctx: context)
                        match (node) {
                            case forallNode: ForallNode => listener.exitForall(forallNode, newNode)
                            case existsNode: ExistsNode => listener.exitExists(existsNode, newNode)
                            case _ => throw IllegalStateException(
                                "Unexpected quantifier node type ${node.syntaxTreeNode.nodeType}")
                        }
                        node.ctx2child[contextId] = newNode
                    case ContextChangeType.Delete =>
                        node.ctx2child.remove(contextId)
                        match (node) {
                            case forallNode: ForallNode => listener.exitForall(forallNode)
                            case existsNode: ExistsNode => listener.exitExists(existsNode)
                            case _ => throw IllegalStateException(
                                "Unexpected quantifier node type ${node.syntaxTreeNode.nodeType}")
                        }
                }
                case _ => throw IllegalStateException(
                    "Expected a quantifier node at syntax tree node ${syntaxTreeNodeId}, but got ${node.syntaxTreeNode.nodeType}")
            }
        } else {
            match (node) {
                case node: QuantifierNode =>
                    for ((_, child) in node.ctx2child) {
                        adjustHelper(child)
                    }
                    match (node) {
                        case forallNode: ForallNode => listener.exitForall(forallNode)
                        case existsNode: ExistsNode => listener.exitExists(existsNode)
                        case _ => throw IllegalStateException(
                            "Unexpected quantifier node type ${node.syntaxTreeNode.nodeType}")
                    }
                case node: NonleafNode =>
                    for (child in node.children) {
                        adjustHelper(child)
                    }
                    match (node) {
                        case andNode: AndNode => listener.exitAnd(andNode)
                        case orNode: OrNode => listener.exitOr(orNode)
                        case impliesNode: ImpliesNode => listener.exitImplies(impliesNode)
                        case notNode: NotNode => listener.exitNot(notNode)
                        case _ => throw IllegalStateException(
                            "Unexpected nonleaf node type ${node.syntaxTreeNode.nodeType}")
                    }
                case _ => throw IllegalStateException(
                    "Unexpected leaf node type ${node.syntaxTreeNode.nodeType} in adjustHelper")
            }
        }
    }

    public func handleAdd(cct: Cct, syntaxTreeNodeId: Int, contextId: Int, context: Context): Unit {
        if (let Some(root) <- cct.root) {
            initAdjust(cct.syntaxTree, syntaxTreeNodeId, ContextChangeType.Add, contextId, context)
            adjustHelper(root)
        } else {
            cct.root = cctBuilder.build(cct.syntaxTree.root)
        }
    }

    public func handleDelete(cct: Cct, syntaxTreeNodeId: Int, contextId: Int): Unit {
        initAdjust(cct.syntaxTree, syntaxTreeNodeId, ContextChangeType.Delete, contextId)
        adjustHelper(cct.root.getOrThrow())
    }
}

class PccEvaluator <: EccEvaluator & PccEvaluatorListener {
    public func exitForall(node: ForallNode, newNode: CctNode): Unit {
        node.truthValue &&= newNode.truthValue
    }

    public func exitExists(node: ExistsNode, newNode: CctNode): Unit {
        node.truthValue ||= newNode.truthValue
    }
}

class PccGenerator <: EccGenerator & PccGeneratorListener {
    public func exitForall(node: ForallNode, newNode: CctNode): Unit {
        let startTime = MonoTime.now()
        if (!newNode.truthValue) {
            node.links = node
                .links
                .union(
                    Links(ArrayList([Link(LinkType.Violated, ArrayList([newNode.assignments.getOrThrow().assignment]))]))
                        .product(newNode.links))
        }
        let elapsed = MonoTime.now() - startTime
        DebugInfo.generateForallTime += elapsed
    }

    public func exitExists(node: ExistsNode, newNode: CctNode): Unit {
        let startTime = MonoTime.now()
        if (newNode.truthValue) {
            node.links = node
                .links
                .union(
                    Links(
                        ArrayList([Link(LinkType.Satisfied, ArrayList([newNode.assignments.getOrThrow().assignment]))]))
                        .product(newNode.links))
        }
        let elapsed = MonoTime.now() - startTime
        DebugInfo.generateExistsTime += elapsed
    }
}
