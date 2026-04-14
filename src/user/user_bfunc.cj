package pcc_cangjie.user

import pcc_cangjie.defs.Context
import std.math.abs

public class UserBfunc {
    static let Ttrans = Duration.minute * 5
    public static func WithinTrans(ctx1: Context, ctx2: Context): Bool {
        return ctx1.timestamp - ctx2.timestamp <= Ttrans
    }

    public static func same(ctx1: Context, ctx2: Context): Bool {
        return ctx1.subject == ctx2.subject
    }

    public static func sz_loc_range(ctx: Context): Bool {
        let longitude = ctx.longitude
        let latitude = ctx.latitude
        return !(longitude < 112.0) && !(longitude > 116.0) && !(latitude < 20.0) && !(latitude > 24.0)
    }

    public static func sz_loc_close(ctx1: Context, ctx2: Context): Bool {
        let lon1 = ctx1.longitude
        let lat1 = ctx1.latitude
        let lon2 = ctx2.longitude
        let lat2 = ctx2.latitude
        let distSqr = (lon1 - lon2) * (lon1 - lon2) + (lat1 - lat2) * (lat1 - lat2)
        return !(distSqr > 0.001 * 0.001)
    }

    public static func sz_spd_close(ctx1: Context, ctx2: Context): Bool {
        let spd1 = ctx1.speed
        let spd2 = ctx2.speed
        return abs(spd2 - spd1) <= 50.0
    }

    public static func sz_loc_dist(ctx1: Context, ctx2: Context): Bool {
        let lon1 = ctx1.longitude
        let lat1 = ctx1.latitude
        let lon2 = ctx2.longitude
        let lat2 = ctx2.latitude
        let distSqr = (lon1 - lon2) * (lon1 - lon2) + (lat1 - lat2) * (lat1 - lat2)
        return !(distSqr > 0.025 * 0.025)
    }
}
