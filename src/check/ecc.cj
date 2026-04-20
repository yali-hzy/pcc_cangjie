package pcc_cangjie.check

import pcc_cangjie.defs.Context
import pcc_cangjie.collection.{Link, Links, LinkType}
import pcc_cangjie.logger.LOGGER
import std.collection.{fold, ArrayList, filter, HashMap, forEach, any}
import std.time.MonoTime
import pcc_cangjie.defs.DebugInfo
import pcc_cangjie.defs.{maxUsedHeapSize, maxAllocatedHeapSize}
import std.runtime.{getUsedHeapSize, getAllocatedHeapSize}

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
        DebugInfo.reset()
        let time = MonoTime.now()
        cct.root = handleChange(cct.syntaxTree.root)
        let elapsed = MonoTime.now() - time
        let result = cct.link
        for (link in result) {
            LOGGER.getOrThrow().log(link)
        }
        LOGGER.getOrThrow().addDuration(elapsed)
        if (elapsed > Duration.millisecond * 100) {
            println(
                "Warning: Handling add for context ${contextId} in constraint ${cct.syntaxTree.name} with nodeList ${nodeList} took ${elapsed}, which may indicate a performance issue.")
            println(DebugInfo())
        }
        maxUsedHeapSize = max(maxUsedHeapSize, getUsedHeapSize())
        maxAllocatedHeapSize = max(maxAllocatedHeapSize, getAllocatedHeapSize())
    }

    public func handleDelete(cct: Cct, nodeList: ArrayList<Int>, contextId: Int): Unit {
        DebugInfo.reset()
        let time = MonoTime.now()
        cct.root = handleChange(cct.syntaxTree.root)
        let elapsed = MonoTime.now() - time
        let result = cct.link
        for (link in result) {
            LOGGER.getOrThrow().log(link)
        }
        LOGGER.getOrThrow().addDuration(elapsed)
        if (elapsed > Duration.millisecond * 100) {
            println(
                "Warning: Handling delete for context ${contextId} in constraint ${cct.syntaxTree.name} with nodeList ${nodeList} took ${elapsed}, which may indicate a performance issue.")
            println(DebugInfo())
        }
        maxUsedHeapSize = max(maxUsedHeapSize, getUsedHeapSize())
        maxAllocatedHeapSize = max(maxAllocatedHeapSize, getAllocatedHeapSize())
    }
}

open class EccEvaluator <: Evaluator {
    public func exitForall(node: ForallNode): Unit {
        // no Collection.fold in version 1.0.5
        let startTime = MonoTime.now()
        // node.truthValue = node.ctx2child.values() |> fold(true) {tv, child => tv && child.truthValue}

        node.truthValue = true
        for ((_, child) in node.ctx2child) {
            if (!child.truthValue) {
                node.truthValue = false
                break
            }
        }

        // node.truthValue = !any {child => !child[1].truthValue}(node.ctx2child)
        // node.truthValue = !node.ctx2child.values().iterator().any {child => !child.truthValue}
        let elapsed = MonoTime.now() - startTime
        DebugInfo.evaluateIterateCount += node.ctx2child.size
        DebugInfo.evaluateIterateCapacity += node.ctx2child.capacity
        DebugInfo.evaluateMaxIterateSize = max(DebugInfo.evaluateMaxIterateSize, node.ctx2child.size)
        DebugInfo.evaluateMaxIterateCapacity = max(DebugInfo.evaluateMaxIterateCapacity, node.ctx2child.capacity)
        DebugInfo.evaluateForallTime += elapsed
    }

