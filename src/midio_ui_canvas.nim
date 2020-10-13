import dom
import sugar
import canvas
import canvas_renderer
import midio_ui

const scaleFactor = 2.0
const size = 2000.0
let scale = window.devicePixelRatio * scaleFactor

let nativeContainer = getElementById("nativeContainer")
let canvasElem = getElementById("rootCanvas")
let elementWidth = canvasElem.offsetWidth
let elementHeight = canvasElem.offsetHeight
let canvasPixelScale = vec2(size / elementWidth * scaleFactor, size / elementHeight * scaleFactor)

echo "Canvas pixel scale: ", canvasPixelScale

type
  JsContext = ref object
    render*: (float) -> void
    dispatchPointerMove*: (float, float) -> void
    dispatchPointerPress*: (float, float) -> void
    dispatchPointerRelease*: (float, float) -> void
    dispatchKeyDown*: (int, string) -> void
    dispatchUpdate*: (float) -> void

proc renderPrimitives(canvasContext: CanvasContext2d, primitives: seq[Primitive]): void =
  canvasContext.clearRect(0.0, 0.0, size, size)
  canvasContext.render(primitives)

proc initJsContext*(render: () -> midio_ui.Element): JsContext {.exportc.} =
  let canvas = canvasElem.Canvas

  canvas.width = size
  canvas.height = size

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
    vec2(size,size),
    vec2(scale, scale),
    measureText,
    render
  )

  proc renderToJsCanvas(dt: float): void =
    let primitives = midio_ui.render(context, dt)
    canvasContext.renderPrimitives(primitives)

  JsContext(
    render: renderToJsCanvas,
    dispatchPointerMove: context.dispatchPointerMove,
    dispatchPointerPress: context.dispatchPointerDown,
    dispatchPointerRelease: context.dispatchPointerUp,
    dispatchKeyDown: context.dispatchKeyDown,
    dispatchUpdate: context.dispatchUpdate,
  )



#dom.window.addEventListener "resize", proc(event: Event) =

#dom.window.addEventListener "scroll", proc(event: Event) =
#

# TODO: Use canvasElementId and nativeContainerId
proc startApp*(render: () -> midio_ui.Element, canvasElementId: string, nativeContainerId: string): void =
  let ctx = initJsContext(render)

  dom.window.addEventListener "mousedown", proc(event: Event) =
    let ev = cast[MouseEvent](event)
    let canvas = document.getElementById("rootCanvas")
    let bounds = canvas.getBoundingClientRect()
    ctx.dispatchPointerPress(ev.clientX - bounds.left, ev.clientY - bounds.top)

  dom.window.addEventListener "mouseup", proc(event: Event) =
    let ev = cast[MouseEvent](event)
    let canvas = document.getElementById("rootCanvas")
    let bounds = canvas.getBoundingClientRect()
    ctx.dispatchPointerRelease(ev.clientX - bounds.left, ev.clientY - bounds.top)

  dom.window.addEventListener "mousemove", proc(event: Event) =
    let ev = cast[MouseEvent](event)
    let canvas = document.getElementById("rootCanvas")
    let bounds = canvas.getBoundingClientRect()
    ctx.dispatchPointerMove(ev.clientX - bounds.left, ev.clientY - bounds.top)

  dom.window.addEventListener "keydown", proc(event: Event) =
    ## When keyboards key is pressed down
    ## Used together with key up for continuous things like scroll or games
    let ev = cast[KeyboardEvent](event)
    ctx.dispatchKeyDown(ev.keyCode, $ev.key)

  var isAnimating = true

  var lastTime = 0.0
  proc frame(time: float): void =
    let dt = time - lastTime
    lastTime = time

    ctx.dispatchUpdate(dt)
    ctx.render(dt)

    discard dom.window.requestAnimationFrame(frame)

  frame(lastTime)
