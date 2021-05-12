import options, strformat, sugar, dom
import colors
import denim_ui
import denim_ui/gui/primitives/defaults
import denim_ui/gui/primitives/text

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

proc updateTextProps(self: HtmlTextInput): void =
  self.domElement.style.color = $self.textInputProps.color.get("black".parseColor())

proc createHtmlTextInput(props: TextInputProps): dom.Element =
  if props.wordWrap:
    result = document.createElement("TEXTAREA")
    result.addEventListener("keydown", proc(event: Event) =
      let ev = cast[KeyboardEvent](event)
      if $ev.key == "Enter" and props.preventNewLineOnEnter:
        event.preventDefault()
    )
    #result.style.setProperty("word-wrap", "normal")
    result.style.setProperty("word-break", "normal")
    result.style.setProperty("wrap", "soft")
    result.style.setProperty("overflow", "hidden")
    result.style.setProperty("resize", "none")
    result.style.setProperty("line-height", "1.0")
  else:
    result = document.createElement("INPUT")
  result.style.position = "absolute"
  # TODO: Remove or replace this: result.updateTextProps(props)
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

  let (lines, totalSize) = measureMultilineText(
    props.text,
    props.font.get(defaults.font),
    props.fontSize.get(defaults.fontSize),
    props.wordWrap,
    availableSize
  )
  totalSize

# TODO: We are kind of misusing render here. Create a way to react to layouts instead of using render.
method render(self: HtmlTextInput): Option[Primitive] =
  let props = self.textInputProps
  let (bounds, scale) = self.worldBoundsExpensive()
  let fontSize = props.fontSize.get(12.0) * max(scale.x, scale.y)
  let pos = bounds.pos
  self.domElement.style.background = "none"
  self.domElement.style.outline = "none"
  self.domElement.style.borderStyle = "none"
  if not self.textInputProps.wordWrap:
    self.domElement.style.overflow = "visible"
    self.domElement.style.lineHeight = "normal"
    # TODO: Fix hack of adding 6 to text input height to avoid clipping
    self.domElement.style.height = &"{bounds.height + 6.0}px"
  else:
    self.domElement.style.height = &"{bounds.height}px"
  self.domElement.style.textOverflow = "visible"
  self.domElement.style.width = &"{bounds.width}px"
  self.domElement.style.transform = &"translate({pos.x}px,{pos.y - 5.0}px)"
  self.domElement.style.padding = &"0 0 0 0"
  self.domElement.style.margin = &"0 0 0 0"
  self.domElement.style.fontSize = &"{fontSize}px"
  if props.font.isSome:
    self.domElement.style.fontFamily = props.font.get
  self.updateTextProps()
  if props.text != self.domElement.value:
    self.domElement.value = props.text
  none[Primitive]()

method onRooted(self: HtmlTextInput): void =
  # TODO: Dispose of subscription
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
        textInputProps.onChange.get()($ev.target.value)
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
