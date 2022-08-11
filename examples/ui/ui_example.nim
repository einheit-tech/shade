import ../../src/shade

const
  width = 800
  height = 600

initEngineSingleton("UI Example", width, height)
let layer = newLayer()
Game.scene.addLayer layer

let root = newUIComponent()
root.backgroundColor = BLACK
root.stackDirection = Vertical

root.margin.left = 10
root.margin.top = 10
root.margin.right = 10
root.margin.bottom = 10

let
  panel1 = newUIComponent()
  panel2 = newUIComponent()
  panel3 = newUIComponent()

panel1.backgroundColor = WHITE
panel2.backgroundColor = BLUE
panel3.backgroundColor = ORANGE

root.addChild(panel1)
root.addChild(panel2)
root.addChild(panel3)

type Foo = ref object of Node

Foo.renderAsNodeChild:
  root.preRender(ctx, 0, 0, gamestate.resolution.x, gamestate.resolution.y)

method update*(this: Foo, deltaTime: float) =
  # Flip the stackDirection every 2 seconds
  if round(gamestate.runTime) mod 2 == 0:
    root.stackDirection = Vertical
  else:
    root.stackDirection = Horizontal

let foo = Foo()
initNode(Node foo)
layer.addChild(foo)

Input.addKeyPressedListener(
  K_ESCAPE,
  proc(key: Keycode, state: KeyState) =
    Game.stop()
)

Game.start()

