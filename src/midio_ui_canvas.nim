import dom
import sugar
import canvas
import canvas_renderer
import midio_ui

proc renderPrimitives(canvasContext: CanvasContext2d, primitive: Primitive, size: Vec2[float]): void =
  canvasContext.clearRect(0.0, 0.0, size.x, size.y)
  canvasContext.render(primitive)


#dom.window.addEventListener "scroll", proc(event: Event) =

proc startApp*(render: () -> midio_ui.Element, canvasElementId: string, nativeContainerId: string): void =
  let nativeContainer = getElementById(nativeContainerId)
  let canvasElem = getElementById(canvasElementId)

  let canvas = canvasElem.Canvas

  const scaleFactor = 2.0
  var size = vec2(float(window.innerWidth),float(window.innerHeight))
  let scale = window.devicePixelRatio * scaleFactor

  canvas.width = size.x
  canvas.height = size.y

  let elementWidth = canvasElem.offsetWidth
  let elementHeight = canvasElem.offsetHeight
  let canvasPixelScale = vec2(size.x / elementWidth * scaleFactor, size.y / elementHeight * scaleFactor)


  let canvasContext = canvas.getContext2d
  canvasContext.scale(scale, scale)
  #canvasContext.translate(0.5, 0.5) # https://stackoverflow.com/questions/8696631/canvas-drawings-like-lines-are-blurry

  proc measureText(text: string, fontSize: float, font: string, baseline: string): Vec2[float] =
    canvasContext.textBaseline = baseline
    canvasContext.font = $fontSize & "px " & font
    let measured = canvas_measureText(canvasContext, text)
    result = vec2(measured.width, fontSize)

  # NOTE: Turning off mouse capture for the native layer while one of our elements has pointer capture
  pointerCapturedEmitter.add(
    proc(capturer: midio_ui.Element): void =
      nativeContainer.style.pointerEvents = "none"
  )

  pointerCaptureReleasedEmitter.add(
    proc(capturer: midio_ui.Element): void =
      nativeContainer.style.pointerEvents = "auto"
  )

  let context = midio_ui.init(
    size,
    vec2(scale, scale),
    measureText,
    render
  )

  proc renderToJsCanvas(dt: float): void =
    let primitive = midio_ui.render(context, dt)
    if primitive.isSome():
      canvasContext.renderPrimitives(primitive.get(), size)

  dom.window.addEventListener "mousedown", proc(event: Event) =
    let ev = cast[MouseEvent](event)
    let canvas = document.getElementById("rootCanvas")
    let bounds = canvas.getBoundingClientRect()
    context.dispatchPointerDown(ev.clientX - bounds.left, ev.clientY - bounds.top)

  dom.window.addEventListener "mouseup", proc(event: Event) =
    let ev = cast[MouseEvent](event)
    let canvas = document.getElementById("rootCanvas")
    let bounds = canvas.getBoundingClientRect()
    context.dispatchPointerUp(ev.clientX - bounds.left, ev.clientY - bounds.top)

  dom.window.addEventListener "mousemove", proc(event: Event) =
    let ev = cast[MouseEvent](event)
    let canvas = document.getElementById("rootCanvas")
    let bounds = canvas.getBoundingClientRect()
    context.dispatchPointerMove(ev.clientX - bounds.left, ev.clientY - bounds.top)

  dom.window.addEventListener "keydown", proc(event: Event) =
    let ev = cast[KeyboardEvent](event)
    context.dispatchKeyDown(ev.keyCode, $ev.key)

  dom.window.addEventListener "resize", proc(event: Event) =
    let ev = cast[UIEvent](event)
    size = vec2(float(window.innerWidth),float(window.innerHeight))
    canvas.width = size.x
    canvas.height = size.y
    context.dispatchWindowSizeChanged(size)
    canvasContext.scale(scale, scale)
    context.rootElement.invalidateLayout()

  var isAnimating = true

  var lastTime = 0.0
  proc frame(time: float): void =
    let dt = time - lastTime
    lastTime = time

    renderToJsCanvas(dt)

    discard dom.window.requestAnimationFrame(frame)

  frame(lastTime)
