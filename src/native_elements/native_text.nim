import options, strformat, sugar, dom
import colors
import denim_ui
import denim_ui/gui/primitives/defaults

proc contains(self: dom.Element, elem: dom.Element): bool {.importjs: "#.contains(@)".}

var nativeContainer: dom.Element = nil

proc getNativeContainer(): dom.Element =
  if isNil(nativeContainer):
    nativeContainer = getElementById("nativeContainer")
  nativeContainer

type
  HtmlText* = ref object of Text
    domElement*: dom.Element

proc updateTextProps(self: HtmlText): void =
  self.domElement.style.color = $self.textProps.color.get("black".parseColor())

proc createHtmlText(props: TextProps): dom.Element =
  result = document.createElement("DIV")
  result.style.position = "absolute"
  result.innerHtml = props.text

method measureOverride(self: HtmlText, availableSize: Vec2[float]): Vec2[float] =
  self.domElement.style.width = &"{availableSize.x}px"
  vec2(float(self.domElement.clientWidth), float(self.domElement.clientHeight))

# TODO: We are kind of misusing render here. Create a way to react to layouts instead of using render.
method render(self: HtmlText): Option[Primitive] =
  let props = self.textProps
  let (bounds, scale) = self.worldBoundsExpensive()
  let fontSize = props.fontSize.get(12.0) * max(scale.x, scale.y)
  let pos = bounds.pos
  self.domElement.style.background = "none"
  self.domElement.style.outline = "none"
  self.domElement.style.borderStyle = "none"
  self.domElement.style.textOverflow = "visible"
  self.domElement.style.overflow = "visible"
  self.domElement.style.lineHeight = "1.0"
  self.domElement.style.width = &"{bounds.width}px"
  # TODO: Fix hack of adding 6 to text input height to avoid clipping
  self.domElement.style.height = &"{bounds.height + 6.0}px"
  self.domElement.style.transform = &"translate({pos.x}px,{pos.y - 5.0}px)"
  self.domElement.style.padding = &"0 0 0 0"
  self.domElement.style.margin = &"0 0 0 0"
  if props.fontFamily.isSome:
    self.domElement.style.fontFamily = props.fontFamily.get
  self.domElement.style.fontSize = &"{fontSize}px"
  self.updateTextProps()
  none[Primitive]()

method onRooted(self: HtmlText): void =
  getNativeContainer().appendChild(self.domElement)

method onUnrooted(self: HtmlText): void =
  let nativeContainer = getNativeContainer()
  if nativeContainer.contains(self.domElement):
    nativeContainer.removeChild(self.domElement)

proc createHtmlText*(props: (ElementProps, TextProps), children: seq[denim_ui.Element] = @[]): HtmlText =
  let (elemProps, textProps) = props
  let domElement = createHtmlText(textProps)
  result = HtmlText(
    textProps: textProps,
    domElement: domElement
  )
  initElement(result, elemProps)
