package pcc_cangjie.check

import std.collection.HashMap
import pcc_cangjie.defs.Context

interface ExitListener {
    func exitForall(node: ForallNode): Unit
    func exitExists(node: ExistsNode): Unit
    func exitAnd(node: AndNode): Unit
    func exitOr(node: OrNode): Unit
    func exitImplies(node: ImpliesNode): Unit
    func exitNot(node: NotNode): Unit
    func exitBfunc(node: BfuncNode, bindings: HashMap<Int, Context>): Unit
}

interface Evaluator <: ExitListener {}

interface Generator <: ExitListener {}

abstract class CheckListener<E, G> <: ExitListener where E <: Evaluator, G <: Generator {
    CheckListener(let evaluator: E, let generator: G) {}

    public func exitForall(node: ForallNode): Unit {
        evaluator.exitForall(node)
        generator.exitForall(node)
    }

    public func exitExists(node: ExistsNode): Unit {
        evaluator.exitExists(node)
        generator.exitExists(node)
    }

    public func exitAnd(node: AndNode): Unit {
        evaluator.exitAnd(node)
        generator.exitAnd(node)
    }

    public func exitOr(node: OrNode): Unit {
        evaluator.exitOr(node)
        generator.exitOr(node)
    }

    public func exitImplies(node: ImpliesNode): Unit {
        evaluator.exitImplies(node)
        generator.exitImplies(node)
    }

    public func exitNot(node: NotNode): Unit {
        evaluator.exitNot(node)
        generator.exitNot(node)
    }

    public func exitBfunc(node: BfuncNode, bindings: HashMap<Int, Context>): Unit {
        evaluator.exitBfunc(node, bindings)
        generator.exitBfunc(node, bindings)
    }
}
