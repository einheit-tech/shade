import sdl2_nim/sdl_gpu

import ../math/mathutils

type Shader* = ref object
  programID: uint32
  vertShaderID: uint32
  fragShaderID: uint32
  shaderBlock: ShaderBlock

  # Uniforms
  timeUniformID: cint
  resolutionUniformID: cint

proc initShader*(shader: Shader, vertShaderPath, fragShaderPath: string) =
  shader.vertShaderID = loadShader(VERTEX_SHADER, vertShaderPath)
  if shader.vertShaderID == 0:
    raise newException(Exception, $getShaderMessage())

  shader.fragShaderID = loadShader(FRAGMENT_SHADER, fragShaderPath)
  if shader.fragShaderID == 0:
    raise newException(Exception, $getShaderMessage())

  shader.programID = linkShaders(shader.vertShaderID, shader.fragShaderID)
  if shader.programID == 0:
    raise newException(Exception, $getShaderMessage())

  shader.shaderBlock = loadShaderBlock(
    shader.programID,
    # TODO: These names seem hard-coded in sdl_gpu?
    "gpu_Vertex",
    "gpu_TexCoord",
    "gpu_Color",
    "gpu_ModelViewProjectionMatrix"
  )

  shader.timeUniformID = getUniformLocation(shader.programID, "time")
  shader.resolutionUniformID = getUniformLocation(shader.programID, "resolution")

proc newShader*(vertShaderPath, fragShaderPath: string): Shader =
  result = Shader()
  initShader(result, vertShaderPath, fragShaderPath)

proc updateTimeUniform*(this: Shader, time: float) =
  setUniformf(this.timeUniformID, cfloat time)

proc updateResolutionUniform(this: Shader, screenResolution: var Vector) =
  setUniformfv(this.resolutionUniformID, 2, 1, cast[ptr cfloat](screenResolution.addr))

proc render*(this: Shader, time: float, screenResolution: var Vector) =
  activateShaderProgram(this.programID, this.shaderBlock.addr)
  this.updateTimeUniform(time)
  this.updateResolutionUniform(screenResolution)

