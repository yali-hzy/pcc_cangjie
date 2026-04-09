package pcc_cangjie.user

import pcc_cangjie.defs.Context

public class UserBfunc {
    static let Ttrans = Duration.minute * 5
    public static func WithinTrans(ctx1: Context, ctx2: Context): Bool {
        return ctx1.timestamp - ctx2.timestamp <= Ttrans
    }
}
