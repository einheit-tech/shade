import ../../src/shade

const
  width = 800
  height = 600

initEngineSingleton("UI Example", width, height)
let layer = newLayer()
Game.scene.addLayer layer

let root = newUIComponent()
root.backgroundColor = newColor(125, 0, 125)
root.stackDirection = Horizontal

# root.margin.left = 10
# root.margin.top = 10
# root.margin.right = 10
# root.margin.bottom = 10

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

type Foo = ref object of Node

Foo.renderAsNodeChild:
  root.preRender(ctx, 0, 0, gamestate.resolution.x, gamestate.resolution.y)

let flipStackDirectionTask = newTask(
  proc(this: Task, deltaTime: float) = discard,
  proc(this: Task): bool = this.elapsedTime >= 1.5,
  proc(this: Task) =
    this.elapsedTime = 0.0
    this.completed = false
    if root.stackDirection == Vertical:
      root.stackDirection = Horizontal
    else:
      root.stackDirection = Vertical
)

# Flip the stackDirection every few seconds
# layer.addChild(flipStackDirectionTask)

let foo = Foo()
initNode(Node foo)
layer.addChild(foo)

Input.addKeyPressedListener(
  K_ESCAPE,
  proc(key: Keycode, state: KeyState) =
    Game.stop()
)

Game.start()

