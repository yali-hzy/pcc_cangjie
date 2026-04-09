package pcc_cangjie.defs

import std.collection.collectString

public class Constraint <: ToString {
    public Constraint(public let name: String, public let formula: Formula) {}

    public func toString(): String {
        return "Constraint ${name}: ${formula.toString()}"
    }
}

public enum Formula <: ToString {
    | Forall(String, String, Formula)
    | Exists(String, String, Formula)
    | And(Formula, Formula)
    | Or(Formula, Formula)
    | Implies(Formula, Formula)
    | Not(Formula)
    | Bfunc(String, Array<String>)

    public func toString(): String {
        match (this) {
            case Forall(v, s, body) => "forall ${v} in ${s}, ${body.toString()}"
            case Exists(v, s, body) => "exists ${v} in ${s}, ${body.toString()}"
            case And(lhs, rhs) => "(${lhs.toString()}) and (${rhs.toString()})"
            case Or(lhs, rhs) => "(${lhs.toString()}) or (${rhs.toString()})"
            case Implies(lhs, rhs) => "(${lhs.toString()}) implies (${rhs.toString()})"
            case Not(operand) => "not (${operand.toString()})"
            case Bfunc(name, args) => "${name}(${collectString(delimiter: ", ")(args)})"
        }
    }
}
