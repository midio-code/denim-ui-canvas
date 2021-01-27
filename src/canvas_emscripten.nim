import sugar
import denim_ui

{.compile: "html5.h"}

type
  Canvas* {.importc:"HTMLCanvasElement*".} = ref object
    getContext* {.importc.}: proc(self: Canvas, contextType: cstring): CanvasContext2d
    setWidth* {.importc.}: proc(self: Canvas, width: int): void
    getWidth* {.importc.}: proc(self: Canvas): int
    setHeight* {.importc.}: proc(self: Canvas, height: int): void
    getHeight* {.importc.}: proc(self: Canvas): int

  CanvasContext2d* {.importc: "CanvasRenderingContext2D*".} = ref object
    clearRect {.importc.}: proc(this: CanvasContext2d, x: cdouble, y: cdouble, width: cdouble, height: cdouble): void
    fillRect {.importc.}: proc(this: CanvasContext2d, x: cdouble, y: cdouble, width: cdouble, height: cdouble): void
    strokeRect {.importc.}: proc(this: CanvasContext2d, x: cdouble, y: cdouble, width: cdouble, height: cdouble): void
    fillText {.importc.}: proc(this: CanvasContext2d, text: cstring, x: cdouble, y: cdouble, maxWidth: cdouble): void
    strokeText {.importc.}: proc(this: CanvasContext2d, text: cstring, x: cdouble, y: cdouble, maxWidth: cdouble): void
    setLineWidth {.importc.}: proc(this: CanvasContext2d, value: cdouble): void
    getLineWidth {.importc.}: proc(this: CanvasContext2d): cdouble
    setLineCap {.importc.}: proc(this: CanvasContext2d, `type`: cstring): void
    getLineCap {.importc.}: proc(this: CanvasContext2d): cstring
    setLineJoin {.importc.}: proc(this: CanvasContext2d, `type`: cstring): void
    getLineJoin {.importc.}: proc(this: CanvasContext2d): cstring
    getFont {.importc.}: proc(this: CanvasContext2d): cstring
    setFont {.importc.}: proc(this: CanvasContext2d, value: cstring): void
    setTextAlign {.importc.}: proc(this: CanvasContext2d, value: cstring): void
    getTextAlign {.importc.}: proc(this: CanvasContext2d): cstring
    setFillStyle {.importc.}: proc(this: CanvasContext2d, value: cstring): void
    getFillStyle {.importc.}: proc(this: CanvasContext2d): cstring
    setStrokeStyle {.importc.}: proc(this: CanvasContext2d, value: cstring): void
    getStrokeStyle {.importc.}: proc(this: CanvasContext2d): cstring
    beginPath {.importc.}: proc(this: CanvasContext2d): void
    closePath {.importc.}: proc(this: CanvasContext2d): void
    moveTo {.importc.}: proc(this: CanvasContext2d, x: cdouble, y: cdouble): void
    lineTo {.importc.}: proc(this: CanvasContext2d, x: cdouble, y: cdouble): void
    bezierCurveTo {.importc.}: proc(this: CanvasContext2d, cp1x: cdouble, cp1y: cdouble, cp2x: cdouble, cp2y: cdouble, x, y: cdouble): void
    quadraticCurveTo {.importc.}: proc(this: CanvasContext2d, cpx: cdouble, cpy: cdouble, x: cdouble, y: cdouble): void
    arc {.importc.}: proc(this: CanvasContext2d, x: cdouble, y: cdouble, radius: cdouble, startAngle: cdouble, endAngle: cdouble): void
    arcTo {.importc.}: proc(this: CanvasContext2d, x1: cdouble, y1: cdouble, x2: cdouble, y2: cdouble, radius: cdouble): void
    ellipse {.importc.}: proc(this: CanvasContext2d, x: cdouble, y: cdouble, radiusX: cdouble, radiusY: cdouble, rotation: cdouble, startAngle: cdouble, endAngle: cdouble): void
    rect {.importc.}: proc(this: CanvasContext2d, x: cdouble, y: cdouble, width: cdouble, height: cdouble): void
    fill {.importc.}: proc(this: CanvasContext2d): void
    stroke {.importc.}: proc(this: CanvasContext2d): void
    clip {.importc.}: proc(this: CanvasContext2d): void
    isPointInPath {.importc.}: proc(this: CanvasContext2d, x: cdouble, y: cdouble): cint
    isPointInStroke {.importc.}: proc(this: CanvasContext2d, x: cdouble, y: cdouble): cint
    rotate {.importc.}: proc(this: CanvasContext2d, angle: cdouble): void
    scale {.importc.}: proc(this: CanvasContext2d, x: cdouble, y: cdouble): void
    translate {.importc.}: proc(this: CanvasContext2d, x: cdouble, y: cdouble): void
    transform {.importc.}: proc(this: CanvasContext2d, a: cdouble, b: cdouble, c: cdouble, d: cdouble, e: cdouble, f: cdouble): void
    setTransform {.importc.}: proc(this: CanvasContext2d, a: cdouble, b: cdouble, c: cdouble, d: cdouble, e: cdouble, f: cdouble): void
    resetTransform {.importc.}: proc(this: CanvasContext2d): void
    setGlobalAlpha {.importc.}: proc(this: CanvasContext2d, value: cdouble): void
    getGlobalAlpha {.importc.}: proc(this: CanvasContext2d): cdouble
    setGlobalCompositeOperation {.importc.}: proc(this: CanvasContext2d, value: cstring): void
    getGlobalCompositeOperation {.importc.}: proc(this: CanvasContext2d): cstring
    save {.importc.}: proc(this: CanvasContext2d): void
    restore {.importc.}: proc(this: CanvasContext2d): void

  TextMetrics {.importc.} = object
    width*: float

  Path2D* {.importc.} = ref object

