package pcc_cangjie.parse

import pcc_cangjie.defs.{Pattern, Lifespan}
import std.convert.Parsable
import std.collection.ArrayList
import std.time.DateTime

public func parsePatternsFromXml(xml: XmlTree): Array<Pattern> {
    let patterns = ArrayList<Pattern>()
    for (patternNode in xml.childNodes) {
        if (patternNode.nodeName == "pattern") {
            let pat = Pattern(patternNode.attributes["name"])

            for (child in patternNode.childNodes) {
                match (child.nodeName) {
                    case "category" => pat.category = nodeValueTransform(child.nodeValue)
                    case "subject" => pat.subject = nodeValueTransform(child.nodeValue)
                    case "predicate" => pat.predicate = nodeValueTransform(child.nodeValue)
                    case "object" => pat.object = nodeValueTransform(child.nodeValue)
                    case "lifespan" => pat.lifespan = nodeValueTransform(child.nodeValue).map(parseLifespan)
                    case "site" => pat.site = nodeValueTransform(child.nodeValue)
                    case "timestamp" => pat.timestamp = nodeValueTransform(child.nodeValue).map(
                        parseDateTimeFromTimeStamp)
                    case _ => throw PatternParseException("Unknown pattern field: ${child.nodeName}")
                }
            }

            patterns.add(pat)
        }
    }
    return patterns.toArray()
}

public func parseTaxiPatternsFromXml(xml: XmlTree): Array<Pattern> {
    let patterns = ArrayList<Pattern>()
    for (patternNode in xml.childNodes) {
        if (patternNode.nodeName == "pattern") {
            var name: ?String = None
            var category: ?String = None
            var subject: ?String = None
            var predicate: ?String = None
            var object: ?String = None
            var lifespan: ?Lifespan = None
            var site: ?String = None
            var timestamp: ?DateTime = None
            var freshness: ?Duration = None

            for (child in patternNode.childNodes) {
                match (child.nodeName) {
                    case "id" => name = nodeValueTransform(child.nodeValue)
                    case "freshness" => freshness = nodeValueTransform(child.nodeValue).map {
                        str => Int.parse(str) * Duration.millisecond
                    }
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

            let pat = Pattern(name.getOrThrow())
            pat.category = category
            pat.subject = subject
            pat.predicate = predicate
            pat.object = object
            pat.lifespan = lifespan
            pat.site = site
            pat.timestamp = timestamp
            pat.freshness = freshness.getOrThrow()

            patterns.add(pat)
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
