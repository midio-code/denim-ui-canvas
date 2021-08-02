import denim_ui
import tables
import canvas
import jsMap
import jsSet
import hashes
import strformat
import math

type
  Cache = ref object
    canvas*: Canvas
    currentZone*: int
    currentPosWithinZone*: Point
    currentLineHeight*: float
    cacheBounds*: JsMap[Hash, Bounds]
    cachedByZone*: JsMap[int, JsSet[Hash]]

const cacheSize* = 2048.0
# We divide the cache into n * n zones, evicting one zone at the
# time as we need more cache space after the cache is full
const numZonesSqrt = 2
const numZones = numZonesSqrt * numZonesSqrt
const zoneSize = (cacheSize / numZonesSqrt.float).floor

let zones = [
  rect(zero(), vec2(zoneSize)),
  rect(vec2(zoneSize, 0.0), vec2(zoneSize)),
  rect(vec2(0.0, zoneSize), vec2(zoneSize)),
  rect(vec2(zoneSize, zoneSize), vec2(zoneSize)),
]

proc newCache(): Cache =
  let canvas = createCanvas()
  canvas.width = cacheSize
  canvas.height = cacheSize
  Cache(
    canvas: canvas,
    currentZone: 0,
    currentLineHeight: 0.0,
    currentPosWithinZone: zero(),
    cacheBounds: newJsMap[Hash, Bounds](),
    cachedByZone: newJsMap[int, JsSet[Hash]]()
  )

proc context(cache: Cache): CanvasContext2d =
  cache.canvas.getContext2d()

# TODO: Rename this variable to just cache
var caches* = newCache()

const padding = 4.0

proc evictCachedItemsForZone(cache: Cache, zone: int) =
  assert(zone in cache.cachedByZone)
  let cachedByZone = cache.cachedByZone.mgetorput(zone, newJsSet[Hash]())
  for item in cachedByZone:
    cache.cacheBounds.delete(item)
  cache.cachedByZone[zone] = newJsSet[Hash]()

proc clearZone(cache: Cache) =
  let ctx = cache.context()
  let
    currentZoneBounds = zones[cache.currentZone]
    p = currentZoneBounds.pos
    s = currentZoneBounds.size
  ctx.setTransform(1.0, 0.0, 0.0, 1.0, 0.0, 0.0)
  ctx.clearRect(p.x, p.y, s.x, s.y)

proc advanceToNextZone(cache: Cache) =
  cache.currentZone = (cache.currentZone + 1) mod numZones
  cache.currentPosWithinZone = zero()
  cache.evictCachedItemsForZone(cache.currentZone)
  cache.clearZone()
  cache.currentPosWithinZone = zero()

proc findNextAvailableCachePosition(cache: Cache, bounds: Bounds): Point =
  ## Finds a position in the cache that can accomodate `bounds`
  var pos = cache.currentPosWithinZone.copy()

  cache.currentLineHeight = max(cache.currentLineHeight, bounds.size.y).ceil()

  let widthLeft = zoneSize - cache.currentPosWithinZone.x
  if widthLeft < bounds.size.x + padding:
    pos.x = 0.0
    pos.y += cache.currentLineHeight + padding
    cache.currentLineHeight = bounds.size.y.ceil()
    cache.currentPosWithinZone = pos.copy()
  else:
    cache.currentPosWithinZone.x += bounds.size.x.ceil() + padding

  let heightLeft = zoneSize - cache.currentPosWithinZone.y
  if heightLeft < bounds.size.y + padding:
    # NOTE: We must evict something from the cache
    cache.advanceToNextZone()
  vec2(pos.x.ceil(), pos.y.ceil()) + zones[cache.currentZone].pos

proc getCacheContextForPrimitive*(p: Primitive): CanvasContext2d =
  let cache = caches
  let bounds = rect(zero(), p.bounds.size)
  let pos = cache.findNextAvailableCachePosition(bounds)

  cache.cacheBounds[p.id] = rect(pos.copy(), bounds.size)

  # NOTE: Caching an index for each zone so that we know which cache bounds to evict
  # when recycling a zone
  let cachedByZone = cache.cachedByZone.mgetorput(cache.currentZone, newJsSet[Hash]())
  cachedByZone.incl(p.id)

  let ctx = cache.context
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