proc `width=`*(self: Canvas, val: int): void =
    self.setWidth(self, val)

proc width*(self: Canvas): int =
    self.getWidth(self)

proc `height=`*(self: Canvas, val: int): void =
    self.setHeight(self, val)

proc height*(self: Canvas): int =
    self.getHeight(self)

proc createCanvas*(id: cstring): Canvas {.importc.}

proc getContext*(self: Canvas): CanvasContext2d {.importc.}
proc getContext2d*(c: Canvas): CanvasContext2d =
  c.getContext(c, "2d")


proc `fillStyle=`*(self: CanvasContext2d, val: cstring): void {.importc: "setFillStyle".}
proc fillStyle*(self: CanvasContext2d): cstring {.importc: "getFillStyle".}

proc `textAlign=`*(self: CanvasContext2d, val: cstring): void {.importc: "setTextAlign".}
proc textAlign*(self: CanvasContext2d): cstring {.importc: "getTextAlign".}

proc `strokeStyle=`*(self: CanvasContext2d, val: cstring): void {.importc: "setStrokeStyle".}
proc strokeStyle*(self: CanvasContext2d): cstring {.importc: "getStrokeStyle".}

proc `lineWidth=`*(self: CanvasContext2d, val: float): void {.importc: "setLineWidth".}
proc lineWidth*(self: CanvasContext2d): float {.importc: "getLineWidth".}

proc `textBaseline=`*(self: CanvasContext2d, val: cstring): void {.importc: "setTextBaseline".}
proc textBaseline*(self: CanvasContext2d): cstring {.importc: "getTextBaseline".}


proc `font=`*(self: CanvasContext2d, val: cstring): void {.importc: "setFont".}
proc font*(self: CanvasContext2d): cstring {.importc: "getFont".}

