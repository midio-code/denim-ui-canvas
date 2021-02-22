import dom
import sugar
import canvas
import canvas_renderer
import native_elements/text_input
import denim_ui
import denim_ui/gui/debug_draw

proc renderPrimitives(canvasContext: CanvasContext2d, primitive: Primitive, size: Vec2[float]): void =
  canvasContext.clearRect(0.0, 0.0, size.x, size.y)
  canvasContext.render(primitive)

proc startApp*(render: () -> denim_ui.Element, canvasElementId: string, nativeContainerId: string): void =
  let nativeContainer = getElementById(nativeContainerId)
  let canvasElem = getElementById(canvasElementId)

  let canvas = canvasElem.Canvas

  let canvasContext = canvas.getContext2d
  let scale = 1.0

  var size = vec2(float(window.innerWidth),float(window.innerHeight))

  proc setCanvasProperties(): void =
    size = vec2(float(window.innerWidth),float(window.innerHeight))

    canvas.style.width = $size.x & "px"
    canvas.style.height = $size.y & "px"

    canvas.width = size.x * window.devicePixelRatio * scale
    canvas.height = size.y * window.devicePixelRatio * scale

    canvasContext.scale(window.devicePixelRatio * scale, window.devicePixelRatio * scale)
  #let canvasPixelScale = vec2(size.x / elementWidth * scaleFactor, size.y / elementHeight * scaleFactor)
  #canvasContext.translate(0.5, 0.5) # https://stackoverflow.com/questions/8696631/canvas-drawings-like-lines-are-blurry
  setCanvasProperties()

  proc measureText(text: string, fontSize: float, font: string, baseline: string): Vec2[float] =
    canvasContext.textBaseline = baseline
    canvasContext.font = $fontSize & "px " & font
    let measured = canvas_measureText(canvasContext, text)
    result = vec2(measured.width, fontSize)

  proc hitTestPath(elem: denim_ui.Element, props: PathProps, point: Point): bool =
    if elem.bounds.isNone:
      return false
    canvasContext.save()
    canvasContext.resetTransform()
    let worldPos = elem.actualWorldPosition
    canvasContext.translate(worldPos.x, worldPos.y)
    canvasContext.lineWidth = 14.0
    if props.stringData.isSome:
      canvasContext.renderPath(props.stringData.get)
    elif props.data.isSome:
      canvasContext.renderPath(props.data.get)
    result = canvasContext.isPointInStroke(point.x, point.y)
    canvasContext.restore()

  # NOTE: Turning off mouse capture for the native layer while one of our elements has pointer capture
  pointerCapturedEmitter.add(
    proc(capturer: PointerCaptureChangedArgs): void =
      nativeContainer.style.pointerEvents = "none"
  )

  pointerCaptureReleasedEmitter.add(
    proc(capturer: PointerCaptureChangedArgs): void =
      nativeContainer.style.pointerEvents = "auto"
  )

  let context = denim_ui.init(
    size,
    vec2(scale, scale),
    measureText,
    hitTestPath,
    render,
    NativeElements(
      createTextInput: createHtmlTextInput
    )
  )

  proc renderToJsCanvas(dt: float): void =
    let primitive = denim_ui.render(context, dt)
    if primitive.isSome():
      canvasContext.renderPrimitives(primitive.get(), size)

  dom.window.addEventListener "pointerdown", proc(event: Event) =
    let ev = cast[MouseEvent](event)
    let canvas = document.getElementById("rootCanvas")
    let bounds = canvas.getBoundingClientRect()
    context.dispatchPointerDown(ev.clientX - bounds.left, ev.clientY - bounds.top, cast[PointerIndex](ev.button))

  dom.window.addEventListener "pointerup", proc(event: Event) =
    let ev = cast[MouseEvent](event)
    let canvas = document.getElementById("rootCanvas")
    let bounds = canvas.getBoundingClientRect()
    context.dispatchPointerUp(ev.clientX - bounds.left, ev.clientY - bounds.top, cast[PointerIndex](ev.button))

  dom.window.addEventListener "pointermove", proc(event: Event) =
    let ev = cast[MouseEvent](event)
    let canvas = document.getElementById("rootCanvas")
    let bounds = canvas.getBoundingClientRect()
    context.dispatchPointerMove(ev.clientX - bounds.left, ev.clientY - bounds.top)

  type
    # NOTE: Polyfills missing event type in the dom module
    WheelEvent = ref object of MouseEvent
      deltaX: float
      deltaY: float
      deltaZ: float
      deltaMode: int

  dom.window.addEventListener "wheel", proc(event: Event) =
    let ev = cast[WheelEvent](event)
    let canvas = document.getElementById("rootCanvas")
    let bounds = canvas.getBoundingClientRect()
    context.dispatchWheel(ev.clientX - bounds.left, ev.clientY - bounds.top, ev.deltaX, ev.deltaY, ev.deltaZ, WheelDeltaUnit(ev.deltaMode))

  dom.window.addEventListener "keydown", proc(event: Event) =
    let ev = cast[KeyboardEvent](event)
    context.dispatchKeyDown(ev.keyCode, $ev.key)

  dom.window.addEventListener "keyup", proc(event: Event) =
    let ev = cast[KeyboardEvent](event)
    context.dispatchKeyUp(ev.keyCode, $ev.key)

  dom.window.addEventListener "resize", proc(event: Event) =
    let ev = cast[UIEvent](event)
    setCanvasProperties()
    context.dispatchWindowSizeChanged(size)
    context.rootElement.invalidateLayout()

  canvasElem.addEventListener "contextmenu", proc(event: Event) =
    event.preventDefault()
    event.stopPropagation()
  nativeContainer.addEventListener "contextmenu", proc(event: Event) =
    event.preventDefault()
    event.stopPropagation()


  var isAnimating = true

  var lastTime = 0.0
  proc frame(time: float): void =
    let dt = time - lastTime
    lastTime = time

    renderToJsCanvas(dt)

    discard dom.window.requestAnimationFrame(frame)

  frame(lastTime)
