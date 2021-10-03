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
king.scale = vec2(3.0, 3.0)
king.center = vec2(Game.screen.w.float / 2, Game.screen.h.float / 2)
layer.addChild(king)

# Load a shader
const
  fragShaderPath = "./examples/shaders/color.frag"
  vertShaderPath = "./examples/shaders/common.vert"

let shaderProgram = newShader(image, vertShaderPath, fragShaderPath)
king.shader = shaderProgram

Game.start()

