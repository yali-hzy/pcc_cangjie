package pcc_cangjie.check

import pcc_cangjie.defs.{Context, ContextChangeType}
import pcc_cangjie.collection.{Links, Link, LinkType}
import pcc_cangjie.logger.LOGGER
import std.collection.{ArrayList, HashMap}
import std.sort.sort
import std.time.MonoTime
// import pcc_cangjie.defs.DebugInfo
import pcc_cangjie.defs.VERBOSE
import pcc_cangjie.defs.{maxUsedHeapSize, maxAllocatedHeapSize}
import std.runtime.{getUsedHeapSize, getAllocatedHeapSize}
import pcc_cangjie.timing.MockCurrentTime

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
        // DebugInfo.reset()
        let time = MonoTime.now()
        let sortedNodeList = nodeList.clone()
        sort(sortedNodeList, key: {nodeId => cct.syntaxTree.nodes[nodeId].depth}, descending: true)
        for (nodeId in sortedNodeList) {
            pccAdjuster.handleAdd(cct, nodeId, contextId, context)
        }
        let elapsed = MonoTime.now() - time
        // println(
        //     "Handled add for context ${contextId} in constraint ${cct.syntaxTree.name} with nodeList ${nodeList} in ${elapsed}.")
        if (VERBOSE) {
            LOGGER.getOrThrow().log("Time: ${MockCurrentTime}, add ctx ${contextId} to cct ${cct.syntaxTree.name} with node ${nodeList}. Duration: ${elapsed}.")
            let result = cct.verboseLink
            for (link in result) {
                LOGGER.getOrThrow().log(link)
            }
        } else {
            let result = cct.link
            for (link in result) {
                LOGGER.getOrThrow().log(link)
            }
        }
        LOGGER.getOrThrow().addDuration(elapsed, 1)
        // if (elapsed > Duration.millisecond * 100) {
        //     println(
        //         "Warning: Handling add for context ${contextId} in constraint ${cct.syntaxTree.name} with nodeList ${nodeList} took ${elapsed}, which may indicate a performance issue.")
        //     println(DebugInfo())
        // }
        maxUsedHeapSize = max(maxUsedHeapSize, getUsedHeapSize())
        maxAllocatedHeapSize = max(maxAllocatedHeapSize, getAllocatedHeapSize())
    }

    public func handleDelete(cct: Cct, nodeList: ArrayList<Int>, contextId: Int): Unit {
        // DebugInfo.reset()
        let time = MonoTime.now()
        let sortedNodeList = nodeList.clone()
        sort(sortedNodeList, key: {nodeId => cct.syntaxTree.nodes[nodeId].depth})
        for (nodeId in sortedNodeList) {
            pccAdjuster.handleDelete(cct, nodeId, contextId)
        }
        let elapsed = MonoTime.now() - time
        // println("After handling delete for context ${contextId} in constraint ${cct.syntaxTree.name} with nodeList ${nodeList}, links are:")
        if (VERBOSE) {
            LOGGER.getOrThrow().log("Time: ${MockCurrentTime}, delete ctx ${contextId} from cct ${cct.syntaxTree.name} with node ${nodeList}. Duration: ${elapsed}.")
            let result = cct.verboseLink
            for (link in result) {
                LOGGER.getOrThrow().log(link)
            }
        } else {
            let result = cct.link
            for (link in result) {
                LOGGER.getOrThrow().log(link)
            }
        }
        LOGGER.getOrThrow().addDuration(elapsed, 2)
        // if (elapsed > Duration.millisecond * 100) {
        //     println(
        //         "Warning: Handling delete for context ${contextId} in constraint ${cct.syntaxTree.name} with nodeList ${nodeList} took ${elapsed}, which may indicate a performance issue.")
        //     println(DebugInfo())
        // }
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
    var bindings = HashMap<Int, Context>()

    PccAdjuster(let cctBuilder: CctBuilder) {}

    private func initAdjust(syntaxTree: SyntaxTree, nodeId: Int, changeType: ContextChangeType, contextId: Int) {
        this.syntaxTreeNodeId = nodeId
        this.contextId = contextId
        this.contextChangeType = changeType
        let nodeCount = syntaxTree.nodes.size
        this.bindings = HashMap<Int, Context>()
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
                        let oldValue = bindings.add(node.syntaxTreeNode.dfn, context)
                        let newNode = cctBuilder.build(node.syntaxTreeNode.children[0], parent: node, ctx: context,
                            bindings: bindings)
                        match (node) {
                            case forallNode: ForallNode =>
                                listener.exitForall(forallNode, newNode)
                                if (!newNode.truthValue) {
                                    node.selectedChildren[contextId] = newNode
                                }
                            case existsNode: ExistsNode =>
                                listener.exitExists(existsNode, newNode)
                                if (newNode.truthValue) {
                                    node.selectedChildren[contextId] = newNode
                                }
                            case _ => throw IllegalStateException(
                                "Unexpected quantifier node type ${node.syntaxTreeNode.nodeType}")
                        }
                        node.ctx2child[contextId] = newNode
                        if (let Some(old) <- oldValue) {
                            bindings[node.syntaxTreeNode.dfn] = old
                        } else {
                            bindings.remove(node.syntaxTreeNode.dfn)
                        }
                    case ContextChangeType.Delete =>
                        node.ctx2child.remove(contextId)
                        node.selectedChildren.remove(contextId)
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
                    for ((ctxId, child) in node.ctx2child) {
                        let oldTruthValue = child.truthValue
                        let oldValue = bindings.add(node.syntaxTreeNode.dfn, child.assignment.getOrThrow().ctx)
                        adjustHelper(child)
                        if (let Some(old) <- oldValue) {
                            bindings[node.syntaxTreeNode.dfn] = old
                        } else {
                            bindings.remove(node.syntaxTreeNode.dfn)
                        }
                        if (child.truthValue != oldTruthValue) {
                            match (node) {
                                case forallNode: ForallNode =>
                                    if (!child.truthValue) {
                                        node.selectedChildren[ctxId] = child
                                    } else {
                                        node.selectedChildren.remove(ctxId)
                                    }
                                case existsNode: ExistsNode =>
                                    if (child.truthValue) {
                                        node.selectedChildren[ctxId] = child
                                    } else {
                                        node.selectedChildren.remove(ctxId)
                                    }
                                case _ => throw IllegalStateException(
                                    "Unexpected quantifier node type ${node.syntaxTreeNode.nodeType}")
                            }
                        }
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
        // let startTime = MonoTime.now()
        if (!newNode.truthValue) {
            node.links = node
                .links
                .union(
                    Links(ArrayList([Link(LinkType.Violated, ArrayList([newNode.assignment.getOrThrow()]))])).product(
                        newNode.links))
        }
        // let elapsed = MonoTime.now() - startTime
        // DebugInfo.generateForallTime += elapsed
    }

    public func exitExists(node: ExistsNode, newNode: CctNode): Unit {
        // let startTime = MonoTime.now()
        if (newNode.truthValue) {
            node.links = node
                .links
                .union(
                    Links(ArrayList([Link(LinkType.Satisfied, ArrayList([newNode.assignment.getOrThrow()]))])).product(
                        newNode.links))
        }
        // let elapsed = MonoTime.now() - startTime
        // DebugInfo.generateExistsTime += elapsed
    }
}
