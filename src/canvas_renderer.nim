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
    ctx.quadraticCurveTo(segment.controlPoint.x, segment.controlPoint.y, segment.point.x, segment.point.y)
  of Close:
    ctx.closePath()

proc renderText(ctx: CanvasContext2d, colorInfo: Option[ColorInfo], textInfo: TextInfo): void =
  ctx.fillStyle = colorInfo.map(x => x.fill.get("red")).get("brown")
  ctx.textAlign = textInfo.alignment
  ctx.textBaseline = textInfo.textBaseline
  ctx.font = $textInfo.fontSize & "px " & textInfo.font
  ctx.fillText(textInfo.text, textInfo.pos.x, textInfo.pos.y)

proc renderCircle(ctx: CanvasContext2d, center: Vec2[float], radius: float): void =
  ctx.beginPath()
  ctx.arc(center.x + radius, center.y + radius, radius, 0, 2 * PI)

proc renderEllipse(ctx: CanvasContext2d, info: EllipseInfo): void =
  ctx.beginPath()
  let
    c = info.center
    r = info.radius
  ctx.ellipse(c.x, c.y, r.x, r.y, info.rotation, info.startAngle, info.endAngle)

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

proc renderPrimitive(ctx: CanvasContext2d, p: Primitive, offset: Point): void =
  case p.kind
  of Container:
    discard
  of Path:
    ctx.beginPath()
    for segment in p.segments:
      renderSegment(ctx, segment)
    fillAndStroke(ctx, p.colorInfo, p.strokeInfo)
  of Text:
    renderText(ctx, p.colorInfo, p.textInfo)
  of Circle:
    let info = p.circleInfo
    renderCircle(ctx, info.center, info.radius)
    fillAndStroke(ctx, p.colorInfo, p.strokeInfo)
  of Ellipse:
    let info = p.ellipseInfo
    renderEllipse(ctx, info)
    fillAndStroke(ctx, p.colorInfo, p.strokeInfo)
  of Rectangle:
    if p.strokeInfo.isSome():
      ctx.lineWidth = p.strokeInfo.get().width
    if p.colorInfo.isSome():
      let b = p.rectangleInfo.bounds
      let ci = p.colorInfo.get()
      if ci.fill.isSome():
        ctx.fillStyle = ci.fill.get()
        ctx.fillRect(b.left, b.top, b.width, b.height)
      if ci.stroke.isSome():
        ctx.strokeStyle = ci.stroke.get()
        ctx.strokeRect(b.left, b.top, b.width, b.height)


proc render*(ctx: CanvasContext2d, primitive: Primitive): void =
  proc renderInner(primitive: Primitive, offset: Vec2[float]): void =
    ctx.save()
    if primitive.transform.isSome():
      let transform = primitive.transform.get()
      let wp = offset
      let size = primitive.bounds.size
      let xPos = wp.x + size.x / 2.0
      let yPos = wp.y + size.y / 2.0
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
      ctx.rect(offset.x, offset.y, cb.size.x, cb.size.y)
      ctx.clip()
    ctx.renderPrimitive(primitive, offset)
    for p in primitive.children:
      renderInner(p, offset + p.bounds.pos)
    ctx.restore()

  renderInner(primitive, vec2(0.0))
