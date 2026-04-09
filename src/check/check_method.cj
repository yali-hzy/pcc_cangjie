package pcc_cangjie.check

import pcc_cangjie.defs.Context
import std.collection.ArrayList

interface CheckMethod {
    func handleAdd(cct: Cct, nodeList: ArrayList<Int>, contextId: Int, context: Context): Unit
    func handleDelete(cct: Cct, nodeList: ArrayList<Int>, contextId: Int): Unit
}
