package pcc_cangjie.logger

import pcc_cangjie.timing.GlobalTimer
import std.fs.{File, Path, Directory, removeIfExists, exists}

public class Logger <: Resource {
    let logFile: File
    var closed = false

    public init(dir: String, fileName: String) {
        let logDir = Path(dir)
        let logFilePath = logDir.join(fileName)
        if (!exists(logDir)) {
            Directory.create(logDir, recursive: true)
        }
        removeIfExists(logFilePath)
        logFile = File.create(logFilePath)
    }

    public func log(message: String): Unit {
        let msg = "[${GlobalTimer.getOrThrow().now()}] ${message}\n"
        logFile.write(msg.toArray())
        print(msg)
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
