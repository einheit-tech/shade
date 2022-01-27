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
      var
        rect1 = newRectangle(300, 300, 80, 80)
        rect2 = newRectangle(0, 0, 100, 100)
      assertEquals(rect1.intersects(rect2), false)
      assertEquals(rect2.intersects(rect1), false)

      rect1 = newRectangle(952, 627, 968, 653)
      rect2 = newRectangle(480, 920, 1440, 1080)
      assertEquals(rect1.intersects(rect2), false)
      assertEquals(rect2.intersects(rect1), false)

  describe "createBoundsAround":

    it "returns the outer bounds of two rectangles":
      let
        rect1 = newRectangle(0, 0, 100, 100)
        rect2 = newRectangle(-30, 30, 110, 280)

      let sum = createBoundsAround(rect1, rect2)
      assertEquals(sum.topLeft, vector(-30, 0))
      assertEquals(sum.bottomRight, vector(110, 280))


