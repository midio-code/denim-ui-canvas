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
  if colorInfo.isSome():
    let ci = colorInfo.get()
    if ci.fill.isSome():
      ctx.fillStyle = ci.fill.get()
      ctx.fill()
    if ci.stroke.isSome():
      ctx.strokeStyle = ci.stroke.get()
      ctx.stroke()

proc render*(ctx: CanvasContext2d, primitives: seq[Primitive]): void =
  ctx.save()
  for p in primitives:
    ctx.restore()
    ctx.save()
    ctx.beginPath()
    if p.clipBounds.isSome():
      let cb = p.clipBounds.get()
      ctx.rect(cb.pos.x, cb.pos.y, cb.size.x, cb.size.y)
      ctx.clip()

    case p.kind
    of Path:
      ctx.beginPath()
      for segment in p.segments:
        renderSegment(ctx, segment)
      fillAndStroke(ctx, p.colorInfo, p.strokeInfo)
    of Text:
      renderText(ctx, p.colorInfo, p.textInfo)
    of Circle:
      let info = p.circleInfo
      ctx.beginPath()
      renderCircle(ctx, info.center, info.radius)
      fillAndStroke(ctx, p.colorInfo, p.strokeInfo)
    of Ellipse:
      let info = p.ellipseInfo
      ctx.beginPath()
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
