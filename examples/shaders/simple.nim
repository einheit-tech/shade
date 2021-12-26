import
  ../../src/shade,
  sdl2_nim/sdl_gpu

const
  width = 1920
  height = 1080

initEngineSingleton("Basic Example Game", width, height)
let layer = newLayer()
Game.scene.addLayer layer

let (_, image) = Images.loadImage("./examples/assets/images/king.png")
image.setImageFilter(FILTER_NEAREST)

let king = newSprite(image, 11, 8)
king.scale = vector(10, 10)
king.center = vector(width / 2, height / 2) * pixelToMeterScalar
layer.addChild(king)

# Load a shader
const
  fragShaderPath = "./examples/shaders/water.frag"
  vertShaderPath = "./examples/shaders/common.vert"

let shaderProgram = newShader(vertShaderPath, fragShaderPath)
king.shader = shaderProgram

Game.start()

