package pcc_cangjie.defs

import std.math.abs

class Point {
    Point(public let latitude: Float64, public let longitude: Float64) {}
}

func inHotArea(hotArea: String, longitude: Float64, latitude: Float64): Bool {
    if (DEBUG) {
        println("Checking if point (${latitude}, ${longitude}) is in hot area ${hotArea}")
    }
    match (hotArea) {
        case "A" => return inHotAreaA(Point(latitude, longitude))
        case "B" => return inHotAreaB(Point(latitude, longitude))
        case "C" => return inHotAreaC(Point(latitude, longitude))
        case "D" => return inHotAreaD(Point(latitude, longitude))
        case "E" => return inHotAreaE(Point(latitude, longitude))
        case "F" => return inHotAreaF(Point(latitude, longitude))
        case "G" => return inHotAreaG(Point(latitude, longitude))
        case "H" => return inHotAreaH(Point(latitude, longitude))
        case "I" => return inHotAreaI(Point(latitude, longitude))
        case _ => throw IllegalArgumentException("Unknown hot area: ${hotArea}")
    }
    return false
}

func inPolygon(point: Point, polygon: Array<Point>): Bool {
    var count = 0
    if (DEBUG) {
        println("Checking if point (${point.latitude}, ${point.longitude}) is in polygon with vertices:")
        for (p in polygon) {
            println("(${p.latitude}, ${p.longitude})")
        }
    }
    for (i in 0..polygon.size) {
        let p1 = polygon[i]
        let p2 = polygon[(i - 1 + polygon.size) % polygon.size]
        if (DEBUG) {
            println("Checking edge from (${p1.latitude}, ${p1.longitude}) to (${p2.latitude}, ${p2.longitude})")
        }
        if (((point.latitude >= p1.latitude) && (point.latitude < p2.latitude)) || ((point.latitude >= p2.latitude) && (point
            .latitude < p1.latitude))) {
            if (abs(p1.latitude - p2.latitude) > 0.0) {
                let y = p1.longitude - ((p1.longitude - p2.longitude) * (p1.latitude - point.latitude)) / (p1.latitude - p2
                    .latitude)
                if (DEBUG) {
                    println(
                        "Edge crossing at latitude: ${point.latitude} between points (${p1.latitude}, ${p1.longitude}) and (${p2.latitude}, ${p2.longitude}), crossing longitude: ${y}")
                    println("Edge crossing at longitude: ${y}")
                }
                if (y == point.longitude) {
                    if (DEBUG) {
                        println("true: Point is on the edge of the polygon")
                    }
                    return true
                }
                if (y < point.longitude) {
                    count++
                }
            }
        }
    }

    if (DEBUG) {
        println("Count of edge crossings: ${count}")
        if (count % 2 == 1) {
            println("true: Point is inside the polygon")
        } else {
            println("false: Point is outside the polygon")
        }
    }
    return count % 2 != 0
}

// [AA0]:22.571615,113.923059
// [AA1]:22.573121,113.864853
// [AA2]:22.590556,113.882534
// [AA3]:22.590873,113.901760
func inHotAreaA(point: Point): Bool {
    let points = [
        Point(22.571615, 113.923059),
        Point(22.573121, 113.864853),
        Point(22.590556, 113.882534),
        Point(22.590873, 113.901760)
    ]
    return inPolygon(point, points)
}

// [BB0]:22.548391,113.89455
// [BB1]:22.573121,113.864853
// [BB2]:22.590556,113.882534
// [BB3]:22.590873,113.90176
func inHotAreaB(point: Point): Bool {
    let points = [
        Point(22.548391, 113.89455),
        Point(22.573121, 113.864853),
        Point(22.590556, 113.882534),
        Point(22.590873, 113.90176)
    ]
    return inPolygon(point, points)
}

// [CC0]:22.571615,113.923059
// [CC1]:22.548391,113.89455
// [CC2]:22.573121,113.864853
// [CC3]:22.590556,113.882534
// [CC4]:22.590873,113.901761
func inHotAreaC(point: Point): Bool {
    let points = [
        Point(22.571615, 113.923059),
        Point(22.548391, 113.89455),
        Point(22.573121, 113.864853),
        Point(22.590556, 113.882534),
        Point(22.590873, 113.901761)
    ]
    return inPolygon(point, points)
}

// [DD0]:22.559489,114.02018
// [DD1]:22.570902,114.085411
// [DD2]:22.503359,114.060348
func inHotAreaD(point: Point): Bool {
    let points = [
        Point(22.559489, 114.02018),
        Point(22.570902, 114.085411),
        Point(22.503359, 114.060348)
    ]
    return inPolygon(point, points)
}

// [EE0]:22.559489,114.092304
// [EE1]:22.571853,114.142402
// [EE2]:22.541416,114.135879
// [EE3]:22.532457,114.08485
func inHotAreaE(point: Point): Bool {
    let points = [
        Point(22.559489, 114.092304),
        Point(22.571853, 114.142402),
        Point(22.541416, 114.135879),
        Point(22.532457, 114.08485)
    ]
    return inPolygon(point, points)
}

// [FF0]:22.559489,114.02018
// [FF1]:22.570902,114.085411
// [FF2]:22.571853,114.142402
// [FF3]:22.541416,114.135879
// [FF4]:22.503359,114.060348
func inHotAreaF(point: Point): Bool {
    let points = [
        Point(22.559489, 114.02018),
        Point(22.570902, 114.085411),
        Point(22.571853, 114.142402),
        Point(22.541416, 114.135879),
        Point(22.503359, 114.060348)
    ]
    return inPolygon(point, points)
}

// [GG0]:22.565195,113.927826
// [GG1]:22.55616,114.015056
// [GG2]:22.528414,114.019691
// [GG3]:22.514936,113.937809
// [GG4]:22.531744,113.902618
func inHotAreaG(point: Point): Bool {
    let points = [
        Point(22.565195, 113.927826),
        Point(22.55616, 114.015056),
        Point(22.528414, 114.019691),
        Point(22.514936, 113.937809),
        Point(22.531744, 113.902618)
    ]
    return inPolygon(point, points)
}

// [HH0]:22.565195,113.927826
// [HH1]:22.55616,114.015056
// [HH2]:22.611317,113.988792
func inHotAreaH(point: Point): Bool {
    let points = [
        Point(22.565195, 113.927826),
        Point(22.55616, 114.015056),
        Point(22.611317, 113.988792)
    ]
    return inPolygon(point, points)
}

func inHotAreaI(point: Point): Bool {
    return inHotAreaG(point)
}
