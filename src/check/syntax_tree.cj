package pcc_cangjie.check

import pcc_cangjie.defs.{Formula, Constraint}
import std.collection.{HashMap, Map, ArrayList}
import std.reflect.StaticFunctionInfo

class SyntaxTreeBuilder {
    var id = -1
    var dfnCounter = -1
    let namedVar = HashMap<String, Int>()
    let dfn2VarName = HashMap<Int, String>()
    let dfn2SyntaxNode = HashMap<Int, SyntaxTreeNode>()

    SyntaxTreeBuilder(let PatternNames2Id: HashMap<String, Int>, let PatternMap: HashMap<Int, Map<Int, ArrayList<Int>>>) {}

    private func quantifierHelper(nodeType: NodeType, dfn: Int, depth: Int, parent: ?SyntaxTreeNode, body: Formula,
        varName: String, setName: String): SyntaxTreeNode {
        let patternNo = PatternNames2Id.get(setName).getOrDefault({=> -1})
        if (patternNo == -1) {
            println(
                "Warning: No pattern found for set '${setName}' in quantifier at Constraint ${id}, variable '${varName}'")
        }
        insertPatternMap(patternNo, dfn)
        dfn2VarName[dfn] = varName
        let oldValue = namedVar.add(varName, dfn)
        let syntaxTreeNode = QuantifierSyntaxTreeNode(dfn, depth, nodeType, parent, patternNo)
        syntaxTreeNode.children = [syntaxBuild(body, syntaxTreeNode)]
        if (let Some(old) <- oldValue) {
            namedVar[varName] = old
        } else {
            namedVar.remove(varName)
        }
        return syntaxTreeNode
    }

    private func binaryHelper(nodeType: NodeType, dfn: Int, depth: Int, parent: ?SyntaxTreeNode, lhs: Formula,
        rhs: Formula): SyntaxTreeNode {
        let syntaxTreeNode = NormalSyntaxTreeNode(dfn, depth, nodeType, parent)
        syntaxTreeNode.children = [syntaxBuild(lhs, syntaxTreeNode), syntaxBuild(rhs, syntaxTreeNode)]
        return syntaxTreeNode
    }

    private func unaryHelper(nodeType: NodeType, dfn: Int, depth: Int, parent: ?SyntaxTreeNode, operand: Formula): SyntaxTreeNode {
        let syntaxTreeNode = NormalSyntaxTreeNode(dfn, depth, nodeType, parent)
        syntaxTreeNode.children = [syntaxBuild(operand, syntaxTreeNode)]
        return syntaxTreeNode
    }

    private func insertPatternMap(s: Int, dfn: Int) {
        println("Inserting pattern ${s} with dfn ${dfn} for constraint ${id}")
        if (PatternMap.contains(s)) {
            if (PatternMap[s].contains(id)) {
                PatternMap[s][id].add(dfn)
            } else {
                PatternMap[s][id] = ArrayList([dfn])
            }
        } else {
            PatternMap[s] = HashMap<Int, ArrayList<Int>>([(id, ArrayList([dfn]))])
        }
    }

    private func syntaxBuild(formula: Formula, parent: ?SyntaxTreeNode): SyntaxTreeNode {
        println("Building syntax tree for formula: ${formula}")
        dfnCounter++
        let currentDfn = dfnCounter
        let depth = parent.map {p => p.depth + 1}.getOrDefault {=> 0}
        let syntaxTreeNode: SyntaxTreeNode = match (formula) {
            case Forall(v, s, body) => quantifierHelper(NodeType.Forall, currentDfn, depth, parent, body, v, s)
            case Exists(v, s, body) => quantifierHelper(NodeType.Exists, currentDfn, depth, parent, body, v, s)
            case And(lhs, rhs) => binaryHelper(NodeType.And, currentDfn, depth, parent, lhs, rhs)
            case Or(lhs, rhs) => binaryHelper(NodeType.Or, currentDfn, depth, parent, lhs, rhs)
            case Implies(lhs, rhs) => binaryHelper(NodeType.Implies, currentDfn, depth, parent, lhs, rhs)
            case Not(operand) => unaryHelper(NodeType.Not, currentDfn, depth, parent, operand)
            case Bfunc(name, args) => BfuncSyntaxTreeNode(currentDfn, depth, NodeType.Bfunc, parent,
                BfuncInfo(getBfuncInfo(name, args.size), args.map {v => namedVar[v]}))
        }
        dfn2SyntaxNode[currentDfn] = syntaxTreeNode
        return syntaxTreeNode
    }

