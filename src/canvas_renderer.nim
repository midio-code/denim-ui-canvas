import math
import sugar
import jsffi
import strformat
import options
import canvas
import denim_ui
import strutils
import tables
import sets
import dom
import hashes
import jsSet
import jsMap
import performance
import caching

proc renderSegment*(ctx: CanvasContext2d, segment: PathSegment): void =
  case segment.kind
  of MoveTo:
    ctx.moveTo(segment.to.x, segment.to.y)
  of LineTo:
    ctx.lineTo(segment.to.x, segment.to.y)
  of QuadraticCurveTo:
    let info = segment.quadraticInfo
    ctx.quadraticCurveTo(info.controlPoint.x, info.controlPoint.y, info.point.x, info.point.y)
  of BezierCurveTo:
    let info = segment.bezierInfo
    ctx.bezierCurveTo(info.controlPoint1.x, info.controlPoint1.y, info.controlPoint2.x, info.controlPoint2.y, info.point.x, info.point.y)
  of PathSegmentKind.Close:
    ctx.closePath()

const px: cstring = "px "
const space: cstring = " "
proc renderText(ctx: CanvasContext2d, bounds: Bounds, colorInfo: Option[ColorInfo], textInfo: TextInfo): void =
  if colorInfo.isSome and colorInfo.get.fill.isSome:
    ctx.fillStyle = colorInfo.get.fill.get.toHexCStr
  ctx.textAlign = textInfo.alignment
  ctx.textBaseline = textInfo.textBaseline
  ctx.font = textInfo.fontWeight.toJs.toString().to(cstring) & space & textInfo.fontStyle & space & textInfo.fontSize.toJs.toString().to(cstring) & px & textInfo.fontFamily

  # We want to render the text in the middle of the line, when line height != 1.0
  let yRenderOffset = (bounds.size.y - textInfo.textSize.y) / 2.0

  when defined(draw_boxes_around_text):
    ctx.save()
    ctx.strokeStyle = "#ff0000"
    ctx.lineWidth = 1.0
    ctx.strokeRect(0.0, 0.0, bounds.size.x, bounds.size.y)
    ctx.restore()

  ctx.fillText(textInfo.text, 0.0, yRenderOffset)

proc renderCircle*(ctx: CanvasContext2d, radius: float): void =
  ctx.beginPath()
  ctx.arc(radius, radius, radius, 0, 2 * PI)

proc renderEllipse*(ctx: CanvasContext2d, info: EllipseInfo): void =
  ctx.beginPath()
  let
    r = info.radius
  ctx.ellipse(0.0, 0.0, r.x, r.y, info.rotation, info.startAngle, info.endAngle)

proc renderImage*(ctx: CanvasContext2d, bounds: Bounds, info: ImageInfo): void =
  let image = newImage()
  image.src = info.uri
  ctx.drawImage(image, bounds.pos.x, bounds.pos.y, bounds.size.x, bounds.size.y)

proc setShadow(ctx: CanvasContext2d, shadow: Option[Shadow]): void =
  if shadow.isSome:
    let s = shadow.get
    ctx.shadowBlur = s.size
    let
      r = s.color.r
      g = s.color.g
      b = s.color.b
      a = s.color.a
    ctx.setShadowColor(float(r),float(g),float(b),float(a) / 255.0)
    ctx.shadowOffsetX = s.offset.x
    ctx.shadowOffsetY = s.offset.y

const square = cstring("square")
const butt = cstring("butt")
const round = cstring("round")

const miter = cstring("miter")
const bevel = cstring("bevel")

