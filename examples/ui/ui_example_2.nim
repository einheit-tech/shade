import ../../src/shade
import std/[sugar, random]

const
  width = 800
  height = 600

initEngineSingleton("UI Example", width, height)
let layer = newLayer()
Game.scene.addLayer layer

let root = newUIComponent()
root.backgroundColor = BLACK
root.stackDirection = Vertical
root.alignHorizontal = Alignment.Start
root.alignVertical = Alignment.Start

let
  panel1 = newUIComponent()
  panel2 = newUIComponent()
  panel3 = newUIComponent()

panel1.backgroundColor = RED
panel2.backgroundColor = ORANGE
panel3.backgroundColor = BLUe

root.addChild(panel1)
root.addChild(panel2)
root.addChild(panel3)

Game.setUIRoot(root)

Input.onEvent(KEYUP):
  case e.key.keysym.sym:
    of K_ESCAPE:
      Game.stop()
    else:
      discard


Game.start()