    public func exitExists(node: ExistsNode): Unit {
        let startTime = MonoTime.now()
        // node.truthValue = node.ctx2child.values() |> fold(false) {tv, child => tv || child.truthValue}

        node.truthValue = false
        for ((_, child) in node.ctx2child) {
            if (child.truthValue) {
                node.truthValue = true
                break
            }
        }
        // node.truthValue = any {child => child[1].truthValue}(node.ctx2child)
        // node.truthValue = node.ctx2child.values().iterator().any {child => child.truthValue}
        let elapsed = MonoTime.now() - startTime
        DebugInfo.evaluateIterateCount += node.ctx2child.size
        DebugInfo.evaluateIterateCapacity += node.ctx2child.capacity
        DebugInfo.evaluateMaxIterateSize = max(DebugInfo.evaluateMaxIterateSize, node.ctx2child.size)
        DebugInfo.evaluateMaxIterateCapacity = max(DebugInfo.evaluateMaxIterateCapacity, node.ctx2child.capacity)
        DebugInfo.evaluateExistsTime += elapsed
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
        let startTime = MonoTime.now()
        // let map = node
        //     .assignments
        //     .map {x => x.collectHashMap(node.syntaxTreeNode.depth)}
        //     .getOrDefault {=> HashMap<Int, Context>()}
        let map = if (let Some(assignments) <- node.assignments) {
            assignments.collectHashMap(node.syntaxTreeNode.depth)
        } else {
            HashMap<Int, Context>()
        }
        let bfunc = (node.syntaxTreeNode as BfuncSyntaxTreeNode).getOrThrow().bfunc
        // node.truthValue = applyBfunc(bfunc.funcInfo, bfunc.argsId.map {argId => map[argId]})
        // node.truthValue = applyBfunc(bfunc.funcInfo.name, bfunc.argsId.map {argId => map[argId]})
        node.truthValue = applyBfunc(bfunc.name, bfunc.argsId.map {argId => map[argId]})
        // let ctxArr = if (let Some(assignments) <- node.assignments) {
        //     assignments.collectArray(bfunc.argsId)
        // } else {
        //     Array<Context>()
        // }
        // node.truthValue = applyBfunc(bfunc.name, ctxArr)
        let elapsed = MonoTime.now() - startTime
        DebugInfo.evaluateBfuncTime += elapsed
        // println("Evaluating Bfunc ${bfunc.funcInfo} with arguments ${bfunc.argsId.map {argId => map[argId]}}: ${node.truthValue}")
    }
}

open class EccGenerator <: Generator {
    public func exitForall(node: ForallNode): Unit {
        let startTime = MonoTime.now()
        let result = ArrayList<Link>()
        // node.ctx2child.values() |> filter {child => !child.truthValue} |> forEach {
        //     child => result.add(
        //         all: Links(ArrayList([Link(LinkType.Violated, ArrayList([child.assignments.getOrThrow().assignment]))]))
        //             .product(child.links)
        //             .links)
        // }
        for ((_, child) in node.ctx2child where !child.truthValue) {
            result.add(
                all: Links(ArrayList([Link(LinkType.Violated, ArrayList([child.assignments.getOrThrow().assignment]))]))
                    .product(child.links)
                    .links)
        }
        node.links = Links(result)
        let elapsed = MonoTime.now() - startTime
        DebugInfo.generateCount += node.links.links.size
        DebugInfo.generateForallTime += elapsed
    }

    public func exitExists(node: ExistsNode): Unit {
        let startTime = MonoTime.now()
        let result = ArrayList<Link>()
        // node.ctx2child.values() |> filter {child => child.truthValue} |> forEach {
        //     child => result.add(
        //         all: Links(ArrayList([Link(LinkType.Satisfied, ArrayList([child.assignments.getOrThrow().assignment]))]))
        //             .product(child.links)
        //             .links)
        // }
        for ((_, child) in node.ctx2child where child.truthValue) {
            result.add(
                all: Links(ArrayList([Link(LinkType.Satisfied, ArrayList([child.assignments.getOrThrow().assignment]))]))
                    .product(child.links)
                    .links)
        }
        node.links = Links(result)
        let elapsed = MonoTime.now() - startTime
        DebugInfo.generateCount += node.links.links.size
        DebugInfo.generateExistsTime += elapsed
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
