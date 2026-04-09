package pcc_cangjie.defs

import std.time.DateTime

public class Context <: ToString & Comparable<Context> {
    private static let POISON_STRING = "POISON"
    private static let POISON_DATE = DateTime.of(year: -5000, month: 1, dayOfMonth: 1)
    public static let POISON_CONTEXT: Context = Context(POISON_STRING, POISON_STRING, POISON_STRING, POISON_STRING,
        Moment(POISON_DATE), POISON_STRING, POISON_DATE)

    public Context(public let category: String, public let subject: String, public let predicate: String,
        public let object: String, public let lifespan: Lifespan, public let site: String,
        public let timestamp: DateTime) {}

    public func toString(): String {
        return "Context(\n\tcategory=${category}, \n\tsubject=${subject}, \n\tpredicate=${predicate}, \n\tobject=${object}, \n\tlifespan=${lifespan}, \n\tsite=${site}, \n\ttimestamp=${timestamp}\n)"
    }

    public func compare(other: Context): Ordering {
        return this.timestamp.compare(other.timestamp)
    }
}

public enum ContextChangeType <: ToString {
    Add | Delete

    public func toString(): String {
        match (this) {
            case Add => "Add"
            case Delete => "Delete"
        }
    }
}

public type ContextChange = (Int, Context, ContextChangeType)
