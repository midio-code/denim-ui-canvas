import math
import sugar
import strformat
import options
import canvas
import denim_ui
import strutils
import tables
import dom
import performance
import caching
import drawing_primitives

proc render*(ctx: CanvasContext2d, primitive: Primitive): void =
  ctx.renderPrimitives(primitive)
