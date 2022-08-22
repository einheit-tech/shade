import ../../../src/shade, nimtest

template uitest(title: string, body: untyped) =
  when defined(visualtest):
    discard
  else:
    it(title, body)

describe "UI functional tests":

  describe "Vertical Stack Direction":

    uitest "3 stacked panels":
      let
        root = newUIComponent()
        panel1 = newUIComponent()
        panel2 = newUIComponent()
        panel3 = newUIComponent()

      panel1.height = 50.0

      root.addChild(panel1)
      root.addChild(panel2)
      root.addChild(panel3)

      let ui = newUI(root)
      ui.layout(100.0, 200.0)

      assertEquals(root.bounds, aabb(0, 0, 100, 200))
      assertEquals(panel1.bounds, aabb(0, 0, 100, 50))
      assertEquals(panel2.bounds, aabb(0, 50, 100, 125))
      assertEquals(panel3.bounds, aabb(0, 125, 100, 200))

    uitest "variable, fixed, variable, fixed":
      let
        root = newUIComponent()
        panel1 = newUIComponent()
        panel2 = newUIComponent()
        panel3 = newUIComponent()
        panel4 = newUIComponent()

      panel2.height = 25.0
      panel4.height = 50.0

      root.addChild(panel1)
      root.addChild(panel2)
      root.addChild(panel3)
      root.addChild(panel4)

      let ui = newUI(root)
      ui.layout(200, 500)

      assertEquals(panel1.bounds, aabb(0, 0, 200, 212.5))
      assertEquals(panel2.bounds, aabb(0, 212.5, 200, 237.5))
      assertEquals(panel3.bounds, aabb(0, 237.5, 200, 450))
      assertEquals(panel4.bounds, aabb(0, 450, 200, 500))

    uitest "with margins and padding":
      let 
        root = newUIComponent()
        panel1 = newUIComponent()
        panel2 = newUIComponent()
        panel3 = newUIComponent()

      root.addChild(panel1)
      root.addChild(panel2)
      root.addChild(panel3)

      root.padding = insets(5, 10, 5, 10)

      panel1.height = 100.0
      panel3.height = 50.0

      panel1.margin = 5.0
      panel2.margin = 8.0
      panel3.margin = 5.0

      let ui = newUI(root)
      ui.layout(800, 600)

      assertEquals(panel2.bounds.height, 404.0)
      assertEquals(panel2.bounds.left, 13.0)
      assertEquals(panel2.bounds.top, 123.0)

  describe "Horizontal Stack Direction":

    uitest "3 stacked panels":
      let
        root = newUIComponent()
        panel1 = newUIComponent()
        panel2 = newUIComponent()
        panel3 = newUIComponent()

      root.stackDirection = Horizontal
      panel2.width = 75.0

      root.addChild(panel1)
      root.addChild(panel2)
      root.addChild(panel3)

      let ui = newUI(root)
      ui.layout(400.0, 300.0)

      assertEquals(root.bounds, aabb(0, 0, 400, 300))
      assertEquals(panel1.bounds, aabb(0, 0, 162.5, 300))
      assertEquals(panel2.bounds, aabb(162.5, 0, 237.5, 300))
      assertEquals(panel3.bounds, aabb(237.5, 0, 400, 300))

    uitest "variable, fixed, variable, fixed":
      let
        root = newUIComponent()
        panel1 = newUIComponent()
        panel2 = newUIComponent()
        panel3 = newUIComponent()
        panel4 = newUIComponent()

      root.stackDirection = Horizontal

      panel2.width = 25.0
      panel4.width = 50.0

      root.addChild(panel1)
      root.addChild(panel2)
      root.addChild(panel3)
      root.addChild(panel4)

      let ui = newUI(root)
      ui.layout(800, 600)

      assertEquals(panel1.bounds, aabb(0, 0, 362.5, 600))
      assertEquals(panel2.bounds, aabb(362.5, 0, 387.5, 600))
      assertEquals(panel3.bounds, aabb(387.5, 0, 750, 600))
      assertEquals(panel4.bounds, aabb(750, 0, 800, 600))

  describe "Alignment":

    uitest "3 centered blocks (Horizontal)":
      let
        root = newUIComponent()
        panel1 = newUIComponent()
        panel2 = newUIComponent()
        panel3 = newUIComponent()

      root.stackDirection = Horizontal

      root.alignVertical = Center
      root.alignHorizontal = Center

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

      let ui = newUI(root)
      ui.layout(100, 200)

      assertEquals(panel1.bounds, aabb(33.0, 95.0, 43.0, 105.0))
      assertEquals(panel2.bounds, aabb(45, 2, 55, 198))
      assertEquals(panel3.bounds, aabb(57, 95, 67, 105))

    uitest "H":
      let
        root = newUIComponent()
        panel1 = newUIComponent()
        panel2 = newUIComponent()
        panel3 = newUIComponent()

      root.stackDirection = Horizontal

      root.alignVertical = Center
      root.alignHorizontal = Center
      root.padding = 10.0

      root.addChild(panel1)
      root.addChild(panel2)
      root.addChild(panel3)

      panel1.width = ratio(0.25)
      panel2.height = ratio(0.2)
      panel3.width = ratio(0.25)

      let ui = newUI(root)
      ui.layout(800, 600)

      assertEquals(panel1.bounds, aabb(10, 10, 205, 590))
      assertEquals(panel3.bounds, aabb(205, 242, 595, 358))
      assertEquals(panel3.bounds, aabb(595, 10, 790, 590))

