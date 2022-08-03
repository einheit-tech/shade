import
  ../../src/shade,
  sdl2_nim/sdl_gpu

const
  width = 360
  height = 720

initEngineSingleton("Basic Example Game", width, height)
let layer = newLayer()
Game.scene.addLayer layer

# Load a shader
const
  fragShaderPath = "./examples/shaders/hexagons.frag"
  vertShaderPath = "./examples/shaders/common.vert"

let shaderProgram = newShader(vertShaderPath, fragShaderPath)


type Background = ref object of Node

Background.renderAsNodeChild:
  ctx.rectangleFilled(
    0,
    0,
    gamestate.resolution.x,
    gamestate.resolution.y,
    WHITE
  )

let bg = Background(shader: shaderProgram)
initNode(Node bg, {LayerObjectFlags.Render})
layer.addChild(bg)

Input.addKeyPressedListener(
  K_ESCAPE,
  proc(key: Keycode, state: KeyState) =
    Game.stop()
)

Game.start()

