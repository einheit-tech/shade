import
  ../../src/shade,
  sdl2_nim/sdl_gpu

const
  width = 800
  height = 600

initEngineSingleton("Basic Example Game", width, height)
let layer = newLayer()
Game.scene.addLayer layer

let (_, image) = Images.loadImage("./examples/assets/images/king.png", FILTER_NEAREST)

let king = newNode({LayerObjectFlags.UPDATE, LayerObjectFlags.RENDER})
king.scale = vector(8, 8)
king.setLocation(vector(320, height / 2))

let kingSprite = newSprite(image, 11, 8)
king.onRender = proc(this: Node, ctx: Target) =
  kingSprite.render(ctx)

layer.addChild(king)

# Load a shader
const
  fragShaderPath = "./examples/shaders/water.frag"
  vertShaderPath = "./examples/shaders/common.vert"

let shaderProgram = newShader(vertShaderPath, fragShaderPath)
king.shader = shaderProgram

Input.addKeyEventListener(
  K_ESCAPE,
  proc(key: Keycode, state: KeyState) =
    Game.stop()
)

Game.start()

