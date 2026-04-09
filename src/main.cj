package pcc_cangjie

import std.argopt.{ArgumentSpec, ArgumentMode, parseArguments, ArgumentParseException}
import std.collection.{ArrayList, HashMap, Map, forEach}
import std.fs.{File, Path, OpenMode}
import std.io.readString
import std.collection.concurrent.LinkedBlockingQueue
import std.unicode.UnicodeStringExtension
import std.convert.Parsable
import pcc_cangjie.defs.{Context, Pattern, Constraint, FRESHNESS}
import pcc_cangjie.parse.{parsePatternsFromXml, parseConstraintsFromXml, parseDateTimeFromTimeStamp, parseLifespan, 
    XmlParser}
import pcc_cangjie.check.CctChecker
import pcc_cangjie.timing.{GlobalTimer, MockTimer}
import pcc_cangjie.logger.{LOGGER, Logger}
import pcc_cangjie.collection.ContextFlow

main(args: Array<String>): Int64 {
    let options = parseArgs(args).getOrThrow()
    let dataPath = options["data"]
    let convert = options["convert"]
    let method = options["method"]
    let freshness = Int.parse(options["freshness"])
    let interval = Int.parse(options["interval"])
    LOGGER = Logger(options["outdir"], "context_check_${convert}_${method}_${freshness}_${interval}.log")
    let (contexts, patterns, constraints) = loadData(dataPath)
    for (constraint in constraints) {
        println("Constraint: ${constraint.name}, formula: ${constraint.formula}")
    }
    FRESHNESS = freshness * Duration.second
    let cctChecker = CctChecker(patterns)
    cctChecker.initialize(constraints, convert: convert)
    let ctxBlockingQueue = LinkedBlockingQueue<Context>()
    GlobalTimer = if (options.contains("start_time")) {
        let startTime = parseDateTimeFromTimeStamp(options["start_time"])
        MockTimer(startTime)
    } else {
        MockTimer(contexts[0].timestamp)
    }
    let contextsFlow = ContextFlow(interval * Duration.millisecond, ctxBlockingQueue, contexts.iterator())
    cctChecker.check(contextsFlow, method: method)
    LOGGER.getOrThrow().close()
    return 0
}

func parseArgs(args: Array<String>): Option<Map<String, String>> {
    try {
        let dataSpec = ArgumentSpec.Long("data", ArgumentMode.RequiredValue)
        let convertSpec = ArgumentSpec.Long("convert", ArgumentMode.RequiredValue)
        let methodSpec = ArgumentSpec.Long("method", ArgumentMode.RequiredValue)
        let freshnessSpec = ArgumentSpec.Long("freshness", ArgumentMode.RequiredValue)
        let outDirSpec = ArgumentSpec.Long("outdir", ArgumentMode.RequiredValue)
        let intervalSpec = ArgumentSpec.Long("interval", ArgumentMode.RequiredValue)
        let startTimeSpec = ArgumentSpec.Long("start_time", ArgumentMode.RequiredValue)
        let specs = [dataSpec, convertSpec, methodSpec, freshnessSpec, outDirSpec, intervalSpec, startTimeSpec]
        let resultMap = HashMap<String, String>(
            [("convert", "kernel"), ("method", "ecc"), ("freshness", "20"), ("outdir", "log"), ("interval", "400")])
        let parsed = parseArguments(args, specs)
        parsed.options |> forEach {
            option => match (option[0]) {
                case "data" => resultMap["data"] = option[1]
                case "convert" => resultMap["convert"] = option[1]
                case "method" => resultMap["method"] = option[1]
                case "freshness" => resultMap["freshness"] = option[1]
                case "outdir" => resultMap["outdir"] = option[1]
                case "interval" => resultMap["interval"] = option[1]
                case "start_time" => resultMap["start_time"] = option[1]
                case _ => throw IllegalArgumentException("Unknown option: ${option[0]}")
            }
        }
        println("Parsed arguments: ${resultMap}")
        return resultMap
    } catch (e: ArgumentParseException) {
        println("Error parsing arguments: ${e.message}")
        return None
    }
}

func loadData(path: String): (Array<Context>, Array<Pattern>, Array<Constraint>) {
    let contextsPath = Path(path).join("contexts.txt")
    let patternsPath = Path(path).join("patterns.xml")
    let constraintsPath = Path(path).join("constraints.xml")
    let contexts = ArrayList<Context>()
    var patterns = Array<Pattern>()
    var constraints = Array<Constraint>()

    try (contextsFile = File(contextsPath, Read)) {
        let contextsStr = readString(contextsFile).split("\n", removeEmpty: true)
        for (line in contextsStr) {
            let parts = line.trim().split(", ", removeEmpty: true)
            contexts.add(
                Context(parts[0], parts[1], parts[2], parts[3], parseLifespan(parts[4]), parts[5],
                    parseDateTimeFromTimeStamp(parts[6])))
        }
    }

    let parser = XmlParser()

    try (patternsFile = File(patternsPath, Read)) {
        let patternsStr = readString(patternsFile)
        let patternsTree = parser.parseFromString(patternsStr)
        patterns = parsePatternsFromXml(patternsTree)
    }

    try (constraintsFile = File(constraintsPath, Read)) {
        let constraintsStr = readString(constraintsFile)
        let constraintsTree = parser.parseFromString(constraintsStr)
        constraints = parseConstraintsFromXml(constraintsTree)
    }

    (contexts.toArray(), patterns, constraints)
}
