import jsffi
import dom
import tables
import strformat
import canvas
import math
import colors
import denim_ui
import jsMap

var console {.importc, nodecl.}: JsObject

const width = 600.0
const height = 130.0
const textPanelWidth = 250.0
const textPanelHeight = height * 3.0
const numFramesToDisplay = 120

proc lerp(t, a, b: float): float =
  return a + t * (b - a);

var performance {.importc, nodecl.}: dom.Performance

type
  EventKind = enum
    Tick, Tock
  Event = ref object
    kind: EventKind
    time: float

  Frame = ref object
    startTime: float
    endTime: float
    events: seq[tuple[label: cstring, event: Event]]
    counters: JsMap[cstring, int]

  Performance* = ref object
    stopped: bool
    pos: Point
    hoveredFrame: int
    currentFrame: int
    frames: array[numFramesToDisplay,Frame]

proc newPerformance*(pos: Point): Performance =
  Performance(
    stopped: false,
    pos: pos,
    hoveredFrame: -1,
    currentFrame: 0
  )

proc summarizeFrame(frame: Frame): JsMap[cstring, float] =
  var summarizedEvents = newJsMap[cstring, float]()
  for event in frame.events:
    let
      label = event[0]
      ev = event[1]
    if label notin summarizedEvents:
      summarizedEvents.set(label, 0.0)
    if ev.kind == EventKind.Tick:
      summarizedEvents.set(label, summarizedEvents.get(label) - ev.time)
    else:
      summarizedEvents.set(label, summarizedEvents.get(label) + ev.time)
  summarizedEvents

proc tickImpl(self: Performance, label: cstring): void =
  if self.stopped:
    return

  let time = performance.now()
  self.frames[self.currentFrame].events.add(
    (label, Event(kind: EventKind.Tick, time: time))
  )

template tick*(self: Performance, label: cstring): void =
  when defined(visualize_performance):
    tickImpl(self, label)

proc tockImpl(self: Performance, label: cstring): void =
  if self.stopped:
    return

  self.frames[self.currentFrame].events.add(
    (label, Event(kind: EventKind.Tock, time: performance.now()))
  )

template tock*(self: Performance, label: cstring): void =
  when defined(visualize_performance):
    tockImpl(self, label)

proc countImpl(self: Performance, label: cstring): void =
  if isNil(self.frames[self.currentFrame]):
    return
  let cf = self.frames[self.currentFrame]
  if label notin cf.counters:
    cf.counters[label] = 0
  cf.counters[label] = cf.counters[label] + 1

template count*(self: Performance, label: cstring): void =
  when defined(visualize_performance):
    countImpl(self, label)

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
    events: newSeqOfCap[(cstring, Event)](100),
    counters: newJsMap[cstring, int]()
  )

proc endFrame*(self: Performance): void =
  if self.stopped:
    return
  self.frames[self.currentFrame].endTime = performance.now()
  if self.currentFrame == numFramesToDisplay - 1:
    let completeSummarization = newJsMap[cstring, float]()
    for frame in self.frames:
      let summarized = summarizeFrame(frame)
      for label, time in summarized:
        if label notin completeSummarization:
          completeSummarization.set(label, 0.0)
        completeSummarization.set(label, completeSummarization.get(label) + time)
    # echo "Average of past 120 frames:"
    # for label, time in completeSummarization:
    #   echo &"   {label}: {time / numFramesToDisplay.float}"

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

  var summarizedEvents = summarizeFrame(lastFrame)

  let timeSpent = lastFrame.endTime - lastFrame.startTime
  let barHeight = (timeSpent / (16.0 * 2.0)) * height

  performanceCanvasContext.fillStyle = $color
  performanceCanvasContext.strokeStyle = cstring("#555555")
  performanceCanvasContext.lineWidth = 1.0
  let x = barWidth * lastFrameIndex.float
  let y = height - barHeight - yPos
  performanceCanvasContext.fillRect(x, y, barWidth, barHeight)
  performanceCanvasContext.strokeRect(x, y, barWidth, barHeight)

  # Render 60fps line
  performanceCanvasContext.fillStyle = cstring("#004400")
  performanceCanvasContext.fillRect(0.0, height / 2.0, width, 1.0)

  if self.hoveredFrame > 0 and self.hoveredFrame < numFramesToDisplay:
    let hoveredFrame = self.frames[self.hoveredFrame]
    if not isNil(hoveredFrame):
      var summarizedEvents = summarizeFrame(hoveredFrame)
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
        performanceCanvasContext.fillText(&"{label}: {$timeSpent:3.3}ms", width + 5.0, yPos)
        yPos += lineHeight
      for label, count in hoveredFrame.counters:
        performanceCanvasContext.fillText(&"{label}: {$count}", width + 5.0, yPos)
        yPos += lineHeight

      let hoveredFrameTime = hoveredFrame.endTime - hoveredFrame.startTime
      performanceCanvasContext.fillText(&"Total: {hoveredFrameTime:3.3}", width + 5.0, yPos)


proc drawPerformance*(self: Performance, ctx: CanvasContext2d): void =
  self.drawLastFrame()
  ctx.fillStyle = "#fefefe"
  ctx.fillRect(self.pos.x, self.pos.y, width, height)
  ctx.drawImage(performanceCanvas, self.pos.x, self.pos.y)


let perf* = newPerformance(zero())
