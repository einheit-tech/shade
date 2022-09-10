import ../../src/shade
import std/[sugar, random]

const
  width = 800
  height = 600

randomize()

initEngineSingleton("UI Example", width, height)
let layer = newLayer()
Game.scene.addLayer layer

let root = newUIComponent()
root.backgroundColor = WHITE
root.stackDirection = Overlap

let
  normalContainer = newUIComponent()
  panel1 = newUIComponent()
  panel2 = newUIComponent()
  panel3 = newUIComponent()
  overlay = newUIComponent()

normalContainer.stackDirection = Horizontal

overlay.stackDirection = Overlap
overlay.processInputEvents = false

panel1.backgroundColor = GREEN
panel2.backgroundColor = BLUE
panel3.backgroundColor = ORANGE
overlay.backgroundColor = newColor(0, 0, 0, 100)

root.addChild(normalContainer)
normalContainer.addChild(panel1)
normalContainer.addChild(panel2)
normalContainer.addChild(panel3)
root.addChild(overlay)

panel1.alignHorizontal = Center
panel1.alignVertical = Start
panel2.alignVertical = Center
panel2.alignHorizontal = Center

panel3.stackDirection = Vertical
panel3.alignHorizontal = End
panel3.alignVertical = End

proc randomColor(): Color =
  return sample([
    RED,
    BLUE,
    GREEN,
    PURPLE,
    ORANGE,
    WHITE
  ])

for i in 0 ..< 3:
  let panel = newUIComponent()
  panel.backgroundColor = PURPLE
  panel.width = ratio(0.75)
  panel.height = 100.0
  panel.margin = 2.0
  panel.borderWidth = 1.0

  capture panel:
    panel.onPressed:
      var newBgColor: Color = randomColor()
      while newBgColor == panel.backgroundColor:
        newBgColor = randomColor()
      panel.backgroundColor = newBgColor

  panel1.addChild(panel)

var blue: uint8 = 250
for i in 0 ..< 3:
  let panel = newUIComponent()
  panel.margin = 4.0
  panel.width = ratio(0.65)
  panel.height = 100.0

  panel.backgroundColor = newColor(200, 200, blue)
  blue -= 50

  panel3.addChild(panel)

let (_, image) = Images.loadImage("./examples/assets/images/item_board.png")
let imageComponent = newUIImage(image)
imageComponent.imageAlignHorizontal = Center
imageComponent.width = float(image.w)
imageComponent.height = float(image.h)
panel2.addChild(imageComponent)

# Load our font
let (_, kennyPixel) = Fonts.load("./examples/textbox/kennypixel.ttf", 72)
let text = newText(kennyPixel, "Foobar", WHITE)
text.textAlignVertical = Center
text.textAlignHorizontal = Center
imageComponent.addChild(text)

Game.setUIRoot(root)

Input.onEvent(KEYUP):
  case e.key.keysym.sym:
    of K_ESCAPE:
      Game.stop()
    else:
      discard

Game.start()

