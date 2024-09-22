import
  ../../src/shade,
  sdl2_nim/sdl_gpu

const
  width = 800
  height = 600

initEngineSingleton("Rectangle Shader", width, height)
let layer = newLayer()
Game.scene.addLayer layer

# Load a shader
const
  fragShaderPath = "./examples/shaders/rectangle.frag"
  vertShaderPath = "./examples/shaders/common.vert"

let shaderProgram = newShader(vertShaderPath, fragShaderPath)

type Background = ref object of Entity

Background.renderAsEntityChild:
  ctx.rectangleFilled(
    10,
    10,
    50,
    50,
    WHITE
  )

let bg = Background(shader: shaderProgram)
initNode(Entity bg, RENDER)
layer.addChild(bg)

Input.onKeyEvent(K_ESCAPE):
  Game.stop()

Game.start()

