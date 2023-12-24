import ../../src/shade

const
  width = 800
  height = 600

initEngineSingleton(
  "TextBox Example",
  width,
  height,
  clearColor = newColor(32, 32, 32)
)

let layer = newLayer()
Game.scene.addLayer(layer)

# Load our font
let (_, kennyPixel) = Fonts.load("./examples/textbox/kennypixel.ttf", 72)

# Create some text to render
let textBox = newTextBox(kennyPixel, "Hello, world!", RED)
textBox.setLocation(400, 300)
layer.addChild(textBox)

Input.onKeyPressed(K_ESCAPE):
  Game.stop()

Game.start()

