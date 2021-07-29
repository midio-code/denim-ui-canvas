import jsffi
import dom
import tables
import strformat
import canvas
import math
import colors
import denim_ui

const width = 600.0
const height = 130.0
const textPanelWidth = 200.0
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
    pos: Point
    hoveredFrame: int
    currentTicks: Table[cstring, float]
    currentFrame: int
    frames: array[numFramesToDisplay,Frame]

proc newPerformance*(pos: Point): Performance =
  Performance(
    pos: pos,
    hoveredFrame: -1,
    currentTicks: initTable[cstring, float](),
    currentFrame: 0
  )

proc tick*(self: Performance, label: cstring): void =
  self.currentTicks[label] = performance.now()

proc tock*(self: Performance, label: cstring): void =
  let n = performance.now()
  if label notin self.currentTicks:
    raise newException(Exception, &"No matching label for performance 'tock' {label}")

  let last = self.currentTicks[label]
  let timeSpentSinceTick = n - last
  self.currentTicks.del(label)
  self.frames[self.currentFrame].events.add((label, timeSpentSinceTick))


var performanceCanvas = createCanvas()
performanceCanvas.width = width + textPanelWidth
performanceCanvas.height = height

let performanceCanvasContext = performanceCanvas.getContext2d()

proc beginFrame*(self: Performance): void =
  self.frames[self.currentFrame] = Frame(
    startTime: performance.now(),
    events: @[]
  )

proc endFrame*(self: Performance): void =
  self.frames[self.currentFrame].endTime = performance.now()
  self.currentFrame = floorMod(self.currentFrame + 1, numFramesToDisplay)

proc onMouseMove*(self: Performance, x, y: float): void =
  if x >= self.pos.x and x < self.pos.x + width and y >= self.pos.y and y <= self.pos.y + height:
    let barWidth = width / numFramesToDisplay
    let frameIndex = ((x - self.pos.x) / barWidth).floor().int
    self.hoveredFrame = frameIndex
  else:
    self.hoveredFrame = -1

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
    performanceCanvasContext.strokeStyle = "#555555"
    performanceCanvasContext.lineWidth = 1.0
    let x = barWidth * lastFrameIndex.float
    let y = height - barHeight - yPos
    performanceCanvasContext.fillRect(x, y, barWidth, barHeight)
    performanceCanvasContext.strokeRect(x, y, barWidth, barHeight)
    yPos += barHeight
  # Render 60fps line
  performanceCanvasContext.fillStyle = "#004400"
  performanceCanvasContext.fillRect(0.0, height / 2.0, width, 1.0)

  if self.hoveredFrame > 0 and self.hoveredFrame < numFramesToDisplay:
    let hoveredFrame = self.frames[self.hoveredFrame]
    if not isNil(hoveredFrame):
      performanceCanvasContext.fillStyle = "#ffffff"
      performanceCanvasContext.fillRect(width, 0.0, textPanelWidth, height)
      performanceCanvasContext.textBaseline = "top"
      performanceCanvasContext.textAlign = "left"
      performanceCanvasContext.font = "16.0px"
      performanceCanvasContext.fillStyle = "#000000ff"
      var yPos = 5.0
      for event in hoveredFrame.events:
        performanceCanvasContext.fillText(&"{event[0]}: {$event[1]}", width + 5.0, yPos)
        yPos += 20.0

      let hoveredFrameTime = hoveredFrame.endTime - hoveredFrame.startTime
      performanceCanvasContext.fillText(&"Total: {lastFrameTime}", width + 5.0, yPos)


proc drawPerformance*(self: Performance, ctx: CanvasContext2d): void =
  self.drawLastFrame()
  ctx.fillStyle = "#fefefe"
  ctx.fillRect(self.pos.x, self.pos.y, width, height)
  ctx.drawImage(performanceCanvas, self.pos.x, self.pos.y)
