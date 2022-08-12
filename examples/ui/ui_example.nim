import ../../src/shade

const
  width = 800
  height = 600

initEngineSingleton("UI Example", width, height)
let layer = newLayer()
Game.scene.addLayer layer

let root = newUIComponent()
root.backgroundColor = BLACK
root.stackDirection = Horizontal

root.margin.left = 10
root.margin.top = 10
root.margin.right = 10
root.margin.bottom = 10

# root.padding.left = 10
# root.padding.top = 10
# root.padding.right = 10
# root.padding.bottom = 10

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
  panel.height = 100
  panel1.addChild(panel)

for i in 0 ..< 3:
  let panel = newUIComponent()
  panel.margin = margin(4, 4, 4, 4)
  panel.backgroundColor = PURPLE
  panel.height = 100
  panel2.addChild(panel)

for i in 0 ..< 3:
  let panel = newUIComponent()
  panel.margin = margin(4, 4, 4, 4)
  panel.backgroundColor = PURPLE
  panel.height = 100
  panel3.addChild(panel)

root.updateBounds(0, 0, gamestate.resolution.x, gamestate.resolution.y)

type Foo = ref object of Node

Foo.renderAsNodeChild:
  root.preRender(ctx, 0, 0)

let foo = Foo()
initNode(Node foo)
layer.addChild(foo)

Input.addKeyPressedListener(
  K_ESCAPE,
  proc(key: Keycode, state: KeyState) =
    Game.stop()
)

Game.start()

