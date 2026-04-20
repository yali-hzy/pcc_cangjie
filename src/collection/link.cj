package pcc_cangjie.collection

import pcc_cangjie.defs.Context
import std.collection.{HashMap, ArrayList, map, collectArrayList, concat, flatMap}

public class AssignmentLinkedListNode {
    public AssignmentLinkedListNode(let prev: ?AssignmentLinkedListNode, public let assignment: Assignment) {}

    public func collectHashMap(capacity: Int): HashMap<Int, Context> {
        let map = HashMap<Int, Context>(capacity)
        var current: ?AssignmentLinkedListNode = Some(this)
        while (let Some(node) <- current) {
            map[node.assignment.varId] = node.assignment.ctx
            current = node.prev
        }
        return map
    }

    private static let _hashMap = HashMap<Int, Context>()
    public func collectArray(argsId: Array<Int>): Array<Context> {
        let arr = Array<Context>(argsId.size, repeat: Context())
        var current: ?AssignmentLinkedListNode = Some(this)
        while (let Some(node) <- current) {
            _hashMap[node.assignment.varId] = node.assignment.ctx
            current = node.prev
        }
        for ((i, varId) in argsId.enumerate()) {
            arr[i] = _hashMap[varId]
        }
        return arr
    }
}

public class Assignment {
    public Assignment(public let varId: Int, public let ctx: Context) {}
}

public enum LinkType <: ToString {
    Satisfied | Violated

    public func toString(): String {
        match (this) {
            case Satisfied => "satisfied"
            case Violated => "violated"
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
        let resultBindings = ArrayList<Assignment>(bindings)
        resultBindings.add(all: other.bindings)
        return Link(linkType, resultBindings)
        // Link(linkType, bindings |> (other.bindings |> concat) |> collectArrayList)
    }
}

public class Links {
    public Links(public let links: ArrayList<Link>) {}

    public func flipset(): Links {
        let flippedLinks = ArrayList<Link>(links.size)
        for (link in links) {
            flippedLinks.add(link.flip())
        }
        return Links(flippedLinks)
    }

    public func product(other: Links): Links {
        if (links.isEmpty()) {
            return other
        }
        if (other.links.isEmpty()) {
            return this
        }
        // return Links(
        //     links |> flatMap({link1 => other.links |> map({link2 => link1.cartesian(link2)})}) |> collectArrayList)
        let resultLinks = ArrayList<Link>()
        for (link1 in links) {
            for (link2 in other.links) {
                let productLink = link1.cartesian(link2)
                resultLinks.add(productLink)
            }
        }
        return Links(resultLinks)
    }

    public func union(other: Links): Links {
        let resultLinks = ArrayList<Link>(links)
        resultLinks.add(all: other.links)
        return Links(resultLinks)
        // Links(links |> (other.links |> concat) |> collectArrayList)
    }
}
