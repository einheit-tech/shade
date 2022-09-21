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
root.alignHorizontal = Alignment.SpaceEvenly
root.alignVertical = Alignment.SpaceEvenly

let
  panel1 = newUIComponent()
  panel2 = newUIComponent()
  panel3 = newUIComponent()

panel1.backgroundColor = RED
panel2.backgroundColor = ORANGE
panel3.backgroundColor = BLUe

panel1.width = 200.0
panel2.width = 200.0
panel3.width = 200.0

panel1.height = 100.0
panel2.height = 100.0
panel3.height = 100.0

panel1.margin = 8.0
panel2.margin = 8.0
panel3.margin = 8.0

root.addChild(panel1)
root.addChild(panel2)
root.addChild(panel3)

Game.setUIRoot(root)

Input.onEvent(KEYUP):
  case e.key.keysym.sym:
    of K_ESCAPE:
      Game.stop()
    of K_RETURN:
      echo panel1.bounds
      echo panel2.bounds
      echo panel3.bounds
    else:
      discard

Game.start()

