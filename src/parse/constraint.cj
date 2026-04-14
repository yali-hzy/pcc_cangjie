package pcc_cangjie.parse

import pcc_cangjie.defs.{Constraint, Formula}
import std.collection.ArrayList

public func parseConstraintsFromXml(xml: XmlTree): Array<Constraint> {
    let constraints = ArrayList<Constraint>()
    for (constraintNode in xml.childNodes) {
        if (constraintNode.nodeName == "constraint") {
            let name: String = constraintNode.attributes["name"]
            let formula: Formula = parseFormulaFromXml(constraintNode.childNodes[0])
            constraints.add(Constraint(name, formula))
        }
    }
    return constraints.toArray()
}

public func parseTaxiConstraintsFromXml(xml: XmlTree): Array<Constraint> {
    let constraints = ArrayList<Constraint>()
    for (constraintNode in xml.childNodes) {
        if (constraintNode.nodeName == "rule") {
            var name: ?String = None
            var formula: ?Formula = None
            for (child in constraintNode.childNodes) {
                if (child.nodeName == "id") {
                    name = child.nodeValue
                } else if (child.nodeName == "formula") {
                    formula = parseFormulaFromXml(child.childNodes[0])
                } else {
                    throw ConstraintParseException("Unknown constraint field: ${child.nodeName}")
                }
            }
            constraints.add(Constraint(name.getOrThrow(), formula.getOrThrow()))
        }
    }
    return constraints.toArray()
}

public func parseFormulaFromXml(node: XmlTree): Formula {
    match (node.nodeName) {
        case "forall" => Forall(node.attributes["var"], node.attributes["in"], parseFormulaFromXml(node.childNodes[0]))
        case "exists" => Exists(node.attributes["var"], node.attributes["in"], parseFormulaFromXml(node.childNodes[0]))
        case "and" => And(parseFormulaFromXml(node.childNodes[0]), parseFormulaFromXml(node.childNodes[1]))
        case "or" => Or(parseFormulaFromXml(node.childNodes[0]), parseFormulaFromXml(node.childNodes[1]))
        case "implies" => Implies(parseFormulaFromXml(node.childNodes[0]), parseFormulaFromXml(node.childNodes[1]))
        case "not" => Not(parseFormulaFromXml(node.childNodes[0]))
        case "bfunc" => Bfunc(node.attributes["name"], node.childNodes.toArray().map {child => child.attributes["var"]})
        case _ => throw ConstraintParseException("Unknown formula type: ${node.nodeName}")
    }
}

class ConstraintParseException <: Exception {
    public init(message: String) {
        super(message)
    }

    public override func getClassName(): String {
        "ConstraintParseException"
    }
}
