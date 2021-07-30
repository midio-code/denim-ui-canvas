import denim_ui
import tables
import canvas
import jsMap
import hashes
import strformat
import drawing_primitives

type
  Cache = ref object
    canvas: Canvas
    size: Size
    currentPos: Point
    currentLineHeight: float
    cachePositions: JsMap[Hash, Bounds]

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
    cachePositions: newJsMap[Hash, Bounds]()
  )

proc context(cache: Cache): CanvasContext2d =
  cache.canvas.getContext2d()

var caches = newJsMap[PrimitiveKind, Cache]()

proc findNextAvailableCachePosition(cache: Cache, bounds: Bounds): Point =
  ## Finds a position in the cache that can accomodate `bounds`
  var pos = cache.currentPos

  let widthLeft = cache.size.x - cache.currentPos.x
  if widthLeft < bounds.size.x:
    pos.x = 0
    pos.y += cache.currentLineHeight

  let heightLeft = cache.size.y - cache.currentPos.y
  if heightLeft < bounds.size.y:
    # NOTE: We must evict something from the cache
    raise newException(Exception, &"Cache is full")

proc cachePrimitive*(p: Primitive): void =
  let cache = caches.mgetorput(p.kind, newCache())
  let ctx = cache.context
  let pos = cache.findNextAvailableCachePosition(p.bounds)
  ctx.translate(pos.x, pos.y)
  ctx.renderPrimitives(p)

proc isCached(p: Primitive): bool =
  p.kind in caches and p.id in caches[p.kind].cachePositions

proc drawFromCache*(ctx: CanvasContext2d, p: Primitive): void =
  assert(p.isCached)
  let cache = caches[p.kind]
  let pos = cache.cachePositions[p.id]
  let
    size = p.bounds.size
  ctx.drawImage(cache.canvas, pos.x, pos.y, size.x, size.y, 0.0, 0.0, size.x, size.y)
