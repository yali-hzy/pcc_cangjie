package pcc_cangjie.defs

import std.time.DateTime

public enum Lifespan <: ToString & Equatable<Lifespan> {
    | Moment(DateTime) | Period(DateTime, DateTime)

    public func toString(): String {
        match (this) {
            case Moment(t) => "At ${t.toString()}"
            case Period(s, e) => "From ${s.toString()} to ${e.toString()}"
        }
    }

    public operator func ==(other: Lifespan): Bool {
        match ((this, other)) {
            case (Moment(t1), Moment(t2)) => t1 == t2
            case (Period(s1, e1), Period(s2, e2)) => s1 == s2 && e1 == e2
            case _ => false
        }
    }
}
