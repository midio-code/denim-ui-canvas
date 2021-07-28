import webgl
import webgl/consts
import dom
import denim_ui
import random
import math

type
  ShaderKind = enum
    Vertex, Fragment

var globalScale = vec2(1.0)
var viewportSize = vec2(500.0, 500.0)

proc setSize*(self: WebGLRenderingContext, size: Size): void =
  echo "Setting size: ", size
  viewportSize = size

var vertexPositionAttribute : uint

proc checkCompileStatus(gl: WebGLRenderingContext, shader: WebGLShader): void =
  {.emit: "if (!`gl`.getShaderParameter(`shader`, `gl`.COMPILE_STATUS)) {alert('An error occurred compiling the shaders: ' + `gl`.getShaderInfoLog(`shader`));return null;}; ".}

proc checkLinkStatus(gl: WebGLRenderingContext, program: WebGLProgram): void =
  {.emit: "if (!`gl`.getShaderParameter(`program`, `gl`.LINK_STATUS)) {alert('An error occurred linking the shaders: ' + `gl`.getShaderInfoLog(`program`));return null;}; ".}

proc createShader(gl: WebGLRenderingContext, script: string, kind: ShaderKind): WebGLShader =
  case kind:
    of ShaderKind.Fragment:
      result = gl.createShader(seFRAGMENT_SHADER)
    of ShaderKind.Vertex:
      result = gl.createShader(seVERTEX_SHADER)

  gl.shaderSource(result, script)
  gl.compileShader(result)
  gl.checkCompileStatus(result)

var shaderProgram : WebGLProgram
proc clear*(gl: WebGLRenderingContext) =
  gl.clearColor(1.0, 0.0, 1.0, 1.0)
  gl.clearDepth(1.0)
  gl.clear(bbCOLOR.uint or bbDEPTH.uint)

proc initShaders(gl: WebGLRenderingContext): WebGLProgram =
  if not isNil(shaderProgram):
    return shaderProgram
  const vertexShaderSource =
    """
      attribute vec2 aVertexPosition;

      // Per instance attributes
      attribute vec2 pos;
      attribute vec2 size;
      attribute vec4 fill;
      attribute vec4 stroke;
      attribute float strokeWidth;
      attribute vec4 radius;

      uniform vec2 canvasSize;
      uniform vec2 scale;

      varying vec2 vert_pos;

      varying vec2 f_pos;
      varying vec2 f_size;
      varying vec4 f_fill;
      varying vec4 f_stroke;
      varying float f_strokeWidth;
      varying vec4 f_radius;

      void main() {
        vert_pos = aVertexPosition;
        vec2 normalized = (pos + (aVertexPosition * size)) * scale / canvasSize;
        vec2 corrected = normalized * 2.0 - 1.0;
        gl_Position = vec4(corrected.x, -corrected.y, 0.0, 1.0);
        f_pos = size * aVertexPosition;
        f_size = size;
        f_fill = fill;
        f_stroke = stroke;
        f_strokeWidth = strokeWidth;
        f_radius = radius;
      }
    """
  const fragmentShaderSource =
    """
      precision highp float;

      varying vec2 vert_pos;

      varying vec2 f_pos;
      varying vec2 f_size;
      varying vec4 f_fill;
      varying vec4 f_stroke;
      varying float f_strokeWidth;
      varying vec4 f_radius;

      float roundBox(vec2 p, vec2 b, vec4 r)
      {
          r.xy = (p.x>0.0)?r.xy : r.zw;
          r.x  = (p.y>0.0)?r.x  : r.y;
          vec2 q = abs(p)-b+r.x;
          return min(max(q.x,q.y),0.0) + length(max(q,0.0)) - r.x;
      }

      vec4 calcColor() {
        vec4 actualFillColor = vec4((f_fill / 255.0).xyz, 0.0);
        vec4 r = vec4(f_radius.x / f_size.x, f_radius.y / f_size.y, f_radius.z / f_size.x, f_radius.w / f_size.y);
        float dist = roundBox(((f_pos / f_size) * 2.0) - 1.0, vec2(1.0), r);
        if (dist <= 0.0001) {
           actualFillColor.a = f_fill.a;
        } else {
           actualFillColor.a = 0.0;
        }
        return actualFillColor;
      }

      void main() {
        gl_FragColor = calcColor();
      }
    """

  var vertexShader = createShader(gl, vertexShaderSource, ShaderKind.Vertex);
  var fragmentShader = createShader(gl, fragmentShaderSource, ShaderKind.Fragment)

  #Create shader programs
  shaderProgram = gl.createProgram()
  gl.attachShader(shaderProgram, vertexShader)
  gl.attachShader(shaderProgram, fragmentShader)
  gl.linkProgram(shaderProgram)

  gl.useProgram(shaderProgram)

  #gl.checkLinkStatus(shaderProgram)

  shaderProgram


