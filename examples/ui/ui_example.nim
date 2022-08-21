import ../../src/shade

const
  width = 800
  height = 600

initEngineSingleton("UI Example", width, height)
let layer = newLayer()
Game.scene.addLayer layer

let root = newUIComponent()
root.backgroundColor = WHITE
root.stackDirection = Horizontal
root.alignHorizontal = Center

root.padding.left = 10
root.padding.top = 10
root.padding.right = 10
root.padding.bottom = 10

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

panel1.alignVertical = Start
panel2.alignVertical = Center
panel3.alignVertical = End

for i in 0 ..< 3:
  let panel = newUIComponent()
  panel.margin = margin(4, 4, 4, 4)
  panel.backgroundColor = PURPLE
  panel.height = 100.0
  panel1.addChild(panel)

for i in 0 ..< 3:
  let panel = newUIComponent()
  panel.margin = margin(4, 4, 4, 4)
  panel.backgroundColor = PURPLE
  panel.height = 100.0
  panel3.addChild(panel)

# Load our font
let (_, kennyPixel) = Fonts.load("./examples/textbox/kennypixel.ttf", 72)
let text = newText(kennyPixel, "Foobar", RED)
text.textAlignHorizontal = Center
text.height = 400.0
panel2.addChild(text)

# TODO: What's the best way to do this?
root.updateBounds(0, 0, gamestate.resolution.x, gamestate.resolution.y)
gamestate.onResolutionChanged:
  root.updateBounds(0, 0, gamestate.resolution.x, gamestate.resolution.y)

type Foo = ref object of Node

Foo.renderAsNodeChild:
  root.preRender(ctx, 0, 0)

method update*(this: Foo, deltaTime: float) =
  root.update(deltaTime)

let foo = Foo()
initNode(Node foo)
layer.addChild(foo)

Input.addKeyPressedListener(
  K_ESCAPE,
  proc(key: Keycode, state: KeyState) =
    Game.stop()
)

var i = 1
Input.addKeyPressedListener(
  K_RETURN,
  proc(key: Keycode, state: KeyState) =
    panel2.width = float(50 * i)
    i += 1
)

Game.start()

