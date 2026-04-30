package pcc_cangjie.check

import pcc_cangjie.defs.Context
import pcc_cangjie.collection.{Assignment, AssignmentLinkedListNode, Links}
import std.collection.{ArrayList, HashMap, map, collectString}
// import std.time.MonoTime
// import pcc_cangjie.defs.DebugInfo

class CctBuilder {
    let listener = EccListener()
    var bindings = HashMap<Int, Context>()

    CctBuilder(let checker: CctChecker) {}

    // private func makeAssignment(existing: ?AssignmentLinkedListNode, newAssignment: ?Assignment): ?AssignmentLinkedListNode {
    //     match (newAssignment) {
    //         case None => existing
    //         case Some(assignment) => AssignmentLinkedListNode(existing, assignment)
    //     }
    // }

    private func quantifierHelper(refNode: QuantifierSyntaxTreeNode, assignment: ?Assignment) {
        // let startTime = MonoTime.now()
        let cctNode: QuantifierNode = match (refNode.nodeType) {
            case Forall => ForallNode(refNode, assignment)
            case Exists => ExistsNode(refNode, assignment)
            case _ => throw IllegalArgumentException("Expected a quantifier node, but got ${refNode.nodeType}")
        }
        let patternNo = refNode.patternNo
        // let endTime = MonoTime.now()
        // DebugInfo.otherTime += endTime - startTime
        if (patternNo == -1) {
            println("Warning: No pattern found for quantifier at node ${refNode.dfn}")
        } else {
            // var startTime = MonoTime.now()
            // var endTime = MonoTime.now()
            for ((contextId, (context, _)) in checker.ContextSets[patternNo].contextSet) {
                let oldValue = bindings.add(refNode.dfn, context)
                // for ((varId, varContext) in bindings) {
                //     println("Current bindings: dfn ${varId} -> context ${varContext.id}")
                // }
                // endTime = MonoTime.now()
                // DebugInfo.quantifierHelperIterateTime += endTime - startTime
                let child = buildHelper(refNode.children[0], cctNode, Assignment(refNode.dfn, context))
                // startTime = MonoTime.now()
                cctNode.ctx2child[contextId] = child
                match (refNode.nodeType) {
                    case Forall => if (!child.truthValue) {
                        cctNode.selectedChildren[contextId] = child
                    }
                    case Exists => if (child.truthValue) {
                        cctNode.selectedChildren[contextId] = child
                    }
                    case _ => throw IllegalStateException(
                        "Unexpected node type ${refNode.nodeType} in quantifierHelper")
                }
                if (let Some(old) <- oldValue) {
                    bindings[refNode.dfn] = old
                } else {
                    bindings.remove(refNode.dfn)
                }
            }
        }
        return cctNode
    }

    private func nonleafHelper(refNode: SyntaxTreeNode, assignment: ?Assignment) {
        // let startTime = MonoTime.now()
        let cctNode: NonleafNode = match (refNode.nodeType) {
            case And => AndNode(refNode, assignment)
            case Or => OrNode(refNode, assignment)
            case Implies => ImpliesNode(refNode, assignment)
            case Not => NotNode(refNode, assignment)
            case _ => throw IllegalArgumentException("Unexpected node type ${refNode.nodeType} in binaryHelper")
        }
        // let endTime = MonoTime.now()
        // DebugInfo.otherTime += endTime - startTime
        cctNode.children = refNode.children.map {child => buildHelper(child, cctNode, None)}
        // let children = ArrayList<CctNode>(2)
        // for (child in refNode.children) {
        //     children.add(buildHelper(child, cctNode, None))
        // }
        // cctNode.children = children.toArray()
        return cctNode
    }

