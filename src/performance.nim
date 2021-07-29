import jsffi
import dom
import tables
import strformat
import canvas
import math
import colors
import denim_ui

var console {.importc, nodecl.}: JsObject

const width = 600.0
const height = 130.0
const textPanelWidth = 250.0
const textPanelHeight = height * 2.0
const numFramesToDisplay = 120

proc lerp(t, a, b: float): float =
  return a + t * (b - a);

var performance {.importc, nodecl.}: dom.Performance

type
  Frame = ref FrameObj
  FrameObj = object
    startTime: float
    endTime: float
    events: seq[tuple[label: cstring, timeSpent: float]]

  Performance* = ref PerformanceObj
  PerformanceObj* = object
    stopped: bool
    pos: Point
    hoveredFrame: int
    currentTicks: Table[cstring, float]
    currentFrame: int
    frames: array[numFramesToDisplay,Frame]

proc newPerformance*(pos: Point): Performance =
  Performance(
    stopped: false,
    pos: pos,
    hoveredFrame: -1,
    currentTicks: initTable[cstring, float](),
    currentFrame: 0
  )

proc tick*(self: Performance, label: cstring): void =
  if self.stopped:
    return
  self.currentTicks[label] = performance.now()

proc tock*(self: Performance, label: cstring): void =
  if self.stopped:
    return

  let n = performance.now()
  let last = self.currentTicks[label]
  let timeSpentSinceTick = n - last
  self.frames[self.currentFrame].events.add((label, timeSpentSinceTick))


var performanceCanvas = createCanvas()
performanceCanvas.width = width + textPanelWidth
performanceCanvas.height = height + 500.0

let performanceCanvasContext = performanceCanvas.getContext2d()

proc beginFrame*(self: Performance): void =
  if self.stopped:
    return

  console.timeStamp("Frame " & $self.currentFrame)
  self.frames[self.currentFrame] = Frame(
    startTime: performance.now(),
    events: @[]
  )

proc endFrame*(self: Performance): void =
  if self.stopped:
    return
  self.frames[self.currentFrame].endTime = performance.now()
  self.currentFrame = floorMod(self.currentFrame + 1, numFramesToDisplay)

proc onMouseMove*(self: Performance, x, y: float): void =
  if x >= self.pos.x and x < self.pos.x + width and y >= self.pos.y and y <= self.pos.y + height:
    let barWidth = width / numFramesToDisplay
    let frameIndex = ((x - self.pos.x) / barWidth).floor().int
    self.hoveredFrame = frameIndex
  else:
    self.hoveredFrame = -1

proc onMouseClick*(self: Performance, x, y: float): void =
  if x >= self.pos.x and x < self.pos.x + width and y >= self.pos.y and y <= self.pos.y + height:
    self.stopped = true
  else:
    self.stopped = false


proc drawLastFrame(self: Performance): void =
  const barWidth = width / numFramesToDisplay
  let lastFrameIndex = floorMod(self.currentFrame - 1, numFramesToDisplay)
  let lastFrame = self.frames[lastFrameIndex]
  let lastFrameTime = lastFrame.endTime - lastFrame.startTime

  let goodness = clamp(lastFrameTime / 16.0, 0.0, 1.0)
  let red = goodness.lerp(0.0, 255.0).clamp(0, 255)
  let green = goodness.lerp(255.0, 0.0).clamp(0, 255)
  let color = rgb(red.int, green.int, 0)

  performanceCanvasContext.clearRect(barWidth * lastFrameIndex.float, 0.0, barWidth, height)

  let numEvents = lastFrame.events.len
  var yPos = 0.0
  for i, event in lastFrame.events:
    let barHeight = (event.timeSpent / (16.0 * 2.0)) * height
    performanceCanvasContext.fillStyle = $color
    performanceCanvasContext.strokeStyle = cstring("#555555")
    performanceCanvasContext.lineWidth = 1.0
    let x = barWidth * lastFrameIndex.float
    let y = height - barHeight - yPos
    performanceCanvasContext.fillRect(x, y, barWidth, barHeight)
    performanceCanvasContext.strokeRect(x, y, barWidth, barHeight)
    yPos += barHeight
  # Render 60fps line
  performanceCanvasContext.fillStyle = cstring("#004400")
  performanceCanvasContext.fillRect(0.0, height / 2.0, width, 1.0)

  if self.hoveredFrame > 0 and self.hoveredFrame < numFramesToDisplay:
    let hoveredFrame = self.frames[self.hoveredFrame]
    if not isNil(hoveredFrame):

      var summarizedEvents = initTable[cstring, float]()
      for event in hoveredFrame.events:
        summarizedEvents.mgetorput(event[0], 0.0) += event[1]
      let numLabels = summarizedEvents.len

      const lineHeight = 22.0

      performanceCanvasContext.fillStyle = cstring("#ffffff")
      performanceCanvasContext.fillRect(width, 0.0, textPanelWidth, max(textPanelHeight, lineHeight * numLabels + 10.0))

      performanceCanvasContext.textBaseline = cstring("top")
      performanceCanvasContext.textAlign = cstring("left")
      performanceCanvasContext.font = cstring("18.0px serif")
      performanceCanvasContext.fillStyle = cstring("#000000ff")
      var yPos = 5.0
      performanceCanvasContext.fillText(&"Frame: {self.hoveredFrame}", width + 5.0, yPos)
      yPos += lineHeight
      for label, timeSpent in summarizedEvents:
        performanceCanvasContext.fillText(&"{label}: {$timeSpent:3.3}", width + 5.0, yPos)
        yPos += lineHeight

      let hoveredFrameTime = hoveredFrame.endTime - hoveredFrame.startTime
      performanceCanvasContext.fillText(&"Total: {hoveredFrameTime:3.3}", width + 5.0, yPos)


proc drawPerformance*(self: Performance, ctx: CanvasContext2d): void =
  self.drawLastFrame()
  ctx.fillStyle = "#fefefe"
  ctx.fillRect(self.pos.x, self.pos.y, width, height)
  ctx.drawImage(performanceCanvas, self.pos.x, self.pos.y)

let perf* = newPerformance(zero())