proc `textBaseline=`*(gl: WebGLRenderingContext, baseline: cstring): void =
    discard

proc `font=`*(gl: WebGLRenderingContext, font: cstring): void =
    discard

proc scale*(gl: WebGLRenderingContext, x,y: float): void =
  globalScale = vec2(x,y)

proc clearRect*(gl: WebGLRenderingContext, l,r,w,h: float): void =
  discard

type
  BuffersObj = object
    attributes: seq[float]
    vertexSize: int
    numInstances: int
  Buffers = ref BuffersObj

proc draw(gl: WebGLRenderingContext, buffers: Buffers): void =
    let program = gl.initShaders()
    gl.useProgram(program)


    let positionsBuffer = gl.createBuffer()
    gl.bindBuffer(beARRAY_BUFFER, positionsBuffer)
    let vertices = [
      0.0, 0.0,
      1.0, 0.0,
      1.0, 1.0,
      0.0, 1.0,
    ]
    gl.bufferData(beARRAY_BUFFER, vertices, beSTATIC_DRAW)

    let indexBuffer = gl.createBuffer()
    gl.bindBuffer(beELEMENT_ARRAY_BUFFER, indexBuffer)
    let indices = [
      0'u16, 1'u16, 2'u16,
      0'u16, 2'u16, 3'u16
    ]
    gl.bufferData(beELEMENT_ARRAY_BUFFER, indices, beSTATIC_DRAW)

    let positionAttribLocation = gl.getAttribLocation(program, "aVertexPosition")
    gl.vertexAttribPointer(
      positionAttribLocation,
      2,
      FLOAT,
      false,
      0,
      0 # offset
    )
    gl.enableVertexAttribArray(
      positionAttribLocation
    )

    let attributesBuffer = gl.createBuffer()
    gl.bindBuffer(beARRAY_BUFFER, attributesBuffer)
    gl.bufferData(beARRAY_BUFFER, buffers.attributes, beSTATIC_DRAW)

    let posAttribLocation = gl.getAttribLocation(program, "pos")
    gl.vertexAttribPointer(
      posAttribLocation,
      2,
      FLOAT,
      false,
      17 * 4,
      0
    )
    let sizeAttribLocation = gl.getAttribLocation(program, "size")
    gl.vertexAttribPointer(
      sizeAttribLocation,
      2,
      FLOAT,
      false,
      17 * 4,
      2 * 4
    )
    let fillAttribLocation = gl.getAttribLocation(program, "fill")
    gl.vertexAttribPointer(
      fillAttribLocation,
      4,
      FLOAT,
      false,
      17 * 4,
      4 * 4
    )

    let strokeAttribLocation = gl.getAttribLocation(program, "stroke")
    gl.vertexAttribPointer(
      strokeAttribLocation,
      4,
      FLOAT,
      false,
      17 * 4,
      8 * 4
    )
    let strokeWidthAttribLocation = gl.getAttribLocation(program, "strokeWidth")
    gl.vertexAttribPointer(
      strokeWidthAttribLocation,
      1,
      FLOAT,
      false,
      17 * 4,
      12 * 4
    )
    let radiusAttribLocation = gl.getAttribLocation(program, "radius")
    gl.vertexAttribPointer(
      radiusAttribLocation,
      4,
      FLOAT,
      false,
      17 * 4,
      13 * 4
    )

    var ext = gl.getANGLEExtension()

    gl.enableVertexAttribArray(
      posAttribLocation
    )
    ext.vertexAttribDivisorANGLE(posAttribLocation, 1);

    gl.enableVertexAttribArray(
      sizeAttribLocation
    )
    ext.vertexAttribDivisorANGLE(sizeAttribLocation, 1);

    gl.enableVertexAttribArray(
      fillAttribLocation
    )
    ext.vertexAttribDivisorANGLE(fillAttribLocation, 1);

    gl.enableVertexAttribArray(
      strokeAttribLocation
    )
    ext.vertexAttribDivisorANGLE(strokeAttribLocation, 1);

    gl.enableVertexAttribArray(
      strokeWidthAttribLocation
    )
    ext.vertexAttribDivisorANGLE(strokeWidthAttribLocation, 1);

    gl.enableVertexAttribArray(
      radiusAttribLocation
    )
    ext.vertexAttribDivisorANGLE(radiusAttribLocation, 1);

    gl.viewport(0, 0, (viewportSize.x * globalScale.x).int, (viewportSize.y * globalScale.y).int)

    let sizeUniformLocation = gl.getUniformLocation(program, "canvasSize")
    gl.uniform2f(sizeUniformLocation, viewportSize.x, viewportSize.y)

    let scaleUniformLocation = gl.getUniformLocation(program, "scale")
    gl.uniform2f(scaleUniformLocation, globalScale.x, globalScale.y)

    ext.drawElementsInstancedANGLE(pmTriangles, 6, dtUNSIGNED_SHORT, 0, buffers.numInstances)

