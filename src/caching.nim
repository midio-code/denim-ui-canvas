import denim_ui
import tables
import canvas
import jsMap
import hashes
import strformat

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

proc findNextAvailableCachePosition(cache: Cache, bounds: Bounds): Point =
  ## Finds a position in the cache that can accomodate `bounds`
  var pos = cache.currentPos.copy()

  cache.currentLineHeight = max(cache.currentLineHeight, bounds.size.y)

  let widthLeft = cache.size.x - cache.currentPos.x
  if widthLeft < bounds.size.x:
    pos.x = 0
    pos.y += cache.currentLineHeight
    cache.currentPos = pos
  else:
    cache.currentPos.x += bounds.size.x

  let heightLeft = cache.size.y - cache.currentPos.y
  if heightLeft < bounds.size.y:
    # NOTE: We must evict something from the cache
    raise newException(Exception, &"Cache is full")
  pos

proc getCacheContextForPrimitive*(p: Primitive, scale: Vec2[float]): CanvasContext2d =
  let cache = caches
  let ctx = cache.context
  ctx.restore()
  let scaledBounds = rect(zero(), p.bounds.size * scale)
  let pos = cache.findNextAvailableCachePosition(scaledBounds)
  cache.cacheBounds[p.id] = rect(pos, scaledBounds.size)
  ctx.save()
  ctx.translate(pos.x, pos.y)
  ctx.scale(scale.x, scale.y)
  ctx

proc isCached*(p: Primitive): bool =
  p.id in caches.cacheBounds

proc drawFromCache*(ctx: CanvasContext2d, p: Primitive): void =
  assert(p.isCached)
  let cache = caches
  let bounds = cache.cacheBounds[p.id]
  let
    pos = bounds.pos
    size = bounds.size
  ctx.drawImage(cache.canvas, pos.x, pos.y, size.x, size.y, 0.0, 0.0, size.x, size.y)
