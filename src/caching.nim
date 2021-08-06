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
    currentTile*: int
    currentPosWithinTile*: Point
    currentLineHeight*: float
    cacheBounds*: JsMap[Hash, Bounds]
    cachedByTile*: JsMap[int, JsSet[Hash]]

const cacheSize* = 4096.0

# We divide the cache into n * n tiles, evicting one tile at the
# time as we need more cache space after the cache is full
const numTilesSqrt = 2
const numTiles = numTilesSqrt * numTilesSqrt
const tileSize = (cacheSize / numTilesSqrt.float).floor

# The padding shouold be dynamically determined to account for elements drawing outside its bounds
# but for now, we just hard code it to get something working for our use case.
# NOTE: The 0.5 makes sure we don't get a blurry result
const padding = 16.0

let tiles = [
  zero(),
  vec2(tileSize, 0.0),
  vec2(0.0, tileSize),
  vec2(tileSize, tileSize),
]

proc newCache(): Cache =
  let canvas = createCanvas()
  canvas.width = cacheSize
  canvas.height = cacheSize
  Cache(
    canvas: canvas,
    currentTile: 0,
    currentLineHeight: 0.0,
    currentPosWithinTile: vec2(padding),
    cacheBounds: newJsMap[Hash, Bounds](),
    cachedByTile: newJsMap[int, JsSet[Hash]]()
  )

proc context(cache: Cache): CanvasContext2d =
  cache.canvas.getContext2d()

# TODO: Rename this variable to just cache
var caches* = newCache()
var cacheTilesSpentThisFrame = 0

proc evictCachedItemsForTile(cache: Cache, tile: int) =
  assert(tile in cache.cachedByTile)
  let cachedByTile = cache.cachedByTile.mgetorput(tile, newJsSet[Hash]())
  for item in cachedByTile:
    cache.cacheBounds.delete(item)
  cache.cachedByTile[tile] = newJsSet[Hash]()

proc clearTile(cache: Cache) =
  let ctx = cache.context()
  let
    currentTileOffset = tiles[cache.currentTile]
    p = currentTileOffset
    s = tileSize
  ctx.setTransform(1.0, 0.0, 0.0, 1.0, 0.0, 0.0)
  ctx.clearRect(p.x, p.y, s, s)

proc advanceToNextTile(cache: Cache) =
  cache.currentTile = (cache.currentTile + 1) mod numTiles
  cache.currentPosWithinTile = vec2(padding)
  cache.evictCachedItemsForTile(cache.currentTile)
  cache.clearTile()
  cacheTilesSpentThisFrame += 1

proc claimCacheSpaceForBounds(cache: Cache, bounds: Bounds): Point =
  ## Finds a position in the cache that can accomodate `bounds` and claims it,
  ## potentially evicting the whole tile it is in.
  var pos = cache.currentPosWithinTile.copy()
  let paddedSize = bounds.size + vec2(padding * 2.0)

  let widthLeft = tileSize - cache.currentPosWithinTile.x
  if widthLeft < paddedSize.x.ceil():
    pos.x = padding
    pos.y += cache.currentLineHeight
    cache.currentLineHeight = bounds.size.y.ceil()
  else:
    cache.currentLineHeight = max(cache.currentLineHeight, paddedSize.y).ceil()

  let heightLeft = tileSize - pos.y
  if heightLeft < paddedSize.y.ceil():
    # NOTE: We must evict something from the cache
    cache.advanceToNextTile()
    pos = vec2(padding)
    cache.currentLineHeight = paddedSize.y

  cache.currentPosWithinTile = pos + vec2(paddedSize.x.ceil(), 0.0)
  result = vec2(pos.x.floor(), pos.y.floor()) + tiles[cache.currentTile]

proc isTooBigForCache(p: Primitive): bool =
  let paddedSize = p.bounds.size + vec2(padding * 2.0)
  paddedSize.x >= tileSize or paddedSize.y >= tileSize

proc tryGetCacheContextForPrimitive*(p: Primitive): Option[CanvasContext2d] =
  if cacheTilesSpentThisFrame >= numTiles or p.isTooBigForCache:
    # NOTE: If we've filled the entire cache this frame, we at least won't try to cache
    # any more this frame.
    return none[CanvasContext2d]()

  let cache = caches
  let bounds = rect(zero(), p.bounds.size)
  let pos = cache.claimCacheSpaceForBounds(bounds)

  cache.cacheBounds[p.id] = rect(pos.copy(), bounds.size)

  # NOTE: Caching an index for each tile so that we know which cache bounds to evict
  # when recycling a tile
  let cachedByTile = cache.cachedByTile.mgetorput(cache.currentTile, newJsSet[Hash]())
  cachedByTile.incl(p.id)

  let ctx = cache.context
  ctx.setTransform(1.0, 0.0, 0.0, 1.0, pos.x, pos.y)

  some(ctx)

proc isCached*(p: Primitive): bool =
  p.id in caches.cacheBounds

proc drawFromCache*(ctx: CanvasContext2d, p: Primitive): void =
  assert(p.isCached)
  let cache = caches
  let bounds = cache.cacheBounds[p.id]
  let
    pos = bounds.pos.copy() - vec2(padding)
    size = bounds.size.copy() + vec2(padding * 2.0)

  ctx.drawImage(cache.canvas, pos.x, pos.y, size.x, size.y, -padding, -padding, size.x, size.y)

proc beginCacheFrame*() =
  cacheTilesSpentThisFrame = 0
