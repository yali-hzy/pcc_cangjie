package pcc_cangjie.check

import pcc_cangjie.defs.{Context, FRESHNESS}
import pcc_cangjie.timing.GlobalTimer
import std.collection.HashMap
import std.sync.Timer

class ContextSet {
    let contextSet = HashMap<Int, (Context, Int)>()

    ContextSet(let id: Int, let checker: CctChecker, let freshness!: Duration = FRESHNESS) {}

    func add(contextId: Int, context: Context): Unit {
        // if (context.timestamp + freshness <= GlobalTimer.getOrThrow().now()) {
        //     println("Context ${contextId} with timestamp ${context.timestamp} is already expired, skipping")
        //     return
        // }
        synchronized(checker.mutex) {
            contextSet[contextId] = (context, 0)
            checker.addChangeNum++
            for ((cctId, nodeList) in checker.PatternMap[id]) {
                // if (context.timestamp + freshness <= GlobalTimer.getOrThrow().now()) {
                //     break
                // }
                contextSet[contextId] = (context, contextSet[contextId][1] + 1)
                checker.method.getOrThrow().handleAdd(checker.CCTs[cctId], nodeList, contextId, context)
            }
        }
        Timer.once(
            context.timestamp + freshness - GlobalTimer.getOrThrow().now(),
            {
                => synchronized(checker.mutex) {
                    checker.deleteChangeNum++
                    var count = contextSet[contextId][1]
                    contextSet.remove(contextId)
                    for ((cctId, nodeList) in checker.PatternMap[id]) {
                        if (count <= 0) {
                            break
                        }
                        checker.method.getOrThrow().handleDelete(checker.CCTs[cctId], nodeList, contextId)
                        count--
                    }
                    if (checker.addChangeNum == checker.deleteChangeNum) {
                        checker.finish.notify()
                    }
                }
            }
        )
    }

    func offlineAdd(contextId: Int, context: Context): Unit {
        contextSet[contextId] = (context, 0)
        for ((cctId, nodeList) in checker.PatternMap[id]) {
            checker.method.getOrThrow().handleAdd(checker.CCTs[cctId], nodeList, contextId, context)
        }
    }

    func offlineDelete(contextId: Int): Unit {
        contextSet.remove(contextId)
        for ((cctId, nodeList) in checker.PatternMap[id]) {
            checker.method.getOrThrow().handleDelete(checker.CCTs[cctId], nodeList, contextId)
        }
    }
}
