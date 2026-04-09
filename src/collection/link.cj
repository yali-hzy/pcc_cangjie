package pcc_cangjie.collection

import pcc_cangjie.defs.Context
import std.collection.{HashMap, ArrayList, map, collectArrayList, concat, flatMap}

public class AssignmentLinkedListNode {
    public AssignmentLinkedListNode(let prev: ?AssignmentLinkedListNode, public let assignment: Assignment) {}

    public func collectHashMap(): HashMap<Int, Context> {
        let map = HashMap<Int, Context>()
        var current: ?AssignmentLinkedListNode = Some(this)
        while (let Some(node) <- current) {
            map[node.assignment.varId] = node.assignment.ctx
            current = node.prev
        }
        return map
    }
}

public class Assignment {
    public Assignment(public let varId: Int, public let ctx: Context) {}
}

public enum LinkType <: ToString {
    Satisfied | Violated

    public func toString(): String {
        match (this) {
            case Satisfied => "Satisfied"
            case Violated => "Violated"
        }
    }
}

public class Link {
    public Link(public let linkType: LinkType, public let bindings: ArrayList<Assignment>) {}

    public func flip(): Link {
        Link(match (linkType) {
            case LinkType.Satisfied => LinkType.Violated
            case LinkType.Violated => LinkType.Satisfied
        }, bindings)
    }

    public func cartesian(other: Link): Link {
        Link(linkType, bindings |> (other.bindings |> concat) |> collectArrayList)
    }
}

public class Links {
    public Links(public let links: ArrayList<Link>) {}

    public func flipset(): Links {
        Links(links |> map({link => link.flip()}) |> collectArrayList)
    }

    public func product(other: Links): Links {
        if (links.isEmpty()) {
            return other
        }
        if (other.links.isEmpty()) {
            return this
        }
        return Links(
            links |> flatMap({link1 => other.links |> map({link2 => link1.cartesian(link2)})}) |> collectArrayList)
    }

    public func union(other: Links): Links {
        Links(links |> (other.links |> concat) |> collectArrayList)
    }
}
