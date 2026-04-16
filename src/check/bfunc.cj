package pcc_cangjie.check

import std.reflect.{TypeInfo, StaticFunctionInfo}
import pcc_cangjie.defs.Context
import pcc_cangjie.user.UserBfunc

let contextInfo = TypeInfo.of<Context>()
let userBfuncInfo = TypeInfo.of<UserBfunc>()

func getBfuncInfo(name: String, paramNum: Int): StaticFunctionInfo {
    userBfuncInfo.getStaticFunction(name, Array(paramNum, repeat: contextInfo))
}

func applyBfunc(funcInfo: StaticFunctionInfo, args: Array<Context>): Bool {
    (funcInfo.apply(userBfuncInfo, args.map {x => x}) as Bool).getOrThrow() // On purpose, avoid binding Array to Any
}

func applyBfunc(name: String, args: Array<Context>): Bool {
    UserBfunc.taxiBfunc(name, args)
}
