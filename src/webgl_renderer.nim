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
      attribute vec4 aVertexPosition;
      attribute vec4 fill;

      uniform vec2 canvasSize;

      varying vec2 pos;
      varying vec4 fillColor;

      void main() {
        vec2 normalized = aVertexPosition.xy / canvasSize;
        vec2 corrected = normalized * 2.0 - 1.0;
        gl_Position = vec4(corrected.x, -corrected.y, 0.0, 1.0);
        pos = gl_Position.xy;
        fillColor = fill;
      }
    """
  const fragmentShaderSource =
    """
      precision highp float;


      varying vec4 fillColor;
      varying vec2 pos;

      void main() {
        gl_FragColor = fillColor / 255.0;
      }
    """

  var vertexShader = createShader(gl, vertexShaderSource, ShaderKind.Vertex);
  var fragmentShader = createShader(gl, fragmentShaderSource, ShaderKind.Fragment)

  #Create shader programs
  shaderProgram = gl.createProgram()
  gl.attachShader(shaderProgram, vertexShader)
  gl.attachShader(shaderProgram, fragmentShader)
  gl.linkProgram(shaderProgram)

  #gl.checkLinkStatus(shaderProgram)

  gl.useProgram(shaderProgram)

  vertexPositionAttribute = gl.getAttribLocation(shaderProgram, "aVertexPosition")
  gl.enableVertexAttribArray(vertexPositionAttribute)

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
    vertices: seq[float]
    indices: seq[uint16]
    vertexSize: int
  Buffers = ref BuffersObj

proc draw(gl: WebGLRenderingContext, buffers: Buffers): void =
    let positionsBuffer = gl.createBuffer()
    gl.bindBuffer(beARRAY_BUFFER, positionsBuffer)
    gl.bufferData(beARRAY_BUFFER, buffers.vertices, beSTATIC_DRAW)

    let indexBuffer = gl.createBuffer()
    gl.bindBuffer(beELEMENT_ARRAY_BUFFER, indexBuffer)
    gl.bufferData(beELEMENT_ARRAY_BUFFER, buffers.indices, beSTATIC_DRAW)

    let
      `type` = FLOAT
      normalize = false
      stride = 6 * 4

    let program = gl.initShaders()
    let positionAttribLocation = gl.getAttribLocation(program, "aVertexPosition")
    gl.vertexAttribPointer(
      positionAttribLocation,
      2,
      `type`,
      normalize,
      stride,
      0
    )
    let fillAttribLocation = gl.getAttribLocation(program, "fill")
    gl.vertexAttribPointer(
      fillAttribLocation,
      4,
      `type`,
      normalize,
      stride,
      2 * 4
    )
    gl.enableVertexAttribArray(
      positionAttribLocation
    )
    gl.enableVertexAttribArray(
      fillAttribLocation
    )

    gl.useProgram(program)

    let sizeUniformLocation = gl.getUniformLocation(program, "canvasSize")


    gl.viewport(0, 0, viewportSize.x.int, viewportSize.y.int)
    gl.uniform2f(sizeUniformLocation, viewportSize.x, viewportSize.y)


    gl.drawElements(pmTriangles, indices.numElements.uint16, dtUNSIGNED_SHORT, 0)

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
      buffers.vertices &= @[
        offset.x + b.pos.x,
        offset.y + b.pos.y + b.size.y,

        color[0], color[1], color[2], color[3],

        offset.x + b.pos.x + b.size.x,
        offset.y + b.pos.y + b.size.y,

        color[0], color[1], color[2], color[3],

        offset.x + b.pos.x,
        offset.y + b.pos.y,

        color[0], color[1], color[2], color[3],

        offset.x + b.pos.x + b.size.x,
        offset.y + b.pos.y,

        color[0], color[1], color[2], color[3],
      ]
      let indexOffset = (buffers.vertices.len / buffers.vertexSize).floor.uint16
      buffers.indices &= @[
        indexOffset + 0'u16,
        indexOffset + 1'u16,
        indexOffset + 2'u16,
        indexOffset + 2'u16,
        indexOffset + 1'u16,
        indexOffset + 3'u16
      ]

  for p in primitive.children:
    gl.renderImpl(p, offset + p.bounds.pos, buffers)

proc render*(gl: WebGLRenderingContext, primitive: Primitive): void =
  gl.enable(DEPTH_TEST)
  gl.depthFunc(LEQUAL)
  gl.clear(COLOR_BUFFER_BIT or DEPTH_BUFFER_BIT)

  var buffers = Buffers(
    vertices: newSeq[float](),
    indices: newSeq[uint16](),
    vertexSize: 6,
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
