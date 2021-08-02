import sugar
import denim_ui
import dom

type
  Canvas* = ref CanvasObj
  CanvasObj {.importc.} = object of dom.Element
    width*: float
    height*: float


  CanvasContext2d* = ref CanvasContext2dObj
  CanvasContext2dObj {.importc.} = object
    fillStyle*: cstring
    textAlign*: cstring
    strokeStyle*: cstring
    lineWidth*: float
    lineCap*: cstring
    lineJoin*: cstring
    textBaseline*: cstring
    font*: cstring
    globalAlpha*: float

  TextMetrics {.importc.} = object
    width*: float
    actualBoundingBoxDescent*: float

  Gradient {.importc, nodecl.} = ref object

  Path2D* {.importjs.} = ref object

proc createCanvas*(): Canvas {.importjs: "document.createElement('canvas')".}

proc getContext2d*(c: Canvas, alpha: bool = false): CanvasContext2d {.importjs: "#.getContext('2d', @)"}

proc beginPath*(c: CanvasContext2d) {.importjs: "#.beginPath()".}
proc strokeText*(c: CanvasContext2d, txt: cstring, x, y: float) {.importjs: "#.strokeText(@)".}
proc fillText*(c: CanvasContext2d, txt: cstring, x, y: float) {.importjs: "#.fillText(@)".}
proc canvas_measureText*(c: CanvasContext2d, txt: cstring): TextMetrics {.importjs: "#.measureText(@)".}

proc rect*(c: CanvasContext2d, x: float, y: float, width: float, height: float) {.importjs: "#.rect(@)".}

proc stroke*(c: CanvasContext2d) {.importjs: "#.stroke()".}
proc stroke*(c: CanvasContext2d, path: Path2D) {.importjs: "#.stroke(@)".}
proc fill*(c: CanvasContext2d) {.importjs: "#.fill()".}
proc fill*(c: CanvasContext2d, path: Path2D) {.importjs: "#.fill(@)".}
proc clearRect*(c: CanvasContext2d, x: float, y: float, width: float, height: float) {.importjs: "#.clearRect(@)".}

proc moveTo*(c: CanvasContext2d, x: float, y: float) {.importjs: "#.moveTo(@)".}
proc lineTo*(c: CanvasContext2d, x: float, y: float) {.importjs: "#.lineTo(@)".}
proc arcTo*(c: CanvasContext2d, x1: float, y1: float, x2: float, y2: float, radius: float) {.importjs: "#.arcTo(@)".}
proc arc*(c: CanvasContext2d, x: float, y: float, radius: float, startAngle: float, endAngle: float, anticlockwise: bool = false) {.importjs: "#.arc(@)".}
proc closePath*(c: CanvasContext2d) {.importjs: "#.closePath()".}
proc quadraticCurveTo*(c: CanvasContext2d, cpx: float, cpy: float, x: float, y: float) {.importjs: "#.quadraticCurveTo(@)".}
proc bezierCurveTo*(c: CanvasContext2d, cp1x: float, cp1y: float, cp2x: float, cp2y: float, x: float, y: float) {.importjs: "#.bezierCurveTo(@)".}

proc ellipse*(c: CanvasContext2d, x, y, radiusX, radiusY, rotation, startAngle, endAngle: float, anticlockwise: bool = false) {.importjs: "#.ellipse(@)".}

proc fillRect*(c: CanvasContext2d, x: float, y: float, w: float, h: float) {.importjs: "#.fillRect(@)".}
proc strokeRect*(c: CanvasContext2d, x: float, y: float, w: float, h: float) {.importjs: "#.strokeRect(@)".}

proc clip*(c: CanvasContext2d) {.importjs: "#.clip()".}
proc save*(c: CanvasContext2d) {.importjs: "#.save()".}
proc restore*(c: CanvasContext2d) {.importjs: "#.restore()".}

proc setLineDash*(c: CanvasContext2d, pattern: seq[int]) {.importjs: "#.setLineDash(@)".}

type
  Image* {.importc.} = ref object
    src*: cstring

