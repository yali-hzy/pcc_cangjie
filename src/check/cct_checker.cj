package pcc_cangjie.check

import pcc_cangjie.defs.{Context, Pattern, Constraint}
import pcc_cangjie.collection.ContextFlow
import std.collection.{HashMap, Map, ArrayList, enumerate, map, collectArray}
import std.collection.concurrent.LinkedBlockingQueue
import std.sync.Mutex

public class CctChecker {
    let PatternNames2Id: HashMap<String, Int> = HashMap<String, Int>()
    let ConstraintNames2Id: HashMap<String, Int> = HashMap<String, Int>()
    let PatternMap = HashMap<Int, Map<Int, ArrayList<Int>>>() // patternId -> constraintId -> list(dfn)
    var CCTs: Array<Cct> = []
    var ContextSets: Array<ContextSet> = []
    var addChangeNum = 0
    var deleteChangeNum = 0
    var method: ?CheckMethod = None
    let mutex = Mutex()
    let finish = synchronized(mutex) {
        mutex.condition()
    }

    func validateName(patterns: Array<Pattern>, constraints: Array<Constraint>) {
        for ((i, pattern) in enumerate(patterns)) {
            if (PatternNames2Id.contains(pattern.name)) {
                throw DuplicateNameException("Duplicate pattern name '${pattern.name}' found in patterns list")
            } else {
                PatternNames2Id[pattern.name] = i
            }
        }
        for ((i, constraint) in enumerate(constraints)) {
            if (ConstraintNames2Id.contains(constraint.name)) {
                throw DuplicateNameException("Duplicate constraint name '${constraint.name}' found in constraints list")
            } else {
                ConstraintNames2Id[constraint.name] = i
            }
        }
    }

    public CctChecker(let patterns: Array<Pattern>) {}

    public func initialize(constraints: Array<Constraint>, convert!: String): Unit {
        validateName(patterns, constraints)
        let convertedConstraints = constraints.map {
            constraint: Constraint => match (convert) {
                case "kernel" => Constraint(constraint.name, kernelConvert(constraint.formula))
                case "notleaf" => Constraint(constraint.name, notLeafConvert(constraint.formula))
                case "none" => constraint
                case _ => throw IllegalArgumentException("Unsupported convert method: ${convert}")
            }
        }
        let syntaxTreeBuilder = SyntaxTreeBuilder(PatternNames2Id, PatternMap)
        // no Array.enumerate in version 1.0.5
        CCTs = convertedConstraints |> enumerate |> map {
            item =>
                let (i, constraint) = item
                let syntaxTree = syntaxTreeBuilder.build(i, constraint)
                println("syntaxTree ${i}: ${syntaxTree.root}")
                Cct(syntaxTree)
        } |> collectArray

        ContextSets = Array(patterns.size, {i => ContextSet(i, this)})
    }

    public func check(contexts: ContextFlow, method!: String): Unit {
        match (method) {
            case "ecc" => this.method = EccMethod(this)
            case "pcc" => this.method = PccMethod(this)
            case _ => throw IllegalArgumentException("Unsupported check method: ${method}")
        }
        var n = 0
        while (true) {
            let context = contexts.queue.remove()
            if (context == Context.POISON_CONTEXT) {
                contexts.cancel()
                synchronized(mutex) {
                    finish.waitUntil {=> addChangeNum == deleteChangeNum}
                }
                break
            }
            n++
            for ((i, pattern) in enumerate(patterns)) {
                if (pattern.matches(context)) {
                    println("Context matches pattern: ${pattern}")
                    ContextSets[i].add(n, context)
                }
            }
        }
    }
}

class DuplicateNameException <: Exception {
    init(message: String) {
        super(message)
    }
    public override func getClassName(): String {
        return "DuplicateNameException"
    }
}
