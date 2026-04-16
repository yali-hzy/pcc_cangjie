package pcc_cangjie.defs

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

    public static func reset(): Unit {
        generateTime = Duration.Zero
        evaluateTime = Duration.Zero
        generateForallTime = Duration.Zero
        evaluateForallTime = Duration.Zero
        generateExistsTime = Duration.Zero
        evaluateExistsTime = Duration.Zero
        evaluateBfuncTime = Duration.Zero
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
        return sb.toString()
    }
}
