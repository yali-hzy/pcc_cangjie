package pcc_cangjie.check

import pcc_cangjie.defs.Context
import pcc_cangjie.collection.{Assignment, AssignmentLinkedListNode, Links}
import std.collection.{ArrayList, HashMap, map, collectString}
import std.time.MonoTime
import pcc_cangjie.defs.DebugInfo

class CctBuilder {
    let listener = EccListener()

    CctBuilder(let checker: CctChecker) {}

    private func makeAssignment(existing: ?AssignmentLinkedListNode, newAssignment: ?Assignment): ?AssignmentLinkedListNode {
        match (newAssignment) {
            case None => existing
            case Some(assignment) => AssignmentLinkedListNode(existing, assignment)
        }
    }

    private func quantifierHelper(refNode: QuantifierSyntaxTreeNode, assignments: ?AssignmentLinkedListNode) {
        let startTime = MonoTime.now()
        let cctNode: QuantifierNode = match (refNode.nodeType) {
            case Forall => ForallNode(refNode, assignments)
            case Exists => ExistsNode(refNode, assignments)
            case _ => throw IllegalArgumentException("Expected a quantifier node, but got ${refNode.nodeType}")
        }
        let patternNo = refNode.patternNo
        let endTime = MonoTime.now()
        DebugInfo.otherTime += endTime - startTime
        if (patternNo == -1) {
            println("Warning: No pattern found for quantifier at node ${refNode.dfn}")
        } else {
            var startTime = MonoTime.now()
            var endTime = MonoTime.now()
            for ((contextId, (context, _)) in checker.ContextSets[patternNo].contextSet) {
                endTime = MonoTime.now()
                DebugInfo.quantifierHelperIterateTime += endTime - startTime
                let child = buildHelper(refNode.children[0], cctNode, Assignment(refNode.dfn, context))
                startTime = MonoTime.now()
                cctNode.ctx2child[contextId] = child
            }
        }
        return cctNode
    }

    private func nonleafHelper(refNode: SyntaxTreeNode, assignments: ?AssignmentLinkedListNode) {
        let startTime = MonoTime.now()
        let cctNode: NonleafNode = match (refNode.nodeType) {
            case And => AndNode(refNode, assignments)
            case Or => OrNode(refNode, assignments)
            case Implies => ImpliesNode(refNode, assignments)
            case Not => NotNode(refNode, assignments)
            case _ => throw IllegalArgumentException("Unexpected node type ${refNode.nodeType} in binaryHelper")
        }
        let endTime = MonoTime.now()
        DebugInfo.otherTime += endTime - startTime
        cctNode.children = refNode.children.map {child => buildHelper(child, cctNode, None)}
        return cctNode
    }

    private func buildHelper(refNode: SyntaxTreeNode, parent: ?CctNode, assignment: ?Assignment): CctNode {
        let startTime = MonoTime.now()
        // let assignments = makeAssignment(parent.flatMap {x => x.assignments}, assignment)
        var assignments: ?AssignmentLinkedListNode = None
        if (let Some(assign) <- assignment) {
            if (let Some(p) <- parent) {
                assignments = AssignmentLinkedListNode(p.assignments, assign)
            } else {
                assignments = AssignmentLinkedListNode(None, assign)
            }
        } else {
            if (let Some(p) <- parent) {
                assignments = p.assignments
            } else {
                assignments = None
            }
        }
        let end1Time = MonoTime.now()
        DebugInfo.assignmentTime += end1Time - startTime
        match (refNode.nodeType) {
            case Forall | Exists =>
                let endTime = MonoTime.now()
                DebugInfo.otherTime += endTime - end1Time
                let cctNode = quantifierHelper((refNode as QuantifierSyntaxTreeNode).getOrThrow(), assignments)
                let endTime2 = MonoTime.now()
                match (refNode.nodeType) {
                    case Forall => listener.exitForall((cctNode as ForallNode).getOrThrow())
                    case Exists => listener.exitExists((cctNode as ExistsNode).getOrThrow())
                    case _ => throw IllegalStateException(
                        "Unexpected node type ${refNode.nodeType} in quantifierHelper")
                }
                let endTime3 = MonoTime.now()
                DebugInfo.listenerTime += endTime3 - endTime2
                return cctNode
            case And | Or | Implies | Not =>
                let endTime = MonoTime.now()
                DebugInfo.otherTime += endTime - end1Time
                let cctNode = nonleafHelper(refNode, assignments)
                let endTime2 = MonoTime.now()
                match (refNode.nodeType) {
                    case And => listener.exitAnd((cctNode as AndNode).getOrThrow())
                    case Or => listener.exitOr((cctNode as OrNode).getOrThrow())
                    case Implies => listener.exitImplies((cctNode as ImpliesNode).getOrThrow())
                    case Not => listener.exitNot((cctNode as NotNode).getOrThrow())
                    case _ => throw IllegalStateException("Unexpected node type ${refNode.nodeType} in normalHelper")
                }
                let endTime3 = MonoTime.now()
                DebugInfo.listenerTime += endTime3 - endTime2
                return cctNode
            case Bfunc =>
                let cctNode = BfuncNode(refNode, assignments)
                let endTime = MonoTime.now()
                DebugInfo.otherTime += endTime - end1Time
                listener.exitBfunc(cctNode)
                // println(cctNode.truthValue)
                return cctNode
        }
    }

