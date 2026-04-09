package pcc_cangjie.parse

import pcc_cangjie.defs.{Pattern, Lifespan}
import std.collection.ArrayList
import std.time.DateTime

public func parsePatternsFromXml(xml: XmlTree): Array<Pattern> {
    let patterns = ArrayList<Pattern>()
    for (patternNode in xml.childNodes) {
        if (patternNode.nodeName == "pattern") {
            var category: ?String = None
            var subject: ?String = None
            var predicate: ?String = None
            var object: ?String = None
            var lifespan: ?Lifespan = None
            var site: ?String = None
            var timestamp: ?DateTime = None

            for (child in patternNode.childNodes) {
                match (child.nodeName) {
                    case "category" => category = nodeValueTransform(child.nodeValue)
                    case "subject" => subject = nodeValueTransform(child.nodeValue)
                    case "predicate" => predicate = nodeValueTransform(child.nodeValue)
                    case "object" => object = nodeValueTransform(child.nodeValue)
                    case "lifespan" => lifespan = nodeValueTransform(child.nodeValue).map(parseLifespan)
                    case "site" => site = nodeValueTransform(child.nodeValue)
                    case "timestamp" => timestamp = nodeValueTransform(child.nodeValue).map(parseDateTimeFromTimeStamp)
                    case _ => throw PatternParseException("Unknown pattern field: ${child.nodeName}")
                }
            }

            patterns.add(
                Pattern(patternNode.attributes["name"], category, subject, predicate, object, lifespan, site, timestamp))
        }
    }
    return patterns.toArray()
}

private func nodeValueTransform(value: String): ?String {
    if (value.isEmpty() || value == "any") {
        return None
    } else {
        return Some(value)
    }
}

class PatternParseException <: Exception {
    public init(message: String) {
        super(message)
    }

    public override func getClassName(): String {
        "PatternParseException"
    }
}
