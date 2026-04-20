package pcc_cangjie.defs

import std.runtime.*

public var FRESHNESS: Duration = 20 * Duration.second
public var DEBUG = false

public class DebugInfo <: ToString {
    public static var generateTime: Duration = Duration.Zero
    public static var evaluateTime: Duration = Duration.Zero
    public static var generateForallTime: Duration = Duration.Zero
    public static var evaluateForallTime: Duration = Duration.Zero
    public static var generateExistsTime: Duration = Duration.Zero
    public static var evaluateExistsTime: Duration = Duration.Zero
    public static var evaluateBfuncTime: Duration = Duration.Zero
    public static var evaluateIterateCount: Int = 0
    public static var generateCount: Int = 0
    public static var evaluateIterateCapacity: Int = 0
    public static var gcCount: Int = 0
    public static var gcTime: Duration = Duration.Zero
    public static var gcFreedSize: Int = 0
    public static var evaluateMaxIterateSize: Int = 0
    public static var evaluateMaxIterateCapacity: Int = 0
    public static var quantifierHelperIterateTime: Duration = Duration.Zero
    public static var otherTime: Duration = Duration.Zero
    public static var listenerTime: Duration = Duration.Zero
    public static var assignmentTime: Duration = Duration.Zero

    public static func reset(): Unit {
        generateTime = Duration.Zero
        evaluateTime = Duration.Zero
        generateForallTime = Duration.Zero
        evaluateForallTime = Duration.Zero
        generateExistsTime = Duration.Zero
        evaluateExistsTime = Duration.Zero
        evaluateBfuncTime = Duration.Zero
        evaluateIterateCount = 0
        generateCount = 0
        evaluateIterateCapacity = 0
        gcCount = getGCCount()
        gcTime = getGCTime() * Duration.microsecond
        gcFreedSize = getGCFreedSize()
        evaluateMaxIterateSize = 0
        evaluateMaxIterateCapacity = 0
        quantifierHelperIterateTime = Duration.Zero
        otherTime = Duration.Zero
        listenerTime = Duration.Zero
        assignmentTime = Duration.Zero
    }

    public func toString(): String {
        let sb = StringBuilder()
        sb.append("DebugInfo:\n")
        sb.append("  generateTime: ${generateTime}\n")
        sb.append("  evaluateTime: ${evaluateTime}\n")
        sb.append("  generateForallTime: ${generateForallTime}\n")
        sb.append("  evaluateForallTime: ${evaluateForallTime}\n")
        sb.append("  generateExistsTime: ${generateExistsTime}\n")
        sb.append("  evaluateExistsTime: ${evaluateExistsTime}\n")
        sb.append("  evaluateBfuncTime: ${evaluateBfuncTime}\n")
        sb.append("  evaluateIterateCount: ${evaluateIterateCount}\n")
        sb.append("  generateCount: ${generateCount}\n")
        sb.append("  evaluateIterateCapacity: ${evaluateIterateCapacity}\n")
        sb.append("  gcCount: ${getGCCount() - gcCount}\n")
        sb.append("  gcTime: ${getGCTime() * Duration.microsecond - gcTime}\n")
        sb.append("  gcFreedSize: ${getGCFreedSize() - gcFreedSize}\n")
        sb.append("  maxHeapSize: ${getMaxHeapSize()}\n")
        sb.append("  usedHeapSize: ${getUsedHeapSize()}\n")
        sb.append("  evaluateMaxIterateSize: ${evaluateMaxIterateSize}\n")
        sb.append("  evaluateMaxIterateCapacity: ${evaluateMaxIterateCapacity}\n")
        sb.append("  getAllocatedHeapSize: ${getAllocatedHeapSize()}\n")
        sb.append("  quantifierHelperIterateTime: ${quantifierHelperIterateTime}\n")
        sb.append("  otherTime: ${otherTime}\n")
        sb.append("  listenerTime: ${listenerTime}\n")
        sb.append("  assignmentTime: ${assignmentTime}\n")
        return sb.toString()
    }
}

public var maxUsedHeapSize: Int = 0
public var maxAllocatedHeapSize: Int = 0
