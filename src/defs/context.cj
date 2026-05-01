package pcc_cangjie.defs

import std.time.DateTime
// import std.collection.HashMap
// import std.convert.Parsable

public open class Context <: ToString & Comparable<Context> {
    private static let POISON_STRING = "POISON"
    private static let POISON_DATE = DateTime.of(year: -5000, month: 1, dayOfMonth: 1)
    public static let POISON_CONTEXT: Context = Context()

    // private let props = HashMap<String, String>()

    // public mut prop category: String {
    //     get() {
    //         return props.get("category").getOrDefault {=> POISON_STRING}
    //     }
    //     set(value) {
    //         props["category"] = value
    //     }
    // }
    public var category: String = POISON_STRING

    // public mut prop subject: String {
    //     get() {
    //         return props.get("subject").getOrDefault {=> POISON_STRING}
    //     }
    //     set(value) {
    //         props["subject"] = value
    //     }
    // }
    public var subject: String = POISON_STRING

    // public mut prop predicate: String {
    //     get() {
    //         return props.get("predicate").getOrDefault {=> POISON_STRING}
    //     }
    //     set(value) {
    //         props["predicate"] = value
    //     }
    // }
    public var predicate: String = POISON_STRING

    // public mut prop object: String {
    //     get() {
    //         return props.get("object").getOrDefault {=> POISON_STRING}
    //     }
    //     set(value) {
    //         props["object"] = value
    //     }
    // }
    public var object: String = POISON_STRING

    // private var _lifespan: Lifespan = Moment(POISON_DATE)
    // public mut prop lifespan: Lifespan {
    //     get() {
    //         return _lifespan
    //     }
    //     set(value) {
    //         _lifespan = value
    //     }
    // }
    public var lifespan: Lifespan = Moment(POISON_DATE)

    // public mut prop site: String {
    //     get() {
    //         return props.get("site").getOrDefault {=> POISON_STRING}
    //     }
    //     set(value) {
    //         props["site"] = value
    //     }
    // }
    public var site: String = POISON_STRING

    // private var _timestamp: DateTime = POISON_DATE
    // public mut prop timestamp: DateTime {
    //     get() {
    //         return _timestamp
    //     }
    //     set(value) {
    //         _timestamp = value
    //     }
    // }
    public var timestamp: DateTime = POISON_DATE

    // public mut prop id: String {
    //     get() {
    //         return props.get("id").getOrDefault {=> POISON_STRING}
    //     }
    //     set(value) {
    //         props["id"] = value
    //     }
    // }
    public var id: String = POISON_STRING

    // public mut prop longitude: Float64 {
    //     get() {
    //         return props.get("longitude").map {x => Float64.parse(x)}.getOrDefault {=> 0.0}
    //     }
    //     set(value) {
    //         props["longitude"] = value.toString()
    //     }
    // }
    public var longitude: Float64 = 0.0

    // public mut prop latitude: Float64 {
    //     get() {
    //         return props.get("latitude").map {x => Float64.parse(x)}.getOrDefault {=> 0.0}
    //     }
    //     set(value) {
    //         props["latitude"] = value.toString()
    //     }
    // }
    public var latitude: Float64 = 0.0

    // public mut prop speed: Float64 {
    //     get() {
    //         return props.get("speed").map {x => Float64.parse(x)}.getOrDefault {=> 0.0}
    //     }
    //     set(value) {
    //         props["speed"] = value.toString()
    //     }
    // }
    public var speed: Float64 = 0.0

    public Context() {}

    public func toString(): String {
        if (this == POISON_CONTEXT) {
            return "POISON_CONTEXT"
        } else {
            let str = StringBuilder()
            str.append("Context(\n")
            // for ((key, value) in props) {
            //     str.append("\t${key}=${value}\n")
            // }
            str.append("\tid=${id}\n")
            if (category != POISON_STRING) {
                str.append("\tcategory=${category}\n")
            }
            if (subject != POISON_STRING) {
                str.append("\tsubject=${subject}\n")
            }
            if (predicate != POISON_STRING) {
                str.append("\tpredicate=${predicate}\n")
            }
            if (object != POISON_STRING) {
                str.append("\tobject=${object}\n")
            }
            if (site != POISON_STRING) {
                str.append("\tsite=${site}\n")
            }
            str.append("\tlongitude=${longitude}\n")
            str.append("\tlatitude=${latitude}\n")
            str.append("\tspeed=${speed}\n")
            if (lifespan != Moment(POISON_DATE)) {
                str.append("\tlifespan=${lifespan}\n")
            }
            if (timestamp != POISON_DATE) {
                str.append("\ttimestamp=${timestamp}\n")
            }
            str.append(")")
            return str.toString()
        }
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

public class CtxChangeItem <: Comparable<CtxChangeItem> {
    public CtxChangeItem(public let contextId: Int, public let context: Context, public let patternId: Int,
        public let changeType: ContextChangeType, public let timestamp: DateTime) {}

    public func compare(other: CtxChangeItem): Ordering {
        return timestamp.compare(other.timestamp)
    }
}
