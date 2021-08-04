import options, strformat, sugar, dom, tables
import denim_ui
import denim_ui/gui/primitives/defaults
import denim_ui/gui/primitives/text
import jsffi
import math

proc contains(self: dom.Element, elem: dom.Element): bool {.importjs: "#.contains(@)".}

var nativeContainer: dom.Element = nil

proc getNativeContainer(): dom.Element =
  if isNil(nativeContainer):
    nativeContainer = getElementById("nativeContainer")
  nativeContainer

type
  HtmlTextInput* = ref object of TextInput
    domElement*: dom.Element
    isFocusedSubscription: Subscription

proc createHtmlTextInput(props: TextInputProps): dom.Element =
  let fontSize = props.fontSize.get(defaults.fontSize)
  if props.wordWrap:
    result = document.createElement("TEXTAREA")
    result.style.setProperty("overflow", "hidden")
    result.style.setProperty("resize", "none")

    result.addEventListener("keydown", proc(event: Event) =
      let ev = cast[KeyboardEvent](event)
      if $ev.key == "Enter" and props.preventNewLineOnEnter:
        event.preventDefault()
    )
  else:
    result = document.createElement("INPUT")

  result.style.position = "fixed"
  result.style.background = "none"
  result.style.outline = "none"
  result.style.borderStyle = "none"
  result.style.setProperty("transform-origin", "top left")

  result.style.padding = "0px"
  result.style.margin = "0px"

  if props.placeholder.isSome():
    result.setAttribute("placeholder", props.placeholder.get())

  result.value = props.text

method measureOverride(self: HtmlTextInput, availableSize: Vec2[float]): Vec2[float] =
  let props = self.textInputProps
  let actualText =
    if props.text == "":
      props.placeholder.get("")
    else:
      props.text

  let fontSize = props.fontSize.get(defaults.fontSize)

  let (lines, totalSize) = measureMultilineText(
    props.text,
    props.fontFamily.get(defaults.fontFamily),
    fontSize,
    props.fontWeight.get(defaults.fontWeight),
    props.wordWrap,
    props.lineHeight.get(fontSize),
    availableSize
  )
  totalSize

template setIfChanged(prop: untyped, value: untyped): untyped =
  let computedValue = value
  if prop != computedValue:
    # NOTE: Since the dom sometimes returns a different string value from the one we set it to
    # this check is not reliable.
    # In the future we might want to introduce a more granular change system, where we only get notified about
    # which properties have changed, making this check implicit.
    prop = computedValue

method updateNativeElement(self: HtmlTextInput): void =
  let props = self.textInputProps
  let
    wbe = self.worldBoundsExpensive()
    bounds = wbe.bounds
    scale = wbe.scale

  let scaleFactor = max(scale.x, scale.y)
  let fontSize = props.fontSize.get(12.0)
  let fontWeight = props.fontWeight.get(400)
  let fontStyle = props.fontStyle.get("normal")
  let lineHeight = props.lineHeight.get(fontSize)

  setIfChanged(self.domElement.value, props.text)


  self.domElement.style.setProperty("line-height", &"{lineHeight}px")
  setIfChanged(self.domElement.style.fontSize, &"{fontSize}px")
  setIfChanged(self.domElement.style.fontWeight, $fontWeight)
  setIfChanged(self.domElement.style.fontStyle, &"{fontStyle}")
  setIfChanged(self.domElement.style.width, &"{self.bounds.get.width}px")
  setIfChanged(self.domElement.style.height, &"{self.bounds.get.height}px")

  # setIfChanged(self.domElement.style.left, &"{bounds.pos.x - 1.0}px")
  # setIfChanged(self.domElement.style.top, &"{bounds.pos.y - 1.5}px")

  let x = (bounds.pos.x - 1.0) / scaleFactor
  let y = (bounds.pos.y - 1.5) / scaleFactor

  self.domElement.style.transform = &"scale({scaleFactor}, {scaleFactor}) translate({x}px, {y}px)"

  setIfChanged(self.domElement.style.color, $self.textInputProps.color.get("#000000".parseColor()))

  if props.fontFamily.isSome:
    self.domElement.style.fontFamily = props.fontFamily.get

# TODO: Now we update all the native properties every frame while the native
# element is rooted. This is fine for now since we mostly just have one or two active at the same time,
# but will have to be fixed eventually.
var disposeUpdateHandlers = initTable[HtmlTextInput, () -> void]()

method onRooted(self: HtmlTextInput): void =
  disposeUpdateHandlers[self] = addBeforeRenderListener(
    proc() =
      updateNativeElement(self)
  )
  self.isFocusedSubscription = self.hasFocus().subscribe(
    proc(val: bool): void =
      if val == false:
        self.domElement.blur()
  )

  getNativeContainer().appendChild(self.domElement)
  if self.textInputProps.text != self.domElement.innerHtml:
    self.domElement.value = self.textInputProps.text
  if self.textInputProps.focusWhenRooted.get(true):
    self.domElement.focus()
    self.domElement.select()

method onUnrooted(self: HtmlTextInput): void =
  if self in disposeUpdateHandlers:
    disposeUpdateHandlers[self]()
    disposeUpdateHandlers.del(self)
  if not isNil(self.isFocusedSubscription):
    self.isFocusedSubscription.dispose()

  let nativeContainer = getNativeContainer()
  if nativeContainer.contains(self.domElement):
    nativeContainer.removeChild(self.domElement)

proc createHtmlTextInput*(props: (ElementProps, TextInputProps), children: seq[denim_ui.Element] = @[]): HtmlTextInput =
  let (elemProps, textInputProps) = props
  let domElement = createHtmlTextInput(textInputProps)
  domElement.addEventListener(
    "input",
    proc(ev: dom.Event): void =
      if textInputProps.onChange.isSome():
        textInputProps.onChange.get()(
          $ev.target.value,
          TextChangedInfo(
            selectionStart: ev.toJs.srcElement.selectionStart.to(int),
            selectionEnd: ev.toJs.srcElement.selectionEnd.to(int)
          )
        )
  )
  let textInputElem = HtmlTextInput(
    textInputProps: textInputProps,
    domElement: domElement
  )

  domElement.addEventListener(
    "focus",
    proc(ev: dom.Event): void =
      textInputElem.giveFocus()
  )

  initElement(textInputElem, elemProps)
  textInputElem
