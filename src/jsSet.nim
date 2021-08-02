import jsffi

type
  JsSet*[T] {.nodecl, importc.} = ref object

proc newJsSet*[T](): JsSet[T] {.importjs: "new Set()".}
proc contains*[T](self: JsSet[T], item: T): bool {.importjs: "#.has(#)".}
proc incl*[T](self: JsSet[T], val: T): void {.importjs: "#.add(#)".}
proc clear*[T](self: JsSet[T]): void {.importjs: "#.clear()".}
proc len*[T](self: JsSet[T]): int {.importjs: "#.size".}

iterator items*[T](obj: JsSet[T]): T =
  var i: T
  {.emit: "for (const `item` of `obj`) {".}
  {.emit: "  `i`= `item`;".}
  yield i
  {.emit: "}".}
