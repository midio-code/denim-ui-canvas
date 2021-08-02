import denim_ui
import tables
import canvas
import jsMap
import hashes
import strformat
import math

type
  Cache = ref object
    canvas: Canvas
    size: Size
    currentPos: Point
    currentLineHeight: float
    cacheBounds: JsMap[Hash, Bounds]

const cacheSize = 4096.0
proc newCache(): Cache =
  let canvas = createCanvas()
  canvas.width = cacheSize
  canvas.height = cacheSize
  Cache(
    canvas: canvas,
    size: vec2(cacheSize),
    currentPos: zero(),
    currentLineHeight: 0.0,
    cacheBounds: newJsMap[Hash, Bounds]()
  )

proc context(cache: Cache): CanvasContext2d =
  cache.canvas.getContext2d()

var caches = newCache()

const padding = 4.0

proc findNextAvailableCachePosition(cache: Cache, bounds: Bounds): Point =
  ## Finds a position in the cache that can accomodate `bounds`
  var pos = cache.currentPos.copy()

  cache.currentLineHeight = max(cache.currentLineHeight, bounds.size.y).ceil()

  let widthLeft = cache.size.x - cache.currentPos.x
  if widthLeft < bounds.size.x:
    pos.x = 0.0
    pos.y += cache.currentLineHeight + padding
    cache.currentLineHeight = bounds.size.y.ceil()
    cache.currentPos = pos.copy()
  else:
    cache.currentPos.x += bounds.size.x.ceil() + padding

  let heightLeft = cache.size.y - cache.currentPos.y
  if heightLeft < bounds.size.y:
    # NOTE: We must evict something from the cache
    raise newException(Exception, &"Cache is full")
  vec2(pos.x.ceil(), pos.y.ceil())

proc getCacheContextForPrimitive*(p: Primitive): CanvasContext2d =
  let cache = caches
  let ctx = cache.context
  let bounds = rect(zero(), p.bounds.size)
  let pos = cache.findNextAvailableCachePosition(bounds)

  cache.cacheBounds[p.id] = rect(pos.copy(), bounds.size)

  ctx.setTransform(1.0, 0.0, 0.0, 1.0, pos.x, pos.y)

  ctx.save()
  ctx.strokeStyle = "#ff0000"
  ctx.lineWidth = 2.0
  ctx.strokeRect(0.0, 0.0, bounds.size.x, bounds.size.y)
  ctx.restore()


  ctx

proc isCached*(p: Primitive): bool =
  p.id in caches.cacheBounds

proc drawFromCache*(ctx: CanvasContext2d, p: Primitive): void =
  assert(p.isCached)
  let cache = caches
  let bounds = cache.cacheBounds[p.id]
  let
    pos = bounds.pos.copy()
    size = bounds.size.copy()

  ctx.drawImage(cache.canvas, pos.x, pos.y, size.x, size.y, 0.0, 0.0, size.x, size.y)
