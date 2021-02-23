import options, strformat, sugar, dom
import colors
import denim_ui
import denim_ui/gui/primitives/defaults

# TODO: Move all this stuff to the canvas renderer

# domElement.contains(domElement) polyfill
proc contains(self: dom.Element, elem: dom.Element): bool {.importjs: "#.contains(@)".}

var nativeContainer: dom.Element = nil

proc getNativeContainer(): dom.Element =
  if isNil(nativeContainer):
    nativeContainer = getElementById("nativeContainer")
  nativeContainer

type
  HtmlTextInput* = ref object of TextInput
    domElement*: dom.Element

proc updateTextProps(self: HtmlTextInput): void =
  self.domElement.style.color = $self.textInputProps.color.get("black".parseColor())

proc createHtmlTextInput(props: TextInputProps): dom.Element =
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

  measureText(actualText, props.fontSize.get(12.0), props.font.get(defaults.font), "top")

# TODO: We are kind of misusing render here. Create a way to react to layouts instead of using render.
method render(self: HtmlTextInput): Option[Primitive] =
  let props = self.textInputProps
  let (bounds, scale) = self.worldBoundsExpensive()
  echo "SCALE IS : ", scale
  let fontSize = props.fontSize.get(12.0) * max(scale.x, scale.y)
  let pos = bounds.pos
  self.domElement.style.transform = &"translate({pos.x}px,{pos.y}px)"
  self.domElement.style.background = "none"
  self.domElement.style.width = &"{bounds.width}px"
  self.domElement.style.height = &"{bounds.height}px"
  self.domElement.style.padding = &"0 0 0 0"
  self.domElement.style.margin = &"0 0 0 0"
  echo "setting font size to: ", fontSize
  self.domElement.style.fontSize = &"{fontSize}px"
  self.updateTextProps()
  if props.text != self.domElement.innerHtml:
    self.domElement.innerHtml = props.text
  none[Primitive]()

method onRooted(self: HtmlTextInput): void =
  getNativeContainer().appendChild(self.domElement)
  if self.textInputProps.focusWhenRooted.get(true):
    self.domElement.focus()

method onUnrooted(self: HtmlTextInput): void =
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
  result = HtmlTextInput(
    textInputProps: textInputProps,
    domElement: domElement
  )
  initElement(result, elemProps)
