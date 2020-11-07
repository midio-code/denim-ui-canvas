import math
import sugar
import options
import canvas
import midio_ui

proc renderSegment(ctx: CanvasContext2d, segment: PathSegment): void =
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
  of Close:
    ctx.closePath()

proc renderText(ctx: CanvasContext2d, colorInfo: Option[ColorInfo], textInfo: TextInfo): void =
  ctx.fillStyle = colorInfo.map(x => x.fill.get("red")).get("brown")
  ctx.textAlign = textInfo.alignment
  ctx.textBaseline = textInfo.textBaseline
  ctx.font = $textInfo.fontSize & "px " & textInfo.font
  ctx.fillText(textInfo.text, 0.0, 0.0)

proc renderCircle(ctx: CanvasContext2d, radius: float): void =
  ctx.beginPath()
  ctx.arc(radius, radius, radius, 0, 2 * PI)

proc renderEllipse(ctx: CanvasContext2d, info: EllipseInfo): void =
  ctx.beginPath()
  let
    r = info.radius
  ctx.ellipse(0.0, 0.0, r.x, r.y, info.rotation, info.startAngle, info.endAngle)

proc fillAndStroke(ctx: CanvasContext2d, colorInfo: Option[ColorInfo], strokeInfo: Option[StrokeInfo]): void =
  if strokeInfo.isSome():
    ctx.lineWidth = strokeInfo.get().width
  else:
    ctx.lineWidth = 0.0
  if colorInfo.isSome():
    let ci = colorInfo.get()
    if ci.fill.isSome():
      ctx.fillStyle = ci.fill.get()
      ctx.fill()
    if ci.stroke.isSome() and strokeInfo.map(x => x.width).get(0.0) > 0.0:
      ctx.strokeStyle = ci.stroke.get()
      ctx.stroke()

proc renderPath*(ctx: CanvasContext2d, segments: seq[PathSegment]): void =
  ctx.beginPath()
  for segment in segments:
    renderSegment(ctx, segment)

proc renderPrimitive(ctx: CanvasContext2d, p: Primitive): void =
  case p.kind
  of PrimitiveKind.Container:
    discard
  of PrimitiveKind.Path:
    ctx.renderPath(p.segments)
    fillAndStroke(ctx, p.colorInfo, p.strokeInfo)
  of PrimitiveKind.Text:
    renderText(ctx, p.colorInfo, p.textInfo)
  of PrimitiveKind.Circle:
    let info = p.circleInfo
    renderCircle(ctx, info.radius)
    fillAndStroke(ctx, p.colorInfo, p.strokeInfo)
  of PrimitiveKind.Ellipse:
    let info = p.ellipseInfo
    renderEllipse(ctx, info)
    fillAndStroke(ctx, p.colorInfo, p.strokeInfo)
  of PrimitiveKind.Rectangle:
    let info = p.rectangleInfo
    ctx.beginPath()
    ctx.rect(info.bounds.pos.x, info.bounds.pos.y, info.bounds.size.x, info.bounds.size.y)
    fillAndStroke(ctx, p.colorInfo, p.strokeInfo)

proc render*(ctx: CanvasContext2d, primitive: Primitive): void =
  proc renderInner(primitive: Primitive): void =
    ctx.save()

    ctx.translate(primitive.bounds.x, primitive.bounds.y)
    if primitive.transform.isSome():
      let transform = primitive.transform.get()
      let size = primitive.bounds.size
      let xPos = size.x / 2.0
      let yPos = size.y / 2.0
      ctx.translate(xPos, yPos)
      ctx.rotate(transform.rotation)
      ctx.translate(-xPos, -yPos)
      ctx.translate(
        transform.translation.x,
        transform.translation.y
      )
      ctx.scale(
        transform.scale.x,
        transform.scale.y
      )
    if primitive.clipToBounds:
      ctx.beginPath()
      let cb = primitive.bounds
      ctx.rect(0.0, 0.0, cb.size.x, cb.size.y)
      ctx.clip()
    ctx.renderPrimitive(primitive)
    for p in primitive.children:
      renderInner(p)
    ctx.restore()

  renderInner(primitive)