    private func initialize(id: Int) {
        this.id = id
        dfnCounter = -1
        dfn2SyntaxNode.clear()
        namedVar.clear()
        dfn2VarName.clear()
    }

    public func build(id: Int, constraint: Constraint): SyntaxTree {
        initialize(id)
        let syntaxTreeRoot = syntaxBuild(constraint.formula, None)
        let syntaxTreeNodes = Array<SyntaxTreeNode>(dfnCounter, {dfn => dfn2SyntaxNode[dfn]})
        return SyntaxTree(constraint.name, syntaxTreeRoot, syntaxTreeNodes, dfn2VarName)
    }
}

class BfuncInfo {
    BfuncInfo(let funcInfo: StaticFunctionInfo, let argsId: Array<Int>) {}
}

abstract class SyntaxTreeNode <: ToString {
    var children: Array<SyntaxTreeNode> = []
    SyntaxTreeNode(let dfn: Int, let depth: Int, let nodeType: NodeType, let parent: ?SyntaxTreeNode) {}

    prop metaDataStr: String {
        get() {
            "dfn=${dfn}, type=${nodeType}, parent=${parent.map {x => x.dfn}}"
        }
    }

    prop childStr: String {
        get() {
            match (children.size) {
                case 0 => ""
                case 1 => "\nchild:\n${children[0].toString()}"
                case 2 => "\nleft child:\n${children[0].toString()}\nright child:\n${children[1].toString()}"
                case _ => "Unexpected number of children: ${children.size}"
            }
        }
    }

    public open func toString(): String {
        return "${nodeType}Node(${metaDataStr})${childStr}"
    }
}

class QuantifierSyntaxTreeNode <: SyntaxTreeNode {
    QuantifierSyntaxTreeNode(dfn: Int, depth: Int, nodeType: NodeType, parent: ?SyntaxTreeNode, let patternNo: Int) {
        super(dfn, depth, nodeType, parent)
    }

    public override func toString(): String {
        return "${nodeType}Node(${metaDataStr}, patternNo=${patternNo})${childStr}"
    }
}

class NormalSyntaxTreeNode <: SyntaxTreeNode {
    init(dfn: Int, depth: Int, nodeType: NodeType, parent: ?SyntaxTreeNode) {
        super(dfn, depth, nodeType, parent)
    }
}

class BfuncSyntaxTreeNode <: SyntaxTreeNode {
    BfuncSyntaxTreeNode(dfn: Int, depth: Int, nodeType: NodeType, parent: ?SyntaxTreeNode, let bfunc: BfuncInfo) {
        super(dfn, depth, nodeType, parent)
    }

    prop bfuncStr: String {
        get() {
            return "${bfunc.funcInfo}(${bfunc.argsId})"
        }
    }

    public override func toString(): String {
        return "${nodeType}Node(${metaDataStr}, bfunc=${bfuncStr})${childStr}"
    }
}

class SyntaxTree {
    SyntaxTree(let name: String, let root: SyntaxTreeNode, let nodes: Array<SyntaxTreeNode>,
        let dfn2VarName: HashMap<Int, String>) {}
}

enum NodeType <: ToString {
    Forall | Exists | And | Or | Implies | Not | Bfunc

    public func toString(): String {
        match (this) {
            case Forall => "Forall"
            case Exists => "Exists"
            case And => "And"
            case Or => "Or"
            case Implies => "Implies"
            case Not => "Not"
            case Bfunc => "Bfunc"
        }
    }
}