proc clearRect*(this: CanvasContext2d, x: float, y: float, width: float, height: float): void = this.clearRect(this,x,y,width,height)
proc fillRect*(this: CanvasContext2d, x: float, y: float, width: float, height: float): void = this.fillRect(this,x,y,width,height)
proc strokeRect*(this: CanvasContext2d, x: float, y: float, width: float, height: float): void = this.strokeRect(this,x,y,width,height)
proc fillText*(this: CanvasContext2d, text: cstring, x: float, y: float, maxWidth: float = 1000.0): void = this.fillText(this,text,x,y,maxWidth)
proc strokeText*(this: CanvasContext2d, text: cstring, x: float, y: float, maxWidth: float): void = this.strokeText(this,text,x,y,maxWidth)
proc setLineWidth*(this: CanvasContext2d, value: float): void = this.setLineWidth(this, value)
proc getLineWidth*(this: CanvasContext2d): float = this.getLineWidth(this)
proc setLineCap*(this: CanvasContext2d, `type`: cstring): void = this.setLineCap(this, `type`)
proc getLineCap*(this: CanvasContext2d): cstring = this.getLineCap(this)
proc setLineJoin*(this: CanvasContext2d, `type`: cstring): void = this.setLineJoin(this, `type`)
proc getLineJoin*(this: CanvasContext2d): cstring = this.getLineJoin(this)
proc getFont*(this: CanvasContext2d): cstring = this.getFont(this)
proc setFont*(this: CanvasContext2d, value: cstring): void = this.setFont(this, value)
proc setTextAlign*(this: CanvasContext2d, value: cstring): void = this.setTextAlign(this, value)
proc getTextAlign*(this: CanvasContext2d): cstring = this.getTextAlign(this)
proc setFillStyle*(this: CanvasContext2d, value: cstring): void = this.setFillStyle(this, value)
proc getFillStyle*(this: CanvasContext2d): cstring = this.getFillStyle(this)
proc setStrokeStyle*(this: CanvasContext2d, value: cstring): void = this.setStrokeStyle(this, value)
proc getStrokeStyle*(this: CanvasContext2d): cstring = this.getStrokeStyle(this)
proc beginPath*(this: CanvasContext2d): void = this.beginPath(this)
proc closePath*(this: CanvasContext2d): void = this.closePath(this)
proc moveTo*(this: CanvasContext2d, x: float, y: float): void = this.moveTo(this, x, y)
proc lineTo*(this: CanvasContext2d, x: float, y: float): void = this.lineTo(this, x, y)
proc bezierCurveTo*(this: CanvasContext2d, cp1x: float, cp1y: float, cp2x: float, cp2y: float, x, y: float): void = this.bezierCurveTo(this, cp1x, cp1y, cp2x, cp2y, x, y)
proc quadraticCurveTo*(this: CanvasContext2d, cpx: float, cpy: float, x: float, y: float): void = this.quadraticCurveTo(this, cpx, cpy, x, y)
proc arc*(this: CanvasContext2d, x: float, y: float, radius: float, startAngle: float, endAngle: float): void = this.arc(this, x, y, radius, startAngle, endAngle)
proc arcTo*(this: CanvasContext2d, x1: float, y1: float, x2: float, y2: float, radius: float): void = this.arcTo(this, x1, y1, x2, y2, radius)
proc ellipse*(this: CanvasContext2d, x: float, y: float, radiusX: float, radiusY: float, rotation: float, startAngle: float, endAngle: float): void = this.ellipse(this, x, y, radiusX, radiusY, rotation, startAngle, endAngle)
proc rect*(this: CanvasContext2d, x: float, y: float, width: float, height: float): void = this.rect(this,x,y,width,height)
proc fill*(this: CanvasContext2d): void = this.fill(this)
proc stroke*(this: CanvasContext2d): void = this.stroke(this)
proc clip*(this: CanvasContext2d): void = this.clip(this)
proc isPointInPath*(this: CanvasContext2d, x: float, y: float): bool = this.isPointInPath(this, x, y) != 0
proc isPointInStroke*(this: CanvasContext2d, x: float, y: float): bool = this.isPointInStroke(this,x,y) != 0
proc rotate*(this: CanvasContext2d, angle: float): void = this.rotate(this, angle)
proc scale*(this: CanvasContext2d, x: float, y: float): void = this.scale(this,x,y)
proc translate*(this: CanvasContext2d, x: float, y: float): void = this.translate(this,x,y)
proc transform*(this: CanvasContext2d, a: float, b: float, c: float, d: float, e: float, f: float): void = this.transform(this, a, b, c, d, e, f)
proc setTransform*(this: CanvasContext2d, a: float, b: float, c: float, d: float, e: float, f: float): void = this.setTransform(this, a,b,c,d,e,f)
proc resetTransform*(this: CanvasContext2d): void = this.resetTransform(this)
proc setGlobalAlpha*(this: CanvasContext2d, value: float): void = this.setGlobalAlpha(this, value)
proc getGlobalAlpha*(this: CanvasContext2d): float = this.getGlobalAlpha(this)
proc setGlobalCompositeOperation*(this: CanvasContext2d, value: cstring): void = this.setGlobalCompositeOperation(this, value)
proc getGlobalCompositeOperation*(this: CanvasContext2d): cstring = this.getGlobalCompositeOperation(this)
proc save*(this: CanvasContext2d): void = this.save(this)
proc restore*(this: CanvasContext2d): void = this.restore(this)


proc transform*(
  c: CanvasContext2d,
  scaleX: float,
  skewX: float,
  scaleY: float,
  skewY: float,
  transX: float,
  transY: float
) {.importc.}


proc newPath2D*(): Path2D {.importc.}
proc newPath2D*(data: cstring): Path2D {.importc.}
