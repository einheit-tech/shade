import ../../src/shade
import std/random

const
  width = 800
  height = 600

randomize()

initEngineSingleton("UI Example", width, height)
let layer = newLayer()
Game.scene.addLayer layer

let root = newUIComponent()
root.backgroundColor = WHITE
root.stackDirection = Horizontal

let
  panel1 = newUIComponent()
  panel2 = newUIComponent()
  panel3 = newUIComponent()

panel1.backgroundColor = GREEN
panel2.backgroundColor = BLUE
panel3.backgroundColor = ORANGE

root.addChild(panel1)
root.addChild(panel2)
root.addChild(panel3)

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

  panel.onPressed:
    var newBgColor: Color = randomColor()
    while newBgColor == this.backgroundColor:
      newBgColor = randomColor()
    this.backgroundColor = newBgColor

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

# Load our font
let (_, kennyPixel) = Fonts.load("./examples/textbox/kennypixel.ttf", 72)
let text = newText(kennyPixel, "Foobar", RED)
text.textAlignHorizontal = Center
text.width = 200.0
text.height = 200.0
panel2.addChild(text)

Game.setUIRoot(root)

Input.onEvent(KEYUP):
  case e.key.keysym.sym:
    of K_ESCAPE:
      Game.stop()
    else:
      discard

Game.start()

