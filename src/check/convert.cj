package pcc_cangjie.check

import pcc_cangjie.defs.Formula

func kernelConvert(formula: Formula): Formula {
    match (formula) {
        case Forall(v, s, body) => Forall(v, s, kernelConvert(body))
        case Exists(v, s, body) => Not(Forall(v, s, Not(kernelConvert(body))))
        case And(lhs, rhs) => And(kernelConvert(lhs), kernelConvert(rhs))
        case Or(lhs, rhs) => Not(And(Not(kernelConvert(lhs)), Not(kernelConvert(rhs))))
        case Implies(lhs, rhs) => Not(And(kernelConvert(lhs), Not(kernelConvert(rhs))))
        case Not(operand) => Not(kernelConvert(operand))
        case Bfunc(name, args) => Bfunc(name, args)
    }
}

func notLeafConvert(formula: Formula): Formula {
    match (formula) {
        case Forall(v, s, body) => Forall(v, s, notLeafConvert(body))
        case Exists(v, s, body) => Exists(v, s, notLeafConvert(body))
        case And(lhs, rhs) => And(notLeafConvert(lhs), notLeafConvert(rhs))
        case Or(lhs, rhs) => Or(notLeafConvert(lhs), notLeafConvert(rhs))
        case Implies(lhs, rhs) => Implies(notLeafConvert(lhs), notLeafConvert(rhs))
        case Bfunc(name, args) => Bfunc(name, args)
        case Not(operand) => match (operand) {
            case Forall(v, s, body) => Exists(v, s, notLeafConvert(Not(body)))
            case Exists(v, s, body) => Forall(v, s, notLeafConvert(Not(body)))
            case And(lhs, rhs) => Or(notLeafConvert(Not(lhs)), notLeafConvert(Not(rhs)))
            case Or(lhs, rhs) => And(notLeafConvert(Not(lhs)), notLeafConvert(Not(rhs)))
            case Implies(lhs, rhs) => And(notLeafConvert(lhs), notLeafConvert(Not(rhs)))
            case Not(inner) => notLeafConvert(inner)
            case Bfunc(name, args) => Not(Bfunc(name, args))
        }
    }
}
