import jsffi
import dom
import tables
import strformat
import canvas
import math
import colors
import denim_ui

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
    currentTicks: Table[cstring, float]
    currentFrame: int
    frames: array[120,Frame]

proc newPerformance*(pos: Point): Performance =
  Performance(
    pos: pos,
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
const width = 300.0
const height = 100.0
performanceCanvas.width = width
performanceCanvas.height = height

let performanceCanvasContext = performanceCanvas.getContext2d()

proc beginFrame*(self: Performance): void =
  self.frames[self.currentFrame] = Frame(
    startTime: performance.now(),
    events: @[]
  )

proc endFrame*(self: Performance): void =
  self.frames[self.currentFrame].endTime = performance.now()
  self.currentFrame = floorMod(self.currentFrame + 1, 120)

proc onMouseMove*(self: Performance, x, y: float): void =
  discard

proc drawLastFrame(self: Performance): void =
  const barWidth = width / 120.0
  let lastFrameIndex = floorMod(self.currentFrame - 1, 120)
  let lastFrame = self.frames[lastFrameIndex]
  let lastFrameTime = lastFrame.endTime - lastFrame.startTime
  let barHeight = (lastFrameTime / (16.0 * 2.0)) * height

  let goodness = clamp(lastFrameTime / 16.0, 0.0, 1.0)
  let red = goodness.lerp(0.0, 255.0).clamp(0, 255)
  let green = goodness.lerp(255.0, 0.0).clamp(0, 255)
  let color = rgb(red.int, green.int, 0)

  performanceCanvasContext.clearRect(barWidth * lastFrameIndex.float, 0.0, barWidth, height)
  performanceCanvasContext.fillStyle = $color
  performanceCanvasContext.fillRect(barWidth * lastFrameIndex.float, height - barHeight, barWidth, barHeight)
  performanceCanvasContext.fillStyle = "#004400"
  performanceCanvasContext.fillRect(0.0, height / 2.0, width, 1.0)

proc drawPerformance*(self: Performance, ctx: CanvasContext2d): void =
  self.drawLastFrame()
  ctx.fillStyle = "#fefefe"
  ctx.fillRect(self.pos.x, self.pos.y, width, height)
  ctx.drawImage(performanceCanvas, self.pos.x, self.pos.y)
