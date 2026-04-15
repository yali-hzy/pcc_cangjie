package pcc_cangjie.check

import pcc_cangjie.defs.Context
import pcc_cangjie.collection.{Link, Links, LinkType}
import pcc_cangjie.logger.LOGGER
import std.collection.{fold, ArrayList, filter, HashMap, forEach}
import std.time.MonoTime

class EccListener <: CheckListener<Evaluator, Generator> {
    init() {
        super(EccEvaluator(), EccGenerator())
    }
}

class EccMethod <: CheckMethod {
    let cctBuilder: CctBuilder

    init(checker: CctChecker) {
        this.cctBuilder = CctBuilder(checker)
    }

    private func handleChange(refRoot: SyntaxTreeNode) {
        cctBuilder.build(refRoot)
    }

    public func handleAdd(cct: Cct, nodeList: ArrayList<Int>, contextId: Int, context: Context): Unit {
        // println("Handling add for context ${contextId} in constraint ${cct.syntaxTree.name} with nodeList ${nodeList}")
        let time = MonoTime.now()
        cct.root = handleChange(cct.syntaxTree.root)
        let elapsed = MonoTime.now() - time
        let result = cct.link
        for (link in result) {
            LOGGER.getOrThrow().log(link)
        }
        LOGGER.getOrThrow().addDuration(elapsed)
        if (elapsed > Duration.millisecond * 100) {
            println("Warning: Handling add for context ${contextId} in constraint ${cct.syntaxTree.name} with nodeList ${nodeList} took ${elapsed}, which may indicate a performance issue.")
        }
    }

    public func handleDelete(cct: Cct, nodeList: ArrayList<Int>, contextId: Int): Unit {
        let time = MonoTime.now()
        cct.root = handleChange(cct.syntaxTree.root)
        let elapsed = MonoTime.now() - time
        let result = cct.link
        for (link in result) {
            LOGGER.getOrThrow().log(link)
        }
        LOGGER.getOrThrow().addDuration(elapsed)
        if (elapsed > Duration.millisecond * 100) {
            println("Warning: Handling delete for context ${contextId} in constraint ${cct.syntaxTree.name} with nodeList ${nodeList} took ${elapsed}, which may indicate a performance issue.")
        }
    }
}

open class EccEvaluator <: Evaluator {
    public func exitForall(node: ForallNode): Unit {
        // no Collection.fold in version 1.0.5
        node.truthValue = node.ctx2child.values() |> fold(true) {tv, child => tv && child.truthValue}
    }

    public func exitExists(node: ExistsNode): Unit {
        node.truthValue = node.ctx2child.values() |> fold(false) {tv, child => tv || child.truthValue}
    }

    public func exitAnd(node: AndNode): Unit {
        node.truthValue = node.children[0].truthValue && node.children[1].truthValue
    }

    public func exitOr(node: OrNode): Unit {
        node.truthValue = node.children[0].truthValue || node.children[1].truthValue
    }

    public func exitImplies(node: ImpliesNode): Unit {
        node.truthValue = !node.children[0].truthValue || node.children[1].truthValue
    }

    public func exitNot(node: NotNode): Unit {
        node.truthValue = !node.children[0].truthValue
    }

    public func exitBfunc(node: BfuncNode): Unit {
        let map = node.assignments.map {x => x.collectHashMap()}.getOrDefault {=> HashMap<Int, Context>()}
        let bfunc = (node.syntaxTreeNode as BfuncSyntaxTreeNode).getOrThrow().bfunc
        node.truthValue = applyBfunc(bfunc.funcInfo, bfunc.argsId.map {argId => map[argId]})
        // println("Evaluating Bfunc ${bfunc.funcInfo} with arguments ${bfunc.argsId.map {argId => map[argId]}}: ${node.truthValue}")
    }
}

open class EccGenerator <: Generator {
    public func exitForall(node: ForallNode): Unit {
        let result = ArrayList<Link>()
        node.ctx2child.values() |> filter {child => !child.truthValue} |> forEach {
            child => result.add(
                all: Links(ArrayList([Link(LinkType.Violated, ArrayList([child.assignments.getOrThrow().assignment]))]))
                    .product(child.links)
                    .links)
        }
        node.links = Links(result)
    }

    public func exitExists(node: ExistsNode): Unit {
        let result = ArrayList<Link>()
        node.ctx2child.values() |> filter {child => child.truthValue} |> forEach {
            child => result.add(
                all: Links(ArrayList([Link(LinkType.Satisfied, ArrayList([child.assignments.getOrThrow().assignment]))]))
                    .product(child.links)
                    .links)
        }
        node.links = Links(result)
    }

    public func exitAnd(node: AndNode): Unit {
        node.links = match ((node.children[0].truthValue, node.children[1].truthValue)) {
            case (true, true) => node.children[0].links.product(node.children[1].links)
            case (true, false) => node.children[1].links
            case (false, true) => node.children[0].links
            case (false, false) => node.children[0].links.union(node.children[1].links)
        }
    }

    public func exitOr(node: OrNode): Unit {
        node.links = match ((node.children[0].truthValue, node.children[1].truthValue)) {
            case (true, true) => node.children[0].links.union(node.children[1].links)
            case (true, false) => node.children[0].links
            case (false, true) => node.children[1].links
            case (false, false) => node.children[0].links.product(node.children[1].links)
        }
    }

    public func exitImplies(node: ImpliesNode): Unit {
        node.links = match ((node.children[0].truthValue, node.children[1].truthValue)) {
            case (true, true) => node.children[1].links
            case (true, false) => node.children[0].links.flipset().product(node.children[1].links)
            case (false, true) => node.children[0].links.flipset().union(node.children[1].links)
            case (false, false) => node.children[0].links.flipset()
        }
    }

    public func exitNot(node: NotNode): Unit {
        node.links = node.children[0].links.flipset()
    }

    public func exitBfunc(node: BfuncNode): Unit {
        node.links = Links(ArrayList<Link>())
    }
}