    private func buildHelper(refNode: SyntaxTreeNode, parent: ?CctNode, assignment: ?Assignment): CctNode {
        // let startTime = MonoTime.now()
        // let assignments = makeAssignment(parent.flatMap {x => x.assignments}, assignment)
        // var assignments: ?AssignmentLinkedListNode = None
        // if (let Some(assign) <- assignment) {
        //     if (let Some(p) <- parent) {
        //         assignments = AssignmentLinkedListNode(p.assignments, assign)
        //     } else {
        //         assignments = AssignmentLinkedListNode(None, assign)
        //     }
        // } else {
        //     if (let Some(p) <- parent) {
        //         assignments = p.assignments
        //     } else {
        //         assignments = None
        //     }
        // }
        // let end1Time = MonoTime.now()
        // DebugInfo.assignmentTime += end1Time - startTime
        match (refNode.nodeType) {
            case Forall | Exists =>
                // let endTime = MonoTime.now()
                // DebugInfo.otherTime += endTime - end1Time
                let cctNode = quantifierHelper((refNode as QuantifierSyntaxTreeNode).getOrThrow(), assignment)
                // let endTime2 = MonoTime.now()
                match (refNode.nodeType) {
                    case Forall => listener.exitForall((cctNode as ForallNode).getOrThrow())
                    case Exists => listener.exitExists((cctNode as ExistsNode).getOrThrow())
                    case _ => throw IllegalStateException(
                        "Unexpected node type ${refNode.nodeType} in quantifierHelper")
                }
                // let endTime3 = MonoTime.now()
                // DebugInfo.listenerTime += endTime3 - endTime2
                return cctNode
            case And | Or | Implies | Not =>
                // let endTime = MonoTime.now()
                // DebugInfo.otherTime += endTime - end1Time
                let cctNode = nonleafHelper(refNode, assignment)
                // let endTime2 = MonoTime.now()
                match (refNode.nodeType) {
                    case And => listener.exitAnd((cctNode as AndNode).getOrThrow())
                    case Or => listener.exitOr((cctNode as OrNode).getOrThrow())
                    case Implies => listener.exitImplies((cctNode as ImpliesNode).getOrThrow())
                    case Not => listener.exitNot((cctNode as NotNode).getOrThrow())
                    case _ => throw IllegalStateException("Unexpected node type ${refNode.nodeType} in normalHelper")
                }
                // let endTime3 = MonoTime.now()
                // DebugInfo.listenerTime += endTime3 - endTime2
                return cctNode
            case Bfunc =>
                let cctNode = BfuncNode(refNode, assignment)
                // let endTime = MonoTime.now()
                // DebugInfo.otherTime += endTime - end1Time
                listener.exitBfunc(cctNode, bindings)
                // println(cctNode.truthValue)
                return cctNode
        }
    }

    func build(refNode: SyntaxTreeNode, parent!: ?CctNode = None, ctx!: Context = Context.POISON_CONTEXT, bindings!: HashMap<Int, Context> = HashMap<Int, Context>()): CctNode {
        this.bindings = bindings
        // if (let Some(b) <- bindings) {
        //     this.bindings = b
        // } else {
        //     this.bindings = HashMap<Int, Context>()
        // }
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
                // println()
                for (link in links) {
                    // println("name: ${syntaxTree.name}")
                    // for ((id, varname) in syntaxTree.dfn2VarName) {
                    //     println("dfn: ${id}, varname: ${varname}")
                    // }
                    // println("links size: ${links.size}")
                    // println("Link type: ${link.linkType} ${links[0].linkType}, bindings: ${link.bindings.map {assignment => "(${assignment.varId}, ${assignment.ctx.id})"} |> collectString(delimiter: ",")}")
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

    CctNode(let syntaxTreeNode: SyntaxTreeNode, let assignment: ?Assignment) {}
}

abstract class QuantifierNode <: CctNode {
    let ctx2child = HashMap<Int, CctNode>()
    let selectedChildren = HashMap<Int, CctNode>()
    init(syntaxTreeNode: SyntaxTreeNode, assignment: ?Assignment) {
        super(syntaxTreeNode, assignment)
    }
}

abstract class NonleafNode <: CctNode {
    var children: Array<CctNode> = []
    init(syntaxTreeNode: SyntaxTreeNode, assignment: ?Assignment) {
        super(syntaxTreeNode, assignment)
    }
}

class ForallNode <: QuantifierNode {
    init(syntaxTreeNode: SyntaxTreeNode, assignment: ?Assignment) {
        super(syntaxTreeNode, assignment)
    }
}

class ExistsNode <: QuantifierNode {
    init(syntaxTreeNode: SyntaxTreeNode, assignment: ?Assignment) {
        super(syntaxTreeNode, assignment)
    }
}

class AndNode <: NonleafNode {
    init(syntaxTreeNode: SyntaxTreeNode, assignment: ?Assignment) {
        super(syntaxTreeNode, assignment)
    }
}

class OrNode <: NonleafNode {
    init(syntaxTreeNode: SyntaxTreeNode, assignment: ?Assignment) {
        super(syntaxTreeNode, assignment)
    }
}

class ImpliesNode <: NonleafNode {
    init(syntaxTreeNode: SyntaxTreeNode, assignment: ?Assignment) {
        super(syntaxTreeNode, assignment)
    }
}

class NotNode <: NonleafNode {
    init(syntaxTreeNode: SyntaxTreeNode, assignment: ?Assignment) {
        super(syntaxTreeNode, assignment)
    }
}

class BfuncNode <: CctNode {
    init(syntaxTreeNode: SyntaxTreeNode, assignment: ?Assignment) {
        super(syntaxTreeNode, assignment)
    }
}