# TODO: Cleanup this signature, stuff has just been tacked on when neeeded
proc fillAndStroke(ctx: CanvasContext2d, colorInfo: Option[ColorInfo], strokeInfo: Option[StrokeInfo], shadow: Option[Shadow], path: Option[Path2D] = none[Path2D]()): void =
  if strokeInfo.isSome():
    let si = strokeInfo.get
    ctx.lineWidth = si.width
    if si.lineDash.isSome:
      ctx.setLineDash(si.lineDash.get)
    if si.lineCap.isSome:
      let lineCapValue = case si.lineCap.get:
        of LineCap.Square:
          square
        of LineCap.Butt:
          butt
        of LineCap.Round:
          round
      ctx.lineCap = lineCapValue
    if si.lineJoin.isSome:
      let lineJoinValue = case si.lineJoin.get:
        of LineJoin.Miter:
          miter
        of LineJoin.Bevel:
          bevel
        of LineJoin.Round:
          round
      ctx.lineJoin = lineJoinValue
  else:
    ctx.lineWidth = 0.0

  if colorInfo.isSome():
    let ci = colorInfo.get()
    if ci.fill.isSome():
      ctx.save()
      ctx.setShadow(shadow)
      let fill = ci.fill.get
      case fill.kind:
        of ColorStyleKind.Solid:
          ctx.fillStyle = fill.toHexCStr
        of ColorStyleKind.Gradient:
          let stops = fill.gradient.stops
          let gradient = case fill.gradient.kind:
            of GradientKind.Linear:
              let info = fill.gradient.linearInfo
              ctx.createLinearGradient(info.startPoint.x, info.startPoint.x, info.endPoint.x, info.endPoint.y)
            of GradientKind.Radial:
              let info = fill.gradient.radialInfo
              ctx.createRadialGradient(
                info.startCircle.center.x,
                info.startCircle.center.y,
                info.startCircle.radius,
                info.endCircle.center.x,
                info.endCircle.center.y,
                info.endCircle.radius
              )
          for stop in stops:
            gradient.addColorStop(stop.position, stop.color.toHexCStr)
          ctx.setFillStyle(gradient)
      if path.isSome:
        let p = path.get
        ctx.fill(p)
      else:
        ctx.fill()
      ctx.restore()
    if ci.stroke.isSome() and strokeInfo.isSome and strokeInfo.get.width > 0.0:
      ctx.save()
      if ci.fill.isNone:
        # NOTE: We only apply shadow to the stroke if we haven't already applied it to.
        # This avoids shadows inside stroked shapes.
        ctx.setShadow(shadow)
      ctx.strokeStyle = ci.stroke.get.toHexCStr
      if path.isSome:
        let p = path.get
        ctx.stroke(p)
      else:
        ctx.stroke()
      ctx.restore()

proc renderPath*(ctx: CanvasContext2d, segments: seq[PathSegment]): void =
  ctx.beginPath()
  for segment in segments:
    renderSegment(ctx, segment)

proc renderPath*(ctx: CanvasContext2d, data: string): void =
  ctx.stroke(newPath2D(data))

proc renderRectWithRadius*(ctx: CanvasContext2d, bounds: Bounds, radius: CornerRadius): void =
  let
    w = bounds.size.x
    h = bounds.size.y

  ctx.beginPath()

  ctx.moveTo(radius.topLeft, 0.0)

  ctx.lineTo(w - radius.topRight, 0.0)
  ctx.quadraticCurveTo(w, 0.0, w, radius.topRight)

  ctx.lineTo(w, h - radius.bottomRight)
  ctx.quadraticCurveTo(w, h, w - radius.bottomRight, h)

  ctx.lineTo(radius.bottomLeft, h)
  ctx.quadraticCurveTo(0.0, h, 0.0, h - radius.bottomLeft)

  ctx.lineTo(0.0, radius.topLeft)
  ctx.quadraticCurveTo(0.0, 0.0, radius.topLeft, 0.0)

  ctx.closePath()

