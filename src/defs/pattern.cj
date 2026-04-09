package pcc_cangjie.defs

import std.time.DateTime

public class Pattern <: ToString {
    public Pattern(public let name: String, let category: ?String, let subject: ?String, let predicate: ?String,
        let object: ?String, let lifespan: ?Lifespan, let site: ?String, let timestamp: ?DateTime) {}

    public func toString(): String {
        return "Pattern(\n\tname=${name}, \n\tcategory=${category}, \n\tsubject=${subject}, \n\tpredicate=${predicate}, \n\tobject=${object}, \n\tlifespan=${lifespan}, \n\tsite=${site}, \n\ttimestamp=${timestamp}\n)"
    }

    public func matches(context: Context): Bool {
        if (let Some(category) <- this.category && category != context.category) {
            return false
        }
        if (let Some(subject) <- this.subject && subject != context.subject) {
            return false
        }
        if (let Some(predicate) <- this.predicate && predicate != context.predicate) {
            return false
        }
        if (let Some(object) <- this.object && object != context.object) {
            return false
        }
        if (let Some(lifespan) <- this.lifespan && lifespan != context.lifespan) {
            return false
        }
        if (let Some(site) <- this.site && site != context.site) {
            return false
        }
        if (let Some(timestamp) <- this.timestamp && timestamp != context.timestamp) {
            return false
        }
        return true
    }
}
