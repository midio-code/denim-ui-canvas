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
    textBaseline*: cstring
    font*: cstring

  TextMetrics {.importc.} = object
    width*: float

proc getContext2d*(c: Canvas): CanvasContext2d =
  {.emit: "`result` = `c`.getContext('2d');".}

proc beginPath*(c: CanvasContext2d) {.importjs: "#.beginPath()".}
proc strokeText*(c: CanvasContext2d, txt: cstring, x, y: float) {.importjs: "#.strokeText(@)".}
proc fillText*(c: CanvasContext2d, txt: cstring, x, y: float) {.importjs: "#.fillText(@)".}
proc canvas_measureText*(c: CanvasContext2d, txt: cstring): TextMetrics {.importjs: "#.measureText(@)".}

proc rect*(c: CanvasContext2d, x: float, y: float, width: float, height: float) {.importjs: "#.rect(@)".}

proc stroke*(c: CanvasContext2d) {.importjs: "#.stroke()".}
proc fill*(c: CanvasContext2d) {.importjs: "#.fill()".}
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
proc resetTransform*(c: CanvasContext2d) {.importjs: "#.resetTransform()".}


proc `shadowBlur=`*(c: CanvasContext2d, value: float) {.importjs: "#.shadowBlur = #".}
proc shadowBlur*(c: CanvasContext2d): float {.importjs: "#.shadowBlur".}

proc setShadowColor*(c: CanvasContext2d, r,g,b,a: float) {.importjs: "#.shadowColor = `rgba($${#}, $${#}, $${#}, $${#})`".}

proc `shadowOffsetX=`*(c: CanvasContext2d, value: float) {.importjs: "#.shadowOffsetX = #".}
proc shadowOffsetX*(c: CanvasContext2d): float {.importjs: "#.shadowOffsetX".}

proc `shadowOffsetY=`*(c: CanvasContext2d, value: float) {.importjs: "#.shadowOffsetY = #".}
proc shadowOffsetY*(c: CanvasContext2d): float {.importjs: "#.shadowOffsetY".}


type
  Path2D* {.importjs.} = object

proc newPath2D*(): Path2D {.importjs: "new Path2D()".}

proc isPointInPath*(c: CanvasContext2d, x, y: float): bool {.importjs: "#.isPointInPath(@)"}
proc isPointInPath*(c: CanvasContext2d, path: Path2D, x, y: float): bool {.importjs: "#.isPointInPath(@)"}
proc isPointInStroke*(c: CanvasContext2d, x, y: float): bool {.importjs: "#.isPointInStroke(@)"}
proc isPointInStroke*(c: CanvasContext2d, path: Path2D, x, y: float): bool {.importjs: "#.isPointInStroke(@)"}
