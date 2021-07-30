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

proc render*(ctx: CanvasContext2d, primitive: Primitive, performance: performance.Performance): void =
  ctx.save()
  if primitive.opacity.isSome:
    ctx.globalAlpha = primitive.opacity.get

  perf.tick("translate")
  ctx.translate(primitive.bounds.x, primitive.bounds.y)
  perf.tock("translate")

  perf.tick("transform")
  for transform in  primitive.transform:
    case transform.kind:
      of Scaling:
        ctx.scale(
          transform.scale.x,
          transform.scale.y
        )
      of Translation:
        ctx.translate(transform.translation.x, transform.translation.y)
      of Rotation:
        ctx.rotate(transform.rotation)
  perf.tock("transform")
  if primitive.clipToBounds:
    ctx.beginPath()
    let cb = primitive.bounds
    ctx.rect(0.0, 0.0, cb.size.x, cb.size.y)
    ctx.clip()
  ctx.renderPrimitive(primitive)
  for p in primitive.children:
    ctx.render(p, performance)
  ctx.restore()
