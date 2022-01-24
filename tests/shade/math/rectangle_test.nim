import
  shade,
  ../../testutils

describe "Rectangle":

  describe "contains":

    it "returns true when rect1 contains rect2":
      let
        rect1 = newRectangle(0, 0, 100, 100)
        rect2 = newRectangle(30, 30, 80, 80)
      assertEquals(rect1.contains(rect2), true)

    it "returns false when rect2 contains rect1":
      let
        rect1 = newRectangle(30, 30, 80, 80)
        rect2 = newRectangle(0, 0, 100, 100)
      assertEquals(rect1.contains(rect2), false)

    it "returns false when rect1 and rect2 are not overlapping at all":
      let
        rect1 = newRectangle(300, 300, 80, 80)
        rect2 = newRectangle(0, 0, 100, 100)
      assertEquals(rect1.contains(rect2), false)
      assertEquals(rect2.contains(rect1), false)

  describe "intersects":

    it "returns true when rect1 contains rect2":
      let
        rect1 = newRectangle(0, 0, 100, 100)
        rect2 = newRectangle(30, 30, 80, 80)
      assertEquals(rect1.intersects(rect2), true)

    it "returns true when rect2 contains rect1":
      let
        rect1 = newRectangle(30, 30, 80, 80)
        rect2 = newRectangle(0, 0, 100, 100)
      assertEquals(rect1.intersects(rect2), true)

    it "returns false when rect1 and rect2 are not overlapping at all":
      let
        rect1 = newRectangle(300, 300, 80, 80)
        rect2 = newRectangle(0, 0, 100, 100)
      assertEquals(rect1.intersects(rect2), false)
      assertEquals(rect2.intersects(rect1), false)

