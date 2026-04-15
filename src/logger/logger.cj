package pcc_cangjie.logger

import pcc_cangjie.timing.GlobalTimer
import std.fs.{File, Path, Directory, removeIfExists, exists}
import std.collection.HashSet

public class Logger <: Resource {
    let logFile: File
    var closed = false

    private let linkSet = HashSet<String>()
    private var elapsedTime = Duration.Zero

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

    public func log(message: String): Unit {
        // let msg = "[${GlobalTimer.getOrThrow().now()}] ${message}\n"
        // logFile.write(msg.toArray())
        // print(msg)
        if (!message.isEmpty() && !linkSet.contains(message)) {
            logFile.write("${message}\n".toArray())
            println(message)
            linkSet.add(message)
        }
    }

    public func addDuration(duration: Duration): Unit {
        elapsedTime += duration
        println("Elapsed time updated: ${elapsedTime}")
    }

    public func close(): Unit {
        logFile.flush()
        logFile.close()
        closed = true
    }

    public func isClosed(): Bool {
        return closed
    }
}

public var LOGGER: ?Logger = None
