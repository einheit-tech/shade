import ../../../src/shade, nimtest

describe "UIComponent":

  describe "addChild":

    it "sets up a proper parent-child relationship":
      let root = newUIComponent()
      doAssert(root.parent == nil)
      doAssert(root.children.len == 0)

      let child = newUIComponent()
      root.addChild(child)
      doAssert(child.parent == root)
      doAssert(root.children.len == 1)

      doAssert(root.children.contains(child))

