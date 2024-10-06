import
  ../../src/shade,
  sdl2_nim/sdl_gpu

const
  width = 800
  height = 600

initEngineSingleton("Water shader example", width, height)
let layer = newLayer()
Game.scene.addLayer layer

# Load a shader
const
  fragShaderPath = "./examples/shaders/water.frag"
  vertShaderPath = "./examples/shaders/common.vert"

let (_, image) = Images.loadImage("./examples/assets/images/default.png")

let shaderProgram = newShader(vertShaderPath, fragShaderPath)

type Rectangle = ref object of Node

Rectangle.renderAsNodeChild:
  blitScale(
    image,
    nil,
    ctx,
    gamestate.resolution.x / 2,
    gamestate.resolution.y / 2,
    16,
    16,
  )

let bg = Rectangle(shader: shaderProgram)
initNode(Node bg, RENDER)
layer.addChild(bg)

Input.onKeyPressed(K_ESCAPE):
  Game.stop()

Game.start()

