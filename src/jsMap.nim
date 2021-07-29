import jsffi

type
  JsMap*[TKey, TVal] {.nodecl, importc.} = ref object

proc newJsMap*[TKey, TVal](): JsMap[TKey, TVal] {.importjs: "new Map()".}
proc contains*[TKey, TVal](self: JsMap[TKey, TVal], item: TKey): bool {.importjs: "#.has(#)".}
proc get*[TKey, TVal](self: JsMap[TKey, TVal], key: TKey): TVal {.importjs: "#.get(#)".}
proc set*[TKey, TVal](self: JsMap[TKey, TVal], key: TKey, val: TVal): void {.importjs: "#.set(#, #)".}
proc len*[TKey, TVal](self: JsMap[Tkey, TVal]): int {.importjs: "#.size".}

iterator pairs*[TKey,TVal](obj: JsMap[TKey, TVal]): (TKey, TVal) =
  var k: TKey
  var v: TVal
  {.emit: "for (var `pair` of `obj`) {".}
  {.emit: "  `k`=`pair`[0];".}
  {.emit: "  `v`=`pair`[1];".}
  yield (k, v)
  {.emit: "}".}