proc setSourceToBlob*(self: Image, blob: Blob): void {.importjs: "#.src = URL.createObjectURL(@)".}
proc newImage*(): Image {.importjs: "new Image()".}
proc newImage*(blob: Blob): Image =
  result = newImage()
  result.setSourceToBlob(blob)

proc drawImage*(ctx: CanvasContext2d, img: Image, sx, sy, sw, sh, dx, dy, dw, dh: float): void {.importjs: "#.drawImage(@)".}
proc drawImage*(ctx: CanvasContext2d, img: Image, sx, sy, sw, sh: float): void {.importjs: "#.drawImage(@)".}
proc drawImage*(ctx: CanvasContext2d, img: Image, dx, dy: float): void {.importjs: "#.drawImage(@)".}

proc drawImage*(ctx: CanvasContext2d, img: Canvas, sx, sy, sw, sh, dx, dy, dw, dh: float): void {.importjs: "#.drawImage(@)".}
proc drawImage*(ctx: CanvasContext2d, img: Canvas, dx, dy, dw, dh: float): void {.importjs: "#.drawImage(@)".}
proc drawImage*(ctx: CanvasContext2d, img: Canvas, dx, dy: float): void {.importjs: "#.drawImage(@)".}


proc transform*(
  c: CanvasContext2d,
  scaleX: float,
  skewX: float,
  scaleY: float,
  skewY: float,
  transX: float,
  transY: float
) {.importjs: "#.transform(@)".}

proc rotate*(c: CanvasContext2d, angle: float) {.importjs: "#.rotate(@)".}
proc scale*(c: CanvasContext2d, x: float, y: float) {.importjs: "#.scale(@)".}
proc translate*(c: CanvasContext2d, x: float, y: float) {.importjs: "#.translate(@)".}
proc setTransform*(ctx: CanvasContext2d, a,b,c,d,e,f: float) {.importjs: "#.setTransform(@)".}
proc resetTransform*(c: CanvasContext2d) {.importjs: "#.resetTransform()".}


proc `shadowBlur=`*(c: CanvasContext2d, value: float) {.importjs: "#.shadowBlur = #".}
proc shadowBlur*(c: CanvasContext2d): float {.importjs: "#.shadowBlur".}

proc setShadowColor*(c: CanvasContext2d, r,g,b,a: float) {.importjs: "#.shadowColor = `rgba($${#}, $${#}, $${#}, $${#})`".}

proc `shadowOffsetX=`*(c: CanvasContext2d, value: float) {.importjs: "#.shadowOffsetX = #".}
proc shadowOffsetX*(c: CanvasContext2d): float {.importjs: "#.shadowOffsetX".}

proc `shadowOffsetY=`*(c: CanvasContext2d, value: float) {.importjs: "#.shadowOffsetY = #".}
proc shadowOffsetY*(c: CanvasContext2d): float {.importjs: "#.shadowOffsetY".}


proc newPath2D*(): Path2D {.importjs: "new Path2D()".}
proc newPath2D*(data: cstring): Path2D {.importjs: "new Path2D(@)".}

proc isPointInPath*(c: CanvasContext2d, x, y: float): bool {.importjs: "#.isPointInPath(@)"}
proc isPointInPath*(c: CanvasContext2d, path: Path2D, x, y: float): bool {.importjs: "#.isPointInPath(@)"}
proc isPointInStroke*(c: CanvasContext2d, x, y: float): bool {.importjs: "#.isPointInStroke(@)"}
proc isPointInStroke*(c: CanvasContext2d, path: Path2D, x, y: float): bool {.importjs: "#.isPointInStroke(@)"}



proc createLinearGradient*(c: CanvasContext2d, x0, y0, x1, y1: float): Gradient {.importjs: "#.createLinearGradient(@)"}
proc createRadialGradient*(c: CanvasContext2d, x0, y0, r0, x1, y1, r1: float): Gradient {.importjs: "#.createRadialGradient(@)"}

proc addColorStop*(self: Gradient, pos: float, color: cstring): void {.importjs: "#.addColorStop(@)"}

proc setFillStyle*(self: CanvasContext2d, grad: Gradient): void {.importjs: "#.fillStyle = #".}


proc toBlob*(self: Canvas, callback: Blob -> void): void {.importjs: "#.toBlob(@)".}
