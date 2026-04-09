package pcc_cangjie.timing

import std.time.{DateTime, MonoTime}

public class MockTimer {
    let systemStart: MonoTime

    public MockTimer(let mockStart: DateTime) {
        systemStart = MonoTime.now()
    }

    public func now(): DateTime {
        return mockStart + (MonoTime.now() - systemStart)
    }
}

public var GlobalTimer: ?MockTimer = None
