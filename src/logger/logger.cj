package pcc_cangjie.logger

import pcc_cangjie.timing.GlobalTimer
import std.fs.{File, Path, Directory, removeIfExists, exists}
import std.collection.HashSet
import pcc_cangjie.defs.{maxUsedHeapSize, maxAllocatedHeapSize}
import std.runtime.{getGCCount, getGCTime, getGCFreedSize}
import pcc_cangjie.defs.VERBOSE

public class Logger <: Resource {
    let logFile: File
    var closed = false

    private let linkSet = HashSet<String>()
    private var elapsedTime = Duration.Zero
    private var lastOutTime = Duration.Zero
    private var gcStartCount = getGCCount()
    private var gcStartTime = getGCTime() * Duration.microsecond
    private var gcStartFreedSize = getGCFreedSize()
    private var addTime = Duration.Zero
    private var deleteTime = Duration.Zero

    public init(dir: String, fileName: String) {
        let logDir = Path(dir).normalize()
        let logFilePath = logDir.join(fileName)
        println("Initializing logger with directory: ${logDir}, file name: ${fileName}")
        if (!exists(logDir)) {
            Directory.create(logDir, recursive: true)
        }
        removeIfExists(logFilePath)
        println("Logging to file: ${logFilePath}")
        logFile = File.create(logFilePath)
    }

    public func start(): Unit {
        gcStartCount = getGCCount()
        gcStartTime = getGCTime() * Duration.microsecond
        gcStartFreedSize = getGCFreedSize()
    }

    public func log(message: String): Unit {
        // let msg = "[${GlobalTimer.getOrThrow().now()}] ${message}\n"
        // logFile.write(msg.toArray())
        // print(msg)
        if (VERBOSE) {
            logFile.write("${message}\n".toArray())
            return
        }
        if (!message.isEmpty() && !linkSet.contains(message)) {
            logFile.write("${message}\n".toArray())
            // println(message)
            linkSet.add(message)
        }
    }

    public func addDuration(duration: Duration, tag: Int): Unit {
        elapsedTime += duration
        if (tag == 1) {
            addTime += duration
        } else if (tag == 2) {
            deleteTime += duration
        }
        if (elapsedTime - lastOutTime >= Duration.second * 5) {
            println("Elapsed time updated: ${elapsedTime}")
            lastOutTime = elapsedTime
        }
    }

    public func close(): Unit {
        logFile.flush()
        logFile.close()
        println("Elapsed time: ${elapsedTime}")
        println("Add time: ${addTime}")
        println("Delete time: ${deleteTime}")
        println("maxHeapSize: ${maxUsedHeapSize}")
        println("maxAllocatedHeapSize: ${maxAllocatedHeapSize}")
        println("gcCount: ${getGCCount() - gcStartCount}")
        println("gcTime: ${getGCTime() * Duration.microsecond - gcStartTime}")
        println("gcFreedSize: ${getGCFreedSize() - gcStartFreedSize}")
        closed = true
    }

    public func isClosed(): Bool {
        return closed
    }
}

public var LOGGER: ?Logger = None
