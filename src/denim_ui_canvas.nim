when defined(js):
  import dom
import sugar
when defined(js):
  import canvas
when defined(emscripten):
  import canvas_emscripten
import canvas_renderer
import denim_ui
import denim_ui/gui/debug_draw

proc renderPrimitives(canvasContext: CanvasContext2d, primitive: Primitive, size: Vec2[float]): void =
  canvasContext.clearRect(0.0, 0.0, size.x, size.y)
  canvasContext.render(primitive)

proc startApp*(render: () -> denim_ui.Element, canvasElementId: string, nativeContainerId: string): void =
  when defined(js):
    let nativeContainer = getElementById(nativeContainerId)
    let canvasElem = getElementById(canvasElementId)
    let canvas = canvasElem.Canvas
  when defined(emscripten):
    #let nativeContainer = createCanvas(nativeContainerId)
    let canvas = createCanvas(canvasElementId)


  let canvasContext = canvas.getContext2d
  let scale = 2.0

  #var size = vec2(float(window.innerWidth),float(window.innerHeight))
  var size = vec2(500.0, 500.0)


  proc setCanvasProperties(): void =
    #var size = vec2(float(window.innerWidth),float(window.innerHeight))
    size = vec2(500.0, 500.0)
    echo "Size: ", size

    # canvas.style.width = $size.x & "px"
    # canvas.style.height = $size.y & "px"

    canvas.width = int(size.x * scale)
    canvas.height = int(size.y * scale)
    # canvas.width = size.x * window.devicePixelRatio * scale
    # canvas.height = size.y * window.devicePixelRatio * scale

    #canvasContext.scale(window.devicePixelRatio * scale * 2.0, window.devicePixelRatio * scale * 2.0)
    canvasContext.scale(scale * 2.0, scale * 2.0)
  #let canvasPixelScale = vec2(size.x / elementWidth * scaleFactor, size.y / elementHeight * scaleFactor)
  #canvasContext.translate(0.5, 0.5) # https://stackoverflow.com/questions/8696631/canvas-drawings-like-lines-are-blurry
  setCanvasProperties()

  proc measureText(text: string, fontSize: float, font: string, baseline: string): Vec2[float] =
    canvasContext.textBaseline = baseline
    canvasContext.font = $fontSize & "px " & font
    #let measured = canvas_measureText(canvasContext, text)
    result = vec2(100.0, fontSize)
    #result = vec2(measured.width, fontSize)

  proc hitTestPath(elem: denim_ui.Element, props: PathProps, point: Point): bool =
    if elem.bounds.isNone:
      return false
    canvasContext.save()
    canvasContext.resetTransform()
    let worldPos = elem.actualWorldPosition
    canvasContext.translate(worldPos.x, worldPos.y)
    canvasContext.lineWidth = 5.0
    if props.stringData.isSome:
      canvasContext.renderPath(props.stringData.get)
    elif props.data.isSome:
      canvasContext.renderPath(props.data.get)
    result = canvasContext.isPointInStroke(point.x, point.y)
    canvasContext.restore()

  # NOTE: Turning off mouse capture for the native layer while one of our elements has pointer capture
  when defined(js):
    pointerCapturedEmitter.add(
      proc(capturer: denim_ui.Element): void =
        nativeContainer.style.pointerEvents = "none"
    )

    pointerCaptureReleasedEmitter.add(
      proc(capturer: denim_ui.Element): void =
        nativeContainer.style.pointerEvents = "auto"
    )

  let context = denim_ui.init(
    size,
    vec2(scale, scale),
    measureText,
    hitTestPath,
    render
  )

  proc renderToJsCanvas(dt: float): void =
    let primitive = denim_ui.render(context, dt)
    if primitive.isSome():
      canvasContext.renderPrimitives(primitive.get(), size)

  when defined(js):
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

  when defined(js):
    type
      # NOTE: Polyfills missing event type in the dom module
      WheelEvent = ref object of MouseEvent
        deltaX: float
        deltaY: float
        deltaZ: float
        deltaMode: int
  when defined(emscripten):
    type
      # NOTE: Polyfills missing event type in the dom module
      WheelEvent = ref object
        deltaX: float
        deltaY: float
        deltaZ: float
        deltaMode: int

  when defined(js):
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
    when defined(js):
      nativeContainer.addEventListener "contextmenu", proc(event: Event) =
        event.preventDefault()
        event.stopPropagation()


  var isAnimating = true

  var lastTime = 0.0
  proc frame(time: float): void =
    let dt = time - lastTime
    lastTime = time

    renderToJsCanvas(dt)

    when defined(js):
      discard dom.window.requestAnimationFrame(frame)

  frame(lastTime)
