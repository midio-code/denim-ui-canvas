import webgl
import dom
import denim_ui

type
  ShaderKind = enum
    Vertex, Fragment

var vertexPositionAttribute : uint

proc checkCompileStatus(): void =
  {.emit: "if (!`gl`.getShaderParameter(`result`, `gl`.COMPILE_STATUS)) {alert('An error occurred compiling the shaders: ' + `gl`.getShaderInfoLog(`result`));return null;}; ".}

proc createShader(gl: WebGLRenderingContext, script: string, kind: ShaderKind): WebGLShader =
  case kind:
    of ShaderKind.Fragment:
      result = gl.createShader(seFRAGMENT_SHADER)
    of ShaderKind.Vertex:
      result = gl.createShader(seVERTEX_SHADER)

  gl.shaderSource(result, script)
  gl.compileShader(result)
  checkCompileStatus()

var shaderProgram : WebGLProgram
proc clear*(gl: WebGLRenderingContext) =
  gl.clearColor(1.0, 0.0, 1.0, 1.0)
  gl.clearDepth(1.0)
  gl.clear(bbCOLOR.uint or bbDEPTH.uint)

proc initShaders(gl: WebGLRenderingContext): void =
  var fragmentShader = createShader(gl, "shader-fs", ShaderKind.Fragment)
  var vertexShader = createShader(gl, "shader-vs", ShaderKind.Vertex);

  #Create shader programs
  shaderProgram = gl.createProgram()
  gl.attachShader(shaderProgram,vertexShader)
  gl.attachShader(shaderProgram,fragmentShader)
  gl.linkProgram(shaderProgram)

  # If creating the shader program failed, alert
  # I'm lazy so I'll just emit this directly
  #  {.emit : "if (!`gl`.getProgramParameter(`shaderProgram`, `gl`.LINK_STATUS)) { alert('Unable to initialize the shader program: ' + `gl`.getProgramInfoLog(`shader`)); };" .}

  gl.useProgram(shaderProgram)

  vertexPositionAttribute = gl.getAttribLocation(shaderProgram, "aVertexPosition");
  gl.enableVertexAttribArray(vertexPositionAttribute);


proc initWebGL*(gl: WebGLRenderingContext): void =
  gl.clear()
