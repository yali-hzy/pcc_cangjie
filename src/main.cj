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
    XmlParser, parseDateTimeFromStr, parseTaxiPatternsFromXml, parseTaxiConstraintsFromXml}
import pcc_cangjie.check.CctChecker
import pcc_cangjie.timing.{GlobalTimer, MockTimer}
import pcc_cangjie.logger.{LOGGER, Logger}
import pcc_cangjie.collection.ContextFlow
import pcc_cangjie.defs.VERBOSE

// cjpm run --run-args "--data data/data_with_link_oracles --context data/data_1/0-1.txt --pattern consistency_patterns_48.xml --constraint consistency_rules_48.xml --convert none --offline --outdir link_oracle/data_1 --outfile 0-1_answer.txt --method pcc"
main(args: Array<String>): Int64 {
    let options = parseArgs(args).getOrThrow()
    let dataPath = options["data"]
    let convert = options["convert"]
    let method = options["method"]
    let freshness = Int.parse(options["freshness"])
    let interval = Int.parse(options["interval"])
    let outfile = options
        .get("outfile")
        .getOrDefault {=> "context_check_${convert}_${method}_${freshness}_${interval}.log"}
    LOGGER = Logger(options["outdir"], outfile)
    if (VERBOSE) {
        LOGGER.getOrThrow().log("Running with args: ${args}")
    }
    if (!options.contains("offline")) {
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
    } else {
        let contextPath = options["context"]
        let patternPath = options["pattern"]
        let constraintPath = options["constraint"]
        let (contexts, patterns, constraints) = loadTaxiData(dataPath, contextPath: contextPath,
            patternPath: patternPath, constraintPath: constraintPath)
        for (constraint in constraints) {
            println("Constraint: ${constraint.name}, formula: ${constraint.formula}")
        }
        let cctChecker = CctChecker(patterns)
        cctChecker.initialize(constraints, convert: convert)
        println("Finished initializing checker, starting offline check")
        cctChecker.check(contexts, method: method)
    }
    LOGGER.getOrThrow().close()
    return 0
}

func parseArgs(args: Array<String>): Option<Map<String, String>> {
    try {
        let dataSpec = ArgumentSpec.Long("data", ArgumentMode.RequiredValue)
        let contextSpec = ArgumentSpec.Long("context", ArgumentMode.RequiredValue)
        let patternSpec = ArgumentSpec.Long("pattern", ArgumentMode.RequiredValue)
        let constraintSpec = ArgumentSpec.Long("constraint", ArgumentMode.RequiredValue)
        let convertSpec = ArgumentSpec.Long("convert", ArgumentMode.RequiredValue)
        let methodSpec = ArgumentSpec.Long("method", ArgumentMode.RequiredValue)
        let freshnessSpec = ArgumentSpec.Long("freshness", ArgumentMode.RequiredValue)
        let outDirSpec = ArgumentSpec.Long("outdir", ArgumentMode.RequiredValue)
        let intervalSpec = ArgumentSpec.Long("interval", ArgumentMode.RequiredValue)
        let startTimeSpec = ArgumentSpec.Long("start_time", ArgumentMode.RequiredValue)
        let offlineSpec = ArgumentSpec.Long("offline", ArgumentMode.NoValue)
        let outFileSpec = ArgumentSpec.Long("outfile", ArgumentMode.RequiredValue)
        let verboseSpec = ArgumentSpec.Full("verbose", r'v', ArgumentMode.NoValue)
        let specs = [dataSpec, contextSpec, patternSpec, constraintSpec, convertSpec, methodSpec, freshnessSpec,
            outDirSpec, intervalSpec, startTimeSpec, offlineSpec, outFileSpec, verboseSpec]
        let resultMap = HashMap<String, String>(
            [("context", "context.txt"), ("pattern", "patterns.xml"), ("constraint", "constraints.xml"),
                ("convert", "kernel"), ("method", "ecc"), ("freshness", "20"), ("outdir", "log"), ("interval", "400")])
        let parsed = parseArguments(args, specs)
        parsed.options |> forEach {
            option => match (option[0]) {
                case "data" => resultMap["data"] = option[1]
                case "context" => resultMap["context"] = option[1]
                case "pattern" => resultMap["pattern"] = option[1]
                case "constraint" => resultMap["constraint"] = option[1]
                case "convert" => resultMap["convert"] = option[1]
                case "method" => resultMap["method"] = option[1]
                case "freshness" => resultMap["freshness"] = option[1]
                case "outdir" => resultMap["outdir"] = option[1]
                case "interval" => resultMap["interval"] = option[1]
                case "start_time" => resultMap["start_time"] = option[1]
                case "offline" => resultMap["offline"] = option[1]
                case "outfile" => resultMap["outfile"] = option[1]
                case "verbose" => VERBOSE = true
                case "v" => VERBOSE = true
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

func loadTaxiData(path: String, contextPath!: String = "contexts.txt", patternPath!: String = "patterns.xml",
    constraintPath!: String = "constraints.xml"): (Array<Context>, Array<Pattern>, Array<Constraint>) {
    let contextsPath = Path(path).join(contextPath)
    let patternsPath = Path(path).join(patternPath)
    let constraintsPath = Path(path).join(constraintPath)
    let contexts = ArrayList<Context>()
    var patterns = Array<Pattern>()
    var constraints = Array<Constraint>()

    try (contextsFile = File(contextsPath, Read)) {
        let contextsStr = readString(contextsFile).split("\n", removeEmpty: true)
        for (line in contextsStr) {
            let parts = line.trim().split(",", removeEmpty: true)
            let ctx = Context()
            ctx.category = "location"
            ctx.timestamp = parseDateTimeFromStr(parts[0])
            ctx.subject = parts[1]
            ctx.longitude = Float64.parse(parts[2])
            ctx.latitude = Float64.parse(parts[3])
            ctx.speed = Float64.parse(parts[4])
            let direction = parts[5]
            let status = Int.parse(parts[6])
            ctx.predicate = if (status == 0) {
                "run_without_service"
            } else {
                "run_with_service"
            }
            ctx.site = "sutpc_${Rune(parts[1][parts[1].size - 2])}"
            // println("Parsed context: ${ctx}")
            contexts.add(ctx)
        }
    }

    let parser = XmlParser()

    try (patternsFile = File(patternsPath, Read)) {
        let patternsStr = readString(patternsFile)
        let patternsTree = parser.parseFromString(patternsStr)
        patterns = parseTaxiPatternsFromXml(patternsTree)
    }

    try (constraintsFile = File(constraintsPath, Read)) {
        let constraintsStr = readString(constraintsFile)
        let constraintsTree = parser.parseFromString(constraintsStr)
        constraints = parseTaxiConstraintsFromXml(constraintsTree)
    }

    (contexts.toArray(), patterns, constraints)
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
            let ctx = Context()
            ctx.category = parts[0]
            ctx.subject = parts[1]
            ctx.predicate = parts[2]
            ctx.object = parts[3]
            ctx.lifespan = parseLifespan(parts[4])
            ctx.site = parts[5]
            ctx.timestamp = parseDateTimeFromTimeStamp(parts[6])
            contexts.add(ctx)
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
