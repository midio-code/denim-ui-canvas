import dom
import strformat
import sugar
import canvas
import canvas_renderer
import native_elements/text_input
import native_elements/native_text
import denim_ui

proc renderPrimitives(canvasContext: CanvasContext2d, primitive: Primitive, size: Vec2[float]): void =
  canvasContext.clearRect(0.0, 0.0, size.x, size.y)
  canvasContext.render(primitive)

let transparent = "#000000".parseColor.withAlpha(0x00).toHexCStr

proc startApp*(render: () -> denim_ui.Element, canvasElementId: string, nativeContainerId: string): void =
  let nativeContainer = getElementById(nativeContainerId)
  let canvasElem = getElementById(canvasElementId)

  let canvas = canvasElem.Canvas

  let canvasContext = canvas.getContext2d()
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

  proc measureText(text: string, fontSize: float, fontFamily: string, fontWeight: int, baseline: string): Vec2[float] =
    canvasContext.textBaseline = baseline
    canvasContext.font = &"{$fontWeight} {$fontSize}px {fontFamily}"
    let measured = canvas_measureText(canvasContext, text)
    result = vec2(measured.width, fontSize)

  proc hitTestPath(elem: denim_ui.Element, props: PathProps, point: Point): bool =
    if elem.bounds.isNone:
      return false
    canvasContext.save()
    canvasContext.resetTransform()
    let worldPos = elem.actualWorldPosition.get(zero())
    canvasContext.translate(worldPos.x, worldPos.y)
    canvasContext.lineWidth = 14.0
    canvasContext.fillStyle = transparent
    canvasContext.strokeStyle = transparent
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

  var renderRequested = false
  proc requestRerender() =
    renderRequested = true

  let context = denim_ui.init(
    size,
    vec2(scale, scale),
    measureText,
    hitTestPath,
    requestRerender,
    render,
    NativeElements(
      createTextInput: createHtmlTextInput,
      createNativeText: createHtmlText,
    ),
    proc(cursor: Cursor): void =
      let c = case cursor:
        of Cursor.Default:
          "default"
        of Cursor.Clickable:
          "pointer"
        of Cursor.Dragging:
          "all-scroll"

      document.body.style.cursor = c
  )

  proc render(): void =
    let primitive = denim_ui.render(context)
    if primitive.isSome():
      canvasContext.renderPrimitives(primitive.get(), size)

  canvasElem.addEventListener "pointerdown", proc(event: Event) =
    let ev = cast[MouseEvent](event)
    let canvas = document.getElementById("rootCanvas")
    let bounds = canvas.getBoundingClientRect()
    context.dispatchPointerDown(ev.clientX - bounds.left, ev.clientY - bounds.top, cast[PointerIndex](ev.button))

  canvasElem.addEventListener "pointerup", proc(event: Event) =
    let ev = cast[MouseEvent](event)
    let canvas = document.getElementById("rootCanvas")
    let bounds = canvas.getBoundingClientRect()
    context.dispatchPointerUp(ev.clientX - bounds.left, ev.clientY - bounds.top, cast[PointerIndex](ev.button))

  # TODO: We do this so that we can detect if any of these were pressed or release while outside the window.
  # We should find a way to handle this case for all keys. The reason we do it for these keys is because they are
  # included in the pointer events for some reason.
  var shiftDown = false
  var controlDown = false
  var altDown = false

  proc modifiersList[T](ev: T): seq[string] =
    if ev.ctrlKey:
      result.add("Ctrl")
    if ev.shiftKey:
      result.add("Shift")
    if ev.altKey:
      result.add("Alt")
    if ev.metaKey:
      result.add("Meta")

  canvasElem.addEventListener "pointermove", proc(event: Event) =
    let ev = cast[MouseEvent](event)

    if ev.ctrlKey != controlDown:
      controlDown = ev.ctrlKey
      if controlDown:
        context.dispatchKeyDown("Ctrl", modifiersList(ev))
      else:
        context.dispatchKeyUp("Ctrl", modifiersList(ev))

    if ev.shiftKey != shiftDown:
      shiftDown = ev.shiftKey
      if shiftDown:
        context.dispatchKeyDown("Shift", modifiersList(ev))
      else:
        context.dispatchKeyUp("Shift", modifiersList(ev))

    if ev.altKey != altDown:
      altDown = ev.altKey
      if altDown:
        context.dispatchKeyDown("Alt", modifiersList(ev))
      else:
        context.dispatchKeyUp("Alt", modifiersList(ev))

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

  canvasElem.addEventListener(
    "wheel",
    proc(event: Event) =
      let ev = cast[WheelEvent](event)
      ev.preventDefault()
      let canvas = document.getElementById("rootCanvas")
      let bounds = canvas.getBoundingClientRect()
      context.dispatchWheel(ev.clientX - bounds.left, ev.clientY - bounds.top, ev.deltaX, ev.deltaY, ev.deltaZ, WheelDeltaUnit(ev.deltaMode)),
    AddEventListenerOptions(passive: false)
  )

  dom.window.addEventListener "keydown", proc(event: Event) =
    let ev = cast[KeyboardEvent](event)
    var modifiers: seq[string] = modifiersList(ev)
    if $ev.key == "Shift":
      shiftDown = true
    if $ev.key == "Ctrl":
      controlDown = true
    if $ev.key == "Alt":
      altDown = true
    context.dispatchKeyDown($ev.key, modifiers)

  dom.window.addEventListener "keyup", proc(event: Event) =
    let ev = cast[KeyboardEvent](event)
    var modifiers: seq[string] = modifiersList(ev)
    if $ev.key == "Shift":
      shiftDown = false
    if $ev.key == "Ctrl":
      controlDown = false
    if $ev.key == "Alt":
      altDown = false
    context.dispatchKeyUp($ev.key, modifiers)

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
  nativeContainer.addEventListener "dblclick", proc(event: Event) =
    event.preventDefault()
    event.stopPropagation()

  var lastTime = 0.0
  proc frame(time: float): void =
    let dt = time - lastTime
    lastTime = time

    context.update(dt)
    if renderRequested:
      render()
      renderRequested = false


    discard dom.window.requestAnimationFrame(frame)

  frame(lastTime)
