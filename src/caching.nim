import denim_ui
import tables
import canvas

var textCache* = createCanvas()
textCache.width = 1024
textCache.height = 1024

var textCachePositions* = initTable[TextInfo, Bounds]()
var currentCachePos* = zero()
var currentCacheLineHeight* = 0.0

#proc cachePrimitive*(p: Primitive): void =
