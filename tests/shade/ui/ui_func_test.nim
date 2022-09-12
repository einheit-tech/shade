import ../../../src/shade, nimtest
import std/random

template uitest(title: string, body: untyped) =
  try:
    it(title, body)
  except Exception as e:
    echo e.msg

  resetState()

  when defined(uitest):
    try:
      body
    except:
      discard

    initEngineSingleton(title, int root.width.pixelValue, int root.height.pixelValue)
    let layer = newLayer()
    Game.scene.addLayer layer
    Game.setUIRoot(gui.getUIRoot())

    Input.onEvent(KEYUP):
      case e.key.keysym.sym:
        of K_ESCAPE:
          Game.stop()
        else:
          discard

proc randomColor(): Color =
  return sample([
    RED,
    BLUE,
    GREEN,
    PURPLE,
    ORANGE,
    WHITE
  ])

proc randomColorUIComponent(): UIComponent =
  return newUIComponent(randomColor())

describe "UI functional tests":

  var
    gui: UI
    root: UIComponent

  proc resetState() =
    root = newUIComponent(newColor(50, 50, 50))
    gui = newUI(root)

  beforeEach:
    resetState()

  describe "Layout Validation":

    template tryInvalidate(body: untyped) =
      let panel1 = randomColorUIComponent()
      let panel {.inject.} = randomColorUIComponent()
      panel1.addChild(panel)
      root.addChild(panel1)

      # Ensure both are still invalid after adding panel to root
      assertEquals(root.layoutValidationStatus, Invalid)
      assertEquals(panel1.layoutValidationStatus, Invalid)
      assertEquals(panel.layoutValidationStatus, Invalid)

      # Layout and validation the component tree for the first time
      gui.layout(800, 600)

      # Ensure all are valid after performing layout
      assertEquals(root.layoutValidationStatus, Valid)
      assertEquals(panel1.layoutValidationStatus, Valid)
      assertEquals(panel.layoutValidationStatus, Valid)

      # Invalidate 'panel' with custom code (unique per test)
      body

      # Check validation status of all panels according to spec
      assertEquals(root.layoutValidationStatus, InvalidChild)
      assertEquals(panel1.layoutValidationStatus, InvalidChild)
      assertEquals(panel.layoutValidationStatus, Invalid)

      # Attempt to layout and re-validate the component tree
      gui.layout(800, 600)

      # Ensure all are valid again
      assertEquals(root.layoutValidationStatus, Valid)
      assertEquals(panel1.layoutValidationStatus, Valid)
      assertEquals(panel.layoutValidationStatus, Valid)

    it "is invalid to start":
      assertEquals(root.layoutValidationStatus, Invalid)

    it "invalidates using margin":
      tryInvalidate:
        panel.margin = 10.0

    it "invalidates using padding":
      tryInvalidate:
        panel.padding = 10.0

    it "invalidates using width":
      tryInvalidate:
        panel.width = 100.0

    it "invalidates using height":
      tryInvalidate:
        panel.height = 100.0

    it "invalidates using borderWidth":
      tryInvalidate:
        panel.borderWidth = 1.0

    it "invalidates using new child":
      tryInvalidate:
        panel.addChild(randomColorUIComponent())

    it "revalidates component tree correctly with different layout dimensions":
      let panel = randomColorUIComponent()
      panel.margin = margin(15, 20, 15, 20)
      root.addChild(panel)
      root.padding = 10.0

      gui.layout(800, 600)
      assertEquals(panel.bounds, aabb(25, 30, 775, 570))

      gui.layout(100, 100)
      assertEquals(panel.bounds, aabb(25, 30, 75, 70))

    it "revalidates component tree correctly with changed vertical alignment":
      let panel = randomColorUIComponent()
      panel.height = 30.0
      root.addChild(panel)

      root.alignVertical = Alignment.Start
      gui.layout(800, 600)
      assertEquals(panel.bounds, aabb(0, 0, 800, 30))

      root.alignVertical = Alignment.End
      gui.layout(800, 600)
      assertEquals(panel.bounds, aabb(0, 570, 800, 600))

    it "revalidates component tree correctly with changed horizontal alignment":
      let panel = randomColorUIComponent()
      panel.width = 666.0
      root.addChild(panel)

      root.alignHorizontal = Alignment.Start
      gui.layout(800, 600)
      assertEquals(panel.bounds, aabb(0, 0, 666, 600))

      root.alignHorizontal = Alignment.End
      gui.layout(800, 600)
      assertEquals(panel.bounds, aabb(134, 0, 800, 600))

  describe "Vertical Stack Direction":

    it "3 stacked panels":
      let
        panel1 = randomColorUIComponent()
        panel2 = randomColorUIComponent()
        panel3 = randomColorUIComponent()

      panel1.height = 50.0

      root.addChild(panel1)
      root.addChild(panel2)
      root.addChild(panel3)

      gui.layout(100.0, 200.0)

      assertEquals(root.bounds, aabb(0, 0, 100, 200))
      assertEquals(panel1.bounds, aabb(0, 0, 100, 50))
      assertEquals(panel2.bounds, aabb(0, 50, 100, 125))
      assertEquals(panel3.bounds, aabb(0, 125, 100, 200))

    it "variable, fixed, variable, fixed":
      let
        panel1 = randomColorUIComponent()
        panel2 = randomColorUIComponent()
        panel3 = randomColorUIComponent()
        panel4 = randomColorUIComponent()

      panel2.height = 25.0
      panel4.height = 50.0

      root.addChild(panel1)
      root.addChild(panel2)
      root.addChild(panel3)
      root.addChild(panel4)

      gui.layout(200, 500)

      assertEquals(panel1.bounds, aabb(0, 0, 200, 212.5))
      assertEquals(panel2.bounds, aabb(0, 212.5, 200, 237.5))
      assertEquals(panel3.bounds, aabb(0, 237.5, 200, 450))
      assertEquals(panel4.bounds, aabb(0, 450, 200, 500))

    it "with margins and padding":
      let 
        panel1 = randomColorUIComponent()
        panel2 = randomColorUIComponent()
        panel3 = randomColorUIComponent()

      root.addChild(panel1)
      root.addChild(panel2)
      root.addChild(panel3)

      root.padding = insets(5, 10, 5, 10)

      panel1.height = 100.0
      panel3.height = 50.0

      panel1.margin = 5.0
      panel2.margin = 8.0
      panel3.margin = 5.0

      gui.layout(800, 600)

      assertEquals(panel2.bounds.height, 404.0)
      assertEquals(panel2.bounds.left, 13.0)
      assertEquals(panel2.bounds.top, 123.0)

  describe "Horizontal Stack Direction":

    it "3 stacked panels":
      let
        panel1 = randomColorUIComponent()
        panel2 = randomColorUIComponent()
        panel3 = randomColorUIComponent()

      root.stackDirection = Horizontal
      panel2.width = 75.0

      root.addChild(panel1)
      root.addChild(panel2)
      root.addChild(panel3)

      gui.layout(400.0, 300.0)

      assertEquals(root.bounds, aabb(0, 0, 400, 300))
      assertEquals(panel1.bounds, aabb(0, 0, 162.5, 300))
      assertEquals(panel2.bounds, aabb(162.5, 0, 237.5, 300))
      assertEquals(panel3.bounds, aabb(237.5, 0, 400, 300))

    it "variable, fixed, variable, fixed":
      let
        panel1 = randomColorUIComponent()
        panel2 = randomColorUIComponent()
        panel3 = randomColorUIComponent()
        panel4 = randomColorUIComponent()

      root.stackDirection = Horizontal

      panel2.width = 25.0
      panel4.width = 50.0

      root.addChild(panel1)
      root.addChild(panel2)
      root.addChild(panel3)
      root.addChild(panel4)

      gui.layout(800, 600)

      assertEquals(panel1.bounds, aabb(0, 0, 362.5, 600))
      assertEquals(panel2.bounds, aabb(362.5, 0, 387.5, 600))
      assertEquals(panel3.bounds, aabb(387.5, 0, 750, 600))
      assertEquals(panel4.bounds, aabb(750, 0, 800, 600))

  describe "Overlap Stack Direction":

    it "rgb stacked panels":
      let
        rPanel = newUIComponent(newColor(255, 0, 0))
        gPanel = newUIComponent(newColor(0, 255, 0))
        bPanel = newUIComponent(newColor(0, 0, 255))

      rPanel.width = 100.0
      rPanel.height = 100.0
      gPanel.width = 100.0
      gPanel.height = 100.0
      bPanel.width = 100.0
      bPanel.height = 100.0

      rPanel.margin = margin(10, 25, 0, 0)
      gPanel.margin = margin(20, 50, 0, 0)
      bPanel.margin = margin(30, 75, 0, 0)

      root.padding = 8.0
      root.stackDirection = Overlap
      root.addChild(rPanel)
      root.addChild(gPanel)
      root.addChild(bPanel)

      gui.layout(800, 600)

      assertEquals(rPanel.bounds, aabb(18, 33, 118, 133))
      assertEquals(gPanel.bounds, aabb(28, 58, 128, 158))
      assertEquals(bPanel.bounds, aabb(38, 83, 138, 183))

  describe "Alignment":

    it "3 centered blocks (Horizontal)":
      let
        panel1 = randomColorUIComponent()
        panel2 = randomColorUIComponent()
        panel3 = randomColorUIComponent()

      root.stackDirection = Horizontal

      root.alignVertical = Alignment.Center
      root.alignHorizontal = Alignment.Center

      root.addChild(panel1)
      root.addChild(panel2)
      root.addChild(panel3)

      panel1.margin = 2.0
      panel2.margin = 2.0
      panel3.margin = 2.0

      panel1.width = 10.0
      panel1.height = 10.0

      panel2.width = 10.0

      panel3.width = 10.0
      panel3.height = 10.0

      gui.layout(100, 200)

      assertEquals(panel1.bounds, aabb(33.0, 95.0, 43.0, 105.0))
      assertEquals(panel2.bounds, aabb(45, 2, 55, 198))
      assertEquals(panel3.bounds, aabb(57, 95, 67, 105))

    it "H":
      let
        panel1 = randomColorUIComponent()
        panel2 = randomColorUIComponent()
        panel3 = randomColorUIComponent()

      root.stackDirection = Horizontal

      root.alignVertical = Alignment.Center
      root.alignHorizontal = Alignment.Center
      root.padding = 10.0

      root.addChild(panel1)
      root.addChild(panel2)
      root.addChild(panel3)

      panel1.width = ratio(0.25)
      panel2.height = ratio(0.2)
      panel3.width = ratio(0.25)

      gui.layout(800, 600)

      assertEquals(panel1.bounds, aabb(10, 10, 205, 590))
      assertEquals(panel2.bounds, aabb(205, 242, 595, 358))
      assertEquals(panel3.bounds, aabb(595, 10, 790, 590))

    it "Vertical end alignment":
      let
        panel1 = randomColorUIComponent()
        panel2 = randomColorUIComponent()
        panel3 = randomColorUIComponent()

      root.stackDirection = Vertical

      root.alignVertical = Alignment.End
      root.alignHorizontal = Alignment.End
      root.padding = 4.0

      root.addChild(panel1)
      root.addChild(panel2)
      root.addChild(panel3)

      panel1.width = 100.0
      panel1.height = 100.0

      panel2.width = 100.0
      panel2.height = 100.0

      panel3.width = 100.0
      panel3.height = 100.0

      gui.layout(800, 600)

      assertEquals(panel3.bounds, aabb(696, 496, 796, 596))
      assertEquals(panel2.bounds, aabb(696, 396, 796, 496))
      assertEquals(panel1.bounds, aabb(696, 296, 796, 396))

    it "Horizontal end alignment":
      let
        panel1 = randomColorUIComponent()
        panel2 = randomColorUIComponent()
        panel3 = randomColorUIComponent()

      root.stackDirection = Horizontal

      root.alignVertical = Alignment.End
      root.alignHorizontal = Alignment.End
      root.padding = 4.0

      root.addChild(panel1)
      root.addChild(panel2)
      root.addChild(panel3)

      panel1.width = 100.0
      panel1.height = 100.0

      panel2.width = 100.0
      panel2.height = 100.0

      panel3.width = 100.0
      panel3.height = 100.0

      gui.layout(800, 600)

      assertEquals(panel3.bounds, aabb(696, 496, 796, 596))
      assertEquals(panel2.bounds, aabb(596, 496, 696, 596))
      assertEquals(panel1.bounds, aabb(496, 496, 596, 596))

    it "SpaceEvenly":
      let
        panel1 = randomColorUIComponent()
        panel2 = randomColorUIComponent()
        panel3 = randomColorUIComponent()
      
      root.stackDirection = Horizontal
      root.alignHorizontal = SpaceEvenly
      root.alignVertical = SpaceEvenly
      root.padding = 15.0

      root.addChild(panel1)
      root.addChild(panel2)
      root.addChild(panel3)

      panel1.width = 100.0
      panel1.height = 300.0
      panel2.width = 200.0
      panel2.height = 200.0
      panel3.width = 300.0
      panel3.height = 100.0

      gui.layout(800, 600)

      assertEquals(panel1.bounds, aabb(57.5, 135, 157.5, 465))
      assertEquals(panel2.bounds, aabb(200, 185, 400, 415))
      assertEquals(panel3.bounds, aabb(442.5, 235, 742.5, 365))

    it "SpaceEvenly with margins":
      let
        panel1 = randomColorUIComponent()
        panel2 = randomColorUIComponent()
        panel3 = randomColorUIComponent()

      root.stackDirection = Horizontal
      root.alignHorizontal = SpaceEvenly
      root.padding = 20.0

      root.addChild(panel1)
      root.addChild(panel2)
      root.addChild(panel3)

      panel1.width = 100.0
      panel1.margin = margin(25, 0, 30, 0)
      panel2.width = 200.0
      panel2.margin = margin(52, 0, 0, 0)
      panel3.width = 300.0

      gui.layout(800, 600)

      assertEquals(panel1.bounds, aabb(56, 20, 156, 580))
      assertEquals(panel2.bounds, aabb(208, 20, 408, 580))
      assertEquals(panel3.bounds, aabb(444, 20, 744, 580))

    it "SpaceEvenly with dynamic size":
      let
        panel1 = randomColorUIComponent()
        panel2 = randomColorUIComponent()
        panel3 = randomColorUIComponent()
      
      root.stackDirection = Horizontal
      root.alignHorizontal = SpaceEvenly
      root.padding = 30.0

      root.addChild(panel1)
      root.addChild(panel2)
      root.addChild(panel3)

      panel1.width = 50.0
      panel3.width = 150.0

      gui.layout(800, 600)

      assertEquals(panel1.bounds, aabb(30, 30, 80, 570))
      assertEquals(panel2.bounds, aabb(80, 30, 620, 570))
      assertEquals(panel3.bounds, aabb(620, 30, 770, 570))

  describe "Margins":

    it "root component not affected by margin":
      # Margins on the root component don't make sense since there is nothing for the margins to "push off of" - it's all infinite space.
      root.margin = margin(42, 69, 420, 666)
      gui.layout(100, 100)
      assertEquals(root.bounds, aabb(0, 0, 100, 100))

    it "collapses margins between children (vertically stacked)":
      root.stackDirection = Vertical

      let
        panel1 = randomColorUIComponent()
        panel2 = randomColorUIComponent()

      # Margins should collapse, so there should be 8 pixels between these panels.
      panel1.margin = margin(0, 0, 0, 5)
      panel2.margin = margin(0, 8, 0, 0)

      root.addChild(panel1)
      root.addChild(panel2)
      gui.layout(200, 200)

      assertEquals(panel1.bounds, aabb(0, 0, 200, 96))
      assertEquals(panel2.bounds, aabb(0, 104, 200, 200))

    it "collapses margins between children (horizontally stacked)":
      root.stackDirection = Horizontal

      let
        panel1 = randomColorUIComponent()
        panel2 = randomColorUIComponent()

      # Margins should collapse, so there should be 8 pixels between these panels.
      panel1.margin = margin(0, 0, 12, 0)
      panel2.margin = margin(13, 0, 0, 0)

      root.addChild(panel1)
      root.addChild(panel2)
      gui.layout(200, 200)

      assertEquals(panel1.bounds, aabb(0, 0, 93.5, 200))
      assertEquals(panel2.bounds, aabb(106.5, 0, 200, 200))

    it "resizable children fill space when centered (vertically stacked)":
      let panel1 = randomColorUIComponent()
      panel1.margin = margin(0, 80, 0, 120)

      root.stackDirection = Vertical
      root.alignHorizontal = Alignment.Center
      root.alignVertical = Alignment.Center
      root.addChild(panel1)

      gui.layout(400, 400)

      assertEquals(panel1.bounds, aabb(0, 80, 400, 280))

    it "resizable children fill space when centered (horizontally stacked)":
      let panel1 = randomColorUIComponent()
      panel1.margin = margin(60, 0, 85, 0)

      root.stackDirection = Horizontal
      root.alignHorizontal = Alignment.Center
      root.alignVertical = Alignment.Center
      root.addChild(panel1)

      gui.layout(400, 400)

      assertEquals(panel1.bounds, aabb(60, 0, 315, 400))

    it "center aligns child when margins won't fit parent size (vertically stacked)":
      let panel1 = randomColorUIComponent()
      panel1.margin = margin(80, 80, 120, 120)
      panel1.width = 300.0
      panel1.height = 300.0

      root.stackDirection = Vertical
      root.alignHorizontal = Alignment.Center
      root.alignVertical = Alignment.Center
      root.addChild(panel1)

      gui.layout(400, 400)

      # panel1 height + margin = 300 + 120 + 80 = 500
      # Centered on (200, 200) puts the top at -50 and bottom at 450
      # 80 down from the top margin: 30
      # 120 up from the bottom margin: 330
      assertEquals(panel1.bounds, aabb(30, 30, 330, 330))

    it "center aligns child when margins won't fit parent size (horizontally stacked)":
      let panel1 = randomColorUIComponent()
      panel1.margin = margin(35, 35, 180, 180)
      panel1.width = 300.0
      panel1.height = 300.0

      root.stackDirection = Horizontal
      root.alignHorizontal = Alignment.Center
      root.alignVertical = Alignment.Center
      root.addChild(panel1)

      gui.layout(400, 400)

      # panel1 width + margin = 300 + 35 + 180 = 515
      # Centered on (200, 200) puts the left at -57.5 and bottom at 457.5
      # 35 right from the left margin: -22.5
      # 180 left from the right margin: 277.5
      assertEquals(panel1.bounds, aabb(-22.5, -22.5, 277.5, 277.5))

    it "center aligns multiple children when they won't fit parent (vertically stacked)":
      let
        # No margins
        panel1 = randomColorUIComponent()
        # Both margins conflict
        panel2 = randomColorUIComponent()
        # Left margin conflicts
        panel3 = randomColorUIComponent()
        # Right margin conflicts
        panel4 = randomColorUIComponent()

      panel1.backgroundColor = GREEN
      panel2.backgroundColor = BLUE
      panel3.backgroundColor = RED
      panel4.backgroundColor = PURPLE

      panel1.width = 360.0
      panel1.height = 100.0

      panel2.width = 200.0
      panel2.height = 100.0
      panel2.margin = margin(99, 0, 66, 0)

      panel3.width = 250.0
      panel3.height = 100.0
      panel3.margin = margin(55, 0, 0, 0)

      panel4.width = 250.0
      panel4.height = 100.0
      panel4.margin = margin(0, 0, 65, 0)

      root.addChild(panel1)
      root.addChild(panel2)
      root.addChild(panel3)
      root.addChild(panel4)

      root.stackDirection = Vertical
      root.alignHorizontal = Alignment.Center
      root.alignVertical = Alignment.Center

      root.padding = padding(10, 10, 20, 20)

      gui.layout(360, 360)

      assertEquals(panel1.bounds, aabb(-5, -25, 355, 75))
      assertEquals(panel2.bounds, aabb(91.5, 75, 291.5, 175))
      assertEquals(panel3.bounds, aabb(65, 175, 315, 275))
      assertEquals(panel4.bounds, aabb(25, 275, 275, 375))

    it "center aligns multiple children when they won't fit parent (horizontally stacked)":
      let
        panel1 = randomColorUIComponent()
        panel2 = randomColorUIComponent()
        panel3 = randomColorUIComponent()

      panel1.width = 120.0
      panel2.width = 120.0
      panel3.width = 120.0

      root.addChild(panel1)
      root.addChild(panel2)
      root.addChild(panel3)

      root.stackDirection = Horizontal
      root.alignHorizontal = Alignment.Center
      root.alignVertical = Alignment.Center

      root.padding = padding(10, 0, 20, 0)

      gui.layout(360, 360)

      assertEquals(panel2.bounds.center.x, 10 + (360 - 10 - 20) / 2)

    it "child with exact size and margins perfectly fits the parent with all alignments (vertically stacked)":
      let panel1 = randomColorUIComponent()
      panel1.margin = margin(0, 80, 0, 120)
      panel1.height = 160.0

      root.stackDirection = Vertical
      root.addChild(panel1)

      for alignment in [Alignment.Start, Alignment.Center, Alignment.End]:
        root.alignHorizontal = alignment
        root.alignVertical = alignment
        assertEquals(root.layoutValidationStatus, Invalid)

        gui.layout(400, 360)

        assertEquals(panel1.bounds, aabb(0, 80, 400, 240))

    it "child with exact size and margins perfectly fits the parent with all alignments (horizontally stacked)":
      let panel1 = randomColorUIComponent()
      panel1.margin = margin(60, 0, 135, 0)
      panel1.width = 205.0

      root.stackDirection = Horizontal
      root.addChild(panel1)

      for alignment in [Alignment.Start, Alignment.Center, Alignment.End]:
        root.alignHorizontal = alignment
        root.alignVertical = alignment
        assertEquals(root.layoutValidationStatus, Invalid)

        gui.layout(400, 400)

        assertEquals(panel1.bounds, aabb(60, 0, 265, 400))

  describe "Borders":

    it "takes borders into account when calculating available area":
      let panel1 = randomColorUIComponent()
      root.addChild(panel1)

      root.borderWidth = 2.0

      gui.layout(800, 600)

      assertEquals(panel1.bounds, aabb(2, 2, 798, 598))

    it "takes borders and padding into account when calculating available area":
      let panel1 = randomColorUIComponent()
      root.addChild(panel1)

      root.padding = 1.0
      root.borderWidth = 2.0

      gui.layout(800, 600)

      assertEquals(panel1.bounds, aabb(3, 3, 797, 597))

    it "takes borders and non-proportionate padding into account when calculating available area":
      let panel1 = randomColorUIComponent()
      root.addChild(panel1)

      root.padding = padding(0, 1, 8, 11)
      root.borderWidth = 2.0

      gui.layout(800, 600)

      assertEquals(panel1.bounds, aabb(2, 3, 790, 587))

when defined(uitest):
  Game.start()

