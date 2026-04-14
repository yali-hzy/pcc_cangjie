// 假定文本（Text）只出现在叶子节点

package pcc_cangjie.parse

import std.collection.{ArrayList, ArrayStack, HashSet, List, Map, HashMap}
import std.regex.{Regex, RegexFlag}
import std.unicode.UnicodeStringExtension
import std.convert.{Parsable, RadixConvertible}

public class XmlParser {
    private let tokens = ArrayList<(String, String)>()
    private let stack = ArrayStack<XmlNode>()

    public func parseFromString(xml: String): XmlTree {
        initialize()
        xml |> normalizeLineBreaks |> tokenize
        parse()
    }

    private func initialize(): Unit {
        tokens.clear()
        stack.clear()
    }

    private func tokenize(xml: String): Unit {
        let reRemove = Regex(#"(<!--.*?-->)|(<\?xml.*?\?>)"#, [MultiLine, Unicode])
        let cleanedXml = reRemove.replaceAll(xml, "")
        let reToken = Regex(#"<(?<tag>(/?)(\w+)(.*?))>|(?<text>[^<]+)"#, [MultiLine, Unicode])
        for (md in reToken.lazyFindAll(cleanedXml, group: true)) {
            for ((name, _index) in reToken.getNamedGroups()) {
                try {
                    if (let matchStr <- md.matchString(name).trim() && !matchStr.isEmpty()) {
                        tokens.add((name, matchStr))
                    }
                } catch (e: IndexOutOfBoundsException) {
                    // 标准库实现错误 Version 1.0.5
                }
            }
        }
    }

    private func parse(): XmlTree {
        var root: ?XmlNode = None
        for ((name, value) in tokens) {
            if (name == "tag") {
                if (value.startsWith("/")) {
                    let stackTopStr = if (stack.isEmpty()) {
                        ""
                    } else {
                        stack.peek().getOrThrow().nodeName
                    }
                    if (stackTopStr != value[1..]) {
                        throw XmlParseException("Mismatched closing tag: ${value}, expected: ${stackTopStr}")
                    }
                    stack.remove()
                    continue
                }
                var emptyElem = false
                let trimmedValue = if (value.endsWith('/')) {
                    emptyElem = true
                    value.trimEnd('/').trim()
                } else {
                    value
                }
                let parts = trimmedValue.split(" ", removeEmpty: true)
                let tagName = parts[0]
                let newNode = XmlNode(tagName, if (stack.isEmpty()) {
                    None
                } else {
                    stack.peek()
                })
                // println("Parsed tag: ${tagName}, attributes: ${parts[1..]}")
                let partsList = ArrayList<String>()
                for (i in 1..parts.size) {
                    let attrParts = parts[i].split("=", 2, removeEmpty: true)
                    partsList.add(all: attrParts)
                }
                // println("Parsed attributes: ${partsList}")
                for (i in 0..partsList.size : 2) {
                    let attrName = partsList[i]
                    let value = partsList[i + 1]
                    // println("Parsed attribute: ${attrName} = ${value}")
                    if (!(value.startsWith('"') && value.endsWith('"') || value.startsWith("'") && value.endsWith("'"))) {
                        throw XmlParseException("Invalid attribute format: ${parts[i]}")
                    }
                    let attrValue = value[1..value.size - 1]
                    newNode.attributes[attrName] = attrValue |> xmlRefDecode
                }
                if (root.isNone()) {
                    root = newNode
                } else {
                    stack.peek().getOrThrow().childNodes.add(newNode)
                }
                if (!emptyElem) {
                    stack.add(newNode)
                }
            } else if (name == "text") {
                stack.peek().getOrThrow().nodeValue += value.trim() |> xmlRefDecode
            }
        }
        return root.getOrThrow()
    }
}

// 可惜 StringBuilder 没有 replace 方法

public func normalizeLineBreaks(str: String): String {
    return str.replace("\r\n", "\n").replace("\r", "\n")
}

public func xmlRefDecode(str: String): String {
    str |> xmlEntityRefDecode |> xmlCharRefDecode
}

public func xmlEntityRefDecode(str: String): String {
    return str
        .replace("&lt;", "<")
        .replace("&gt;", ">")
        .replace("&apos;", "'")
        .replace("&quot;", "\"")
        .replace("&amp;", "&")
}

public func xmlCharRefDecode(str: String): String {
    var result = str
    let reCharRef = Regex(#"&#(\d+|x[0-9a-fA-F]+);"#, [MultiLine, Unicode])
    let charRefs = HashSet(reCharRef.findAll(str).map {md => md.matchString()})
    for (charRef in charRefs) {
        let charCode = if (charRef.startsWith('&#x')) {
            Rune(Int.parse(charRef[3..charRef.size - 1], radix: 16))
        } else {
            Rune(Int.parse(charRef[2..charRef.size - 1]))
        }
        result = result.replace("${charRef}", charCode.toString())
    }
    return result
}

public class XmlNode {
    public var nodeValue: String = ""
    public let childNodes: List<XmlNode> = ArrayList<XmlNode>()
    public let attributes: Map<String, String> = HashMap<String, String>()
    public XmlNode(let nodeName: String, let parentNode: ?XmlNode) {}
}

type XmlTree = XmlNode

class XmlParseException <: Exception {
    public init(message: String) {
        super(message)
    }

    public override func getClassName(): String {
        "XmlParseException"
    }
}