proc renderImpl(gl: WebGLRenderingContext, primitive: Primitive, offset: Size, buffers: var Buffers): void =
  case primitive.kind:
    of PrimitiveKind.Container:
      discard
    of PrimitiveKind.Path:
      discard
      # case p.pathInfo.kind:
      #   of PathInfoKind.Segments:
      #     discard
      #   of PathInfoKind.String:
      #     discard
    of PrimitiveKind.Text:
      discard
    of PrimitiveKind.Circle:
      discard
    of PrimitiveKind.Ellipse:
      discard
    of PrimitiveKind.Image:
      discard
    of PrimitiveKind.Rectangle:
      let
        ri = primitive.rectangleInfo
        b = primitive.bounds


      let ci = primitive.colorInfo.get
      var color = [0.0, 0.0, 0.0, 0.0]
      if ci.fill.isSome:
        let fill = ci.fill.get
        case fill.kind:
          of ColorStyleKind.Solid:
            let fillColor = fill.color
            color = [fillColor.r.float, fillColor.g.float, fillColor.b.float, fillColor.a.float]
          else:
            discard
      var strokeColor = [0.0, 0.0, 0.0, 0.0]
      if ci.stroke.isSome:
        let stroke = ci.stroke.get
        case stroke.kind:
          of ColorStyleKind.Solid:
            let sc = stroke.color
            strokeColor = [sc.r.float, sc.g.float, sc.b.float, sc.a.float]
          else:
            discard

      var strokeWidth = 0.0
      if primitive.strokeInfo.isSome:
        let si = primitive.strokeInfo.get
        strokeWidth = si.width

      var radius = [0.0, 0.0, 0.0, 0.0]
      if ri.radius.isSome:
        let r = ri.radius.get
        radius[0] = r.left
        radius[1] = r.top
        radius[2] = r.right
        radius[3] = r.bottom

      buffers.attributes &= @[
        offset.x + b.pos.x, offset.y + b.pos.y,
        b.size.x, b.size.y,
        color[0], color[1], color[2], color[3],
        strokeColor[0], strokeColor[1], strokeColor[2], strokeColor[3],
        strokeWidth,
        radius[0], radius[1], radius[2], radius[3],
      ]

      buffers.numInstances += 1

  for p in primitive.children:
    gl.renderImpl(p, offset + p.bounds.pos, buffers)

proc render*(gl: WebGLRenderingContext, primitive: Primitive): void =
  gl.enable(DEPTH_TEST)
  gl.depthFunc(LEQUAL)
  gl.clear(COLOR_BUFFER_BIT or DEPTH_BUFFER_BIT)

  var buffers = Buffers(
    attributes: newSeq[float](),
    numInstances: 0
  )
  gl.renderImpl(primitive, zero(), buffers)
  gl.draw(buffers)


proc save*(gl: WebGLRenderingContext): void =
  discard

proc restore*(gl: WebGLRenderingContext): void =
  discard

proc resetTransform*(gl: WebGLRenderingContext): void =
  discard

proc translate*(gl: WebGLRenderingContext, x, y: float): void =
  discard

proc `lineWidth=`*(gl: WebGLRenderingContext, width: float): void =
    discard

proc `fillStyle=`*(gl: WebGLRenderingContext, style: cstring): void =
    discard

proc `strokeStyle=`*(gl: WebGLRenderingContext, style: cstring): void =
    discard

proc renderPath*(gl: WebGLRenderingContext, data: cstring): void =
  discard

proc renderPath*(gl: WebGLRenderingContext, data: seq[PathSegment]): void =
  discard

proc isPointInStroke*(gl: WebGLRenderingContext, x, y: float): bool =
  false

proc initWebGL*(gl: WebGLRenderingContext): void =
  gl.clear()
  gl.enable(BLEND);
  gl.blendFunc(bmSRC_ALPHA.uint, bmONE_MINUS_SRC_ALPHA.uint);
