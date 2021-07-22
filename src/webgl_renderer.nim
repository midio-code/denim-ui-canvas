import webgl
import webgl/consts
import dom
import denim_ui
import random

type
  ShaderKind = enum
    Vertex, Fragment

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
  const vertexShaderSource =
    """
      attribute vec4 aVertexPosition;

      uniform vec2 canvasSize;

      varying vec2 pos;

      void main() {
        vec2 normalized = aVertexPosition.xy / canvasSize;
        vec2 corrected = normalized * 2.0 - 1.0;
        gl_Position = vec4(corrected.x, corrected.y, 0.0, 1.0);
        pos = gl_Position.xy;
      }
    """
  const fragmentShaderSource =
    """
      precision highp float;

      varying vec2 pos;

      void main() {
        gl_FragColor = vec4((pos.x + 1.0) / 2.0, (pos.y + 1.0) / 2.0, 0.0, 1.0);
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
  discard

proc clearRect*(gl: WebGLRenderingContext, l,r,w,h: float): void =
  discard

proc renderImpl(gl: WebGLRenderingContext, primitive: Primitive): void =
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
      echo "Rendering rect"
      let
        ri = primitive.rectangleInfo
        b = primitive.bounds
      # let vertices = [
      #   b.pos.x, b.pos.y + b.size.y,
      #   b.pos.x + b.size.x, b.pos.y + b.size.y,
      #   b.pos.x, b.pos.y,
      #   b.pos.x + b.size.x, b.pos.y,
      # ]
      # let vertices = [
      #     0.0, 40.0,
      #     379.0, 40.0,
      #     0.0, 0.0,
      #     379.0, 0.0
      #   ]

      let vertices = [
          0.0, 50.0,
          50.0, 50.0,
          0.0, 0.0,
          50.0, 0.0
        ]

      echo "Vertices: ", vertices
      # NOTE: Render with triangle fan
      let positionsBuffer = gl.createBuffer()
      gl.bindBuffer(beARRAY_BUFFER, positionsBuffer)

      gl.bufferData(beARRAY_BUFFER, vertices, beSTATIC_DRAW)

      let
        numComponents = 2
        `type` = FLOAT
        normalize = false
        stride = 0
        offset = 0

      let program = gl.initShaders()
      let positionAttribLocation = gl.getAttribLocation(program, "aVertexPosition")
      gl.vertexAttribPointer(
        positionAttribLocation,
        numComponents,
        `type`,
        normalize,
        stride,
        offset
      )
      gl.enableVertexAttribArray(
        positionAttribLocation
      )

      gl.useProgram(program)

      let sizeUniformLocation = gl.getUniformLocation(program, "canvasSize")


      let size = vec2(500.0, 500.0)
      gl.viewport(0, 0, size.x.int, size.y.int)
      gl.uniform2f(sizeUniformLocation, size.x, size.y)

      const vertexCount = 4
      #gl.drawArrays(pmTriangleFan, offset, vertexCount)
      gl.drawArrays(pmTriangleStrip, offset, vertexCount)


  for p in primitive.children:
    gl.renderImpl(p)

proc render*(gl: WebGLRenderingContext, primitive: Primitive): void =
  gl.enable(DEPTH_TEST)
  gl.depthFunc(LEQUAL)
  gl.clear(COLOR_BUFFER_BIT or DEPTH_BUFFER_BIT)
  gl.renderImpl(primitive)

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