    func build(refNode: SyntaxTreeNode, parent!: ?CctNode = None, ctx!: Context = Context.POISON_CONTEXT): CctNode {
        match (parent) {
            case None => buildHelper(refNode, None, None)
            case Some(p) => buildHelper(refNode, p, Assignment(p.syntaxTreeNode.dfn, ctx))
        }
    }
}

class Cct {
    var root: ?CctNode = None
    Cct(let syntaxTree: SyntaxTree) {}

    prop truthValue: String {
        get() {
            "truth value = ${root.getOrThrow().truthValue}"
        }
    }

    prop link: ArrayList<String> {
        get() {
            let linkstr = ArrayList<String>()
            let links = root.getOrThrow().links.links
            if (links.isEmpty()) {
            // str.append("No links")
            } else {
                for (link in links) {
                    linkstr.add(
                        "${syntaxTree.name}(${links[0].linkType},{${link.bindings.map {assignment => "(${syntaxTree.dfn2VarName[assignment.varId]}, ${assignment.ctx.id})"} |> collectString(delimiter: ",")}})")
                }
            }
            return linkstr
        }
    }

    prop result: String {
        get() {
            if (!root.getOrThrow().truthValue) {
                "${link}"
            } else {
                ""
            }
        }
    }
}

abstract class CctNode {
    var truthValue = false
    var links: Links = Links(ArrayList())

    CctNode(let syntaxTreeNode: SyntaxTreeNode, let assignments: ?AssignmentLinkedListNode) {}
}

abstract class QuantifierNode <: CctNode {
    let ctx2child = HashMap<Int, CctNode>()
    init(syntaxTreeNode: SyntaxTreeNode, assignments: ?AssignmentLinkedListNode) {
        super(syntaxTreeNode, assignments)
    }
}

abstract class NonleafNode <: CctNode {
    var children: Array<CctNode> = []
    init(syntaxTreeNode: SyntaxTreeNode, assignments: ?AssignmentLinkedListNode) {
        super(syntaxTreeNode, assignments)
    }
}

class ForallNode <: QuantifierNode {
    init(syntaxTreeNode: SyntaxTreeNode, assignments: ?AssignmentLinkedListNode) {
        super(syntaxTreeNode, assignments)
    }
}

class ExistsNode <: QuantifierNode {
    init(syntaxTreeNode: SyntaxTreeNode, assignments: ?AssignmentLinkedListNode) {
        super(syntaxTreeNode, assignments)
    }
}

class AndNode <: NonleafNode {
    init(syntaxTreeNode: SyntaxTreeNode, assignments: ?AssignmentLinkedListNode) {
        super(syntaxTreeNode, assignments)
    }
}

class OrNode <: NonleafNode {
    init(syntaxTreeNode: SyntaxTreeNode, assignments: ?AssignmentLinkedListNode) {
        super(syntaxTreeNode, assignments)
    }
}

class ImpliesNode <: NonleafNode {
    init(syntaxTreeNode: SyntaxTreeNode, assignments: ?AssignmentLinkedListNode) {
        super(syntaxTreeNode, assignments)
    }
}

class NotNode <: NonleafNode {
    init(syntaxTreeNode: SyntaxTreeNode, assignments: ?AssignmentLinkedListNode) {
        super(syntaxTreeNode, assignments)
    }
}

class BfuncNode <: CctNode {
    init(syntaxTreeNode: SyntaxTreeNode, assignments: ?AssignmentLinkedListNode) {
        super(syntaxTreeNode, assignments)
    }
}