proc renderPrimitive*(ctx: CanvasContext2d, p: Primitive): void =
  case p.kind
  of PrimitiveKind.Container:
    discard
  of PrimitiveKind.Path:
    perf.tick("path")
    case p.pathInfo.kind:
      of PathInfoKind.Segments:
        ctx.renderPath(p.pathInfo.segments)
        fillAndStroke(ctx, p.colorInfo, p.strokeInfo, p.shadow)
      of PathInfoKind.String:
        fillAndStroke(ctx, p.colorInfo, p.strokeInfo, p.shadow, newPath2D(p.pathInfo.data))
    perf.tock("path")
  of PrimitiveKind.Text:
    perf.tick("text")
    renderText(ctx, p.bounds, p.colorInfo, p.textInfo)
    perf.tock("text")
  of PrimitiveKind.Circle:
    perf.tick("circle")
    let info = p.circleInfo
    renderCircle(ctx, info.radius)
    fillAndStroke(ctx, p.colorInfo, p.strokeInfo, p.shadow)
    perf.tock("circle")
  of PrimitiveKind.Ellipse:
    perf.tick("ellipse")
    let info = p.ellipseInfo
    renderEllipse(ctx, info)
    fillAndStroke(ctx, p.colorInfo, p.strokeInfo, p.shadow)
    perf.tock("ellipse")
  of PrimitiveKind.Image:
    perf.tick("image")
    let info = p.imageInfo
    ctx.renderImage(p.bounds, info)
    perf.tock("image")
  of PrimitiveKind.Rectangle:
    perf.tick("rectangle")
    let info = p.rectangleInfo
    let bounds = p.bounds
    ctx.beginPath()
    if info.radius == (0.0, 0.0, 0.0, 0.0):
      ctx.rect(0.0, 0.0, bounds.size.x, bounds.size.y)
    else:
      ctx.renderRectWithRadius(bounds, info.radius.get)
    fillAndStroke(ctx, p.colorInfo, p.strokeInfo, p.shadow)
    perf.tock("rectangle")



var primitivesSeenThisFrame = newJsSet[Hash]()
var counters = newJsMap[Hash, int]()


proc registerPrimitiveCurrentFrame(p: Primitive) =
  primitivesSeenThisFrame.incl(p.id)

proc seenPastNumberOfFrames(p: Primitive): int =
  ## Returns how many of the past frames this primitive has been seen
  counters[p.id]

proc endFrame(): void =
  for hash in primitivesSeenThisFrame:
    if hash notin counters:
      counters[hash] = 0
    counters[hash] = counters[hash] + 1

  var toRemove: seq[Hash] = @[]
  for k,v in counters:
    if k notin primitivesSeenThisFrame:
      toRemove.add(k)
  primitivesSeenThisFrame.clear()
  for remove in toRemove:
    counters.delete(remove)

const cacheWhenPrimitiveHasExistedForNFrames = 4

proc renderPrimitives*(ctx: CanvasContext2d, primitive: Primitive, isCaching: bool = false): void =

  ctx.save()

  if not isCaching and primitive.isCached:
    ctx.translate(primitive.bounds.x, primitive.bounds.y)
    perf.count("Draw from cache")
    ctx.drawFromCache(primitive)
  else:
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

    ctx.translate(primitive.bounds.x, primitive.bounds.y)

    if primitive.opacity.isSome:
      ctx.globalAlpha = primitive.opacity.get

    if primitive.clipToBounds:
      ctx.beginPath()
      let cb = primitive.bounds
      ctx.rect(0.0, 0.0, cb.size.x, cb.size.y)
      ctx.clip()

    if isCaching:
      perf.count("Caching")
    else:
      perf.count("Uncached")

    let seenEnoughTimesToCache = seenPastNumberOfFrames(primitive) >= cacheWhenPrimitiveHasExistedForNFrames
    if not isCaching and primitive.cache and seenEnoughTimesToCache:
      let cacheCtx = getCacheContextForPrimitive(primitive)
      perf.count("Caching")
      cacheCtx.renderPrimitive(primitive)
      for p in primitive.children:
        cacheCtx.renderPrimitives(p, true)
      ctx.drawFromCache(primitive)
    else:
      ctx.renderPrimitive(primitive)
      for p in primitive.children:
        ctx.renderPrimitives(p, isCaching)
  ctx.restore()
  registerPrimitiveCurrentFrame(primitive)

proc render*(ctx: CanvasContext2d, primitive: Primitive): void =
  ctx.renderPrimitives(primitive)
  endFrame()
