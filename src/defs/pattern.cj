package pcc_cangjie.defs

import std.time.DateTime
import std.collection.HashMap

public class Pattern <: ToString {
    public Pattern(public let name: String) {}

    public var freshness: Duration = FRESHNESS

    // private let props = HashMap<String, ?String>()

    // private func setValue(field: String, value: ?String) {
    //     if (let Some(v) <- value) {
    //         props[field] = v
    //     } else {
    //         props.remove(field)
    //         ()
    //     }
    // }

    // public mut prop category: ?String {
    //     get() {
    //         return props.get("category").flatten()
    //     }
    //     set(value) {
    //         setValue("category", value)
    //     }
    // }
    public var category: ?String = None

    // public mut prop subject: ?String {
    //     get() {
    //         return props.get("subject").flatten()
    //     }
    //     set(value) {
    //         setValue("subject", value)
    //     }
    // }
    public var subject: ?String = None

    // public mut prop predicate: ?String {
    //     get() {
    //         return props.get("predicate").flatten()
    //     }
    //     set(value) {
    //         setValue("predicate", value)
    //     }
    // }
    public var predicate: ?String = None

    // public mut prop object: ?String {
    //     get() {
    //         return props.get("object").flatten()
    //     }
    //     set(value) {
    //         setValue("object", value)
    //     }
    // }
    public var object: ?String = None

    // private var _lifespan: ?Lifespan = None
    // public mut prop lifespan: ?Lifespan {
    //     get() {
    //         return _lifespan
    //     }
    //     set(value) {
    //         _lifespan = value
    //     }
    // }
    public var lifespan: ?Lifespan = None

    // public mut prop site: ?String {
    //     get() {
    //         return props.get("site").flatten()
    //     }
    //     set(value) {
    //         setValue("site", value)
    //     }
    // }
    public var site: ?String = None

    // private var _timestamp: ?DateTime = None
    // public mut prop timestamp: ?DateTime {
    //     get() {
    //         return _timestamp
    //     }
    //     set(value) {
    //         _timestamp = value
    //     }
    // }
    public var timestamp: ?DateTime = None

    public func toString(): String {
        return "Pattern(\n\tname=${name}, \n\tcategory=${category}, \n\tsubject=${subject}, \n\tpredicate=${predicate}, \n\tobject=${object}, \n\tlifespan=${lifespan}, \n\tsite=${site}, \n\ttimestamp=${timestamp}\n)"
    }

    public func matches(context: Context): Bool {
        if (let Some(category) <- this.category && category != context.category) {
            // println("Pattern ${name} does not match context ${context.id} because category ${category} != ${context.category}")
            return false
        }
        if (let Some(subject) <- this.subject && subject != context.subject) {
            // println("Pattern ${name} does not match context ${context.id} because subject ${subject} != ${context.subject}")
            return false
        }
        if (let Some(predicate) <- this.predicate && predicate != context.predicate) {
            // println("Pattern ${name} does not match context ${context.id} because predicate ${predicate} != ${context.predicate}")
            return false
        }
        if (let Some(object) <- this.object && object != context.object) {
            // println("Pattern ${name} does not match context ${context.id} because object ${object} != ${context.object}")
            return false
        }
        if (let Some(lifespan) <- this.lifespan && lifespan != context.lifespan) {
            // println("Pattern ${name} does not match context ${context.id} because lifespan ${lifespan} != ${context.lifespan}")
            return false
        }
        if (let Some(site) <- this.site && site != context.site) {
            if (site.startsWith("hotarea_")) {
                if (!inHotArea(site[8..], context.longitude, context.latitude)) {
                    return false
                }
            } else {
                // println("Pattern ${name} does not match context ${context.id} because site ${site} != ${context.site}")
                return false
            }
        }
        if (let Some(timestamp) <- this.timestamp && timestamp != context.timestamp) {
            // println("Pattern ${name} does not match context ${context.id} because timestamp ${timestamp} != ${context.timestamp}")
            return false
        }
        return true
    }
}
