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

let shaderProgram = newShader(vertShaderPath, fragShaderPath)

type Background = ref object of Entity

Background.renderAsEntityChild:
  ctx.rectangleFilled(
    0,
    0,
    gamestate.resolution.x,
    gamestate.resolution.y,
    WHITE
  )

let bg = Background(shader: shaderProgram)
initEntity(Entity bg, RENDER)
layer.addChild(bg)

Input.onKeyPressed(K_ESCAPE):
  Game.stop()

Game.start()

