import
  ../../src/shade,
  sdl2_nim/sdl_gpu

const
  width = 800
  height = 600

initEngineSingleton("Post-processing shader example", width, height)
let layer = newLayer()
Game.scene.addLayer layer

# Load a shader
const
  fragShaderPath = "./examples/shaders/shockwave.frag"
  vertShaderPath = "./examples/shaders/common.vert"

let
  shaderProgram = newShader(vertShaderPath, fragShaderPath)
  (_, image) = Images.loadImage("./examples/assets/images/mushroom_sheet.png", FILTER_NEAREST)
  backgroundImageSprite = newSprite(image)

backgroundImageSprite.scale = vector(4, 4)
let background = newSpriteNode(backgroundImageSprite)
background.setLocation(width * 0.5, height * 0.5)
layer.addChild(background)

Input.addKeyPressedListener(
  K_ESCAPE,
  proc(key: Keycode, state: KeyState) =
    Game.stop()
)

Game.postProcessingShader = shaderProgram

Game.start()

