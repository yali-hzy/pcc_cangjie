package pcc_cangjie.parse

import std.collection.ArrayList
import std.time.DateTime
import std.convert.Parsable
import pcc_cangjie.defs.Lifespan

public func parseDateTimeFromTimeStamp(timestamp: Int64): DateTime {
    return DateTime.fromUnixTimeStamp(timestamp * Duration.second)
}

public func parseDateTimeFromTimeStamp(timestampStr: String): DateTime {
    return parseDateTimeFromTimeStamp(Int64.parse(timestampStr))
}

public func parseDateTimeFromStr(dateTimeStr: String): DateTime {
    return DateTime.parse(dateTimeStr, "yyyy-MM-dd HH:mm:ss:S")
}

public func parseLifespan(lifespanStr: String): Lifespan {
    let parts = lifespanStr.split(" ", removeEmpty: true)
    let timeStrs = ArrayList<String>()
    for (part in parts) {
        if (Rune(part[0]) >= r'0' && Rune(part[0]) <= r'9') {
            timeStrs.add(part)
        }
    }
    let lifespanParts = timeStrs.toArray().map {str => parseDateTimeFromTimeStamp(str)}
    if (lifespanParts.size == 1) {
        return Lifespan.Moment(lifespanParts[0])
    } else if (lifespanParts.size == 2) {
        return Lifespan.Period(lifespanParts[0], lifespanParts[1])
    } else {
        throw Exception("Invalid lifespan format: ${lifespanStr}")
    }
}
