import
  shade,
  nimtest

describe "AABB":

  describe "contains":

    it "returns true when aabb1 contains aabb2":
      let
        aabb1 = newAABB(0, 0, 100, 100)
        aabb2 = newAABB(30, 30, 80, 80)
      assertEquals(aabb1.contains(aabb2), true)

    it "returns false when aabb2 contains aabb1":
      let
        aabb1 = newAABB(30, 30, 80, 80)
        aabb2 = newAABB(0, 0, 100, 100)
      assertEquals(aabb1.contains(aabb2), false)

    it "returns false when aabb1 and aabb2 are not overlapping at all":
      let
        aabb1 = newAABB(300, 300, 80, 80)
        aabb2 = newAABB(0, 0, 100, 100)
      assertEquals(aabb1.contains(aabb2), false)
      assertEquals(aabb2.contains(aabb1), false)

  describe "intersects":

    it "returns true when aabb1 contains aabb2":
      let
        aabb1 = newAABB(0, 0, 100, 100)
        aabb2 = newAABB(30, 30, 80, 80)
      assertEquals(aabb1.intersects(aabb2), true)

    it "returns true when aabb2 contains aabb1":
      let
        aabb1 = newAABB(30, 30, 80, 80)
        aabb2 = newAABB(0, 0, 100, 100)
      assertEquals(aabb1.intersects(aabb2), true)

    it "returns false when aabb1 and aabb2 are not overlapping at all":
      var
        aabb1 = newAABB(300, 300, 80, 80)
        aabb2 = newAABB(0, 0, 100, 100)
      assertEquals(aabb1.intersects(aabb2), false)
      assertEquals(aabb2.intersects(aabb1), false)

      aabb1 = newAABB(952, 627, 968, 653)
      aabb2 = newAABB(480, 920, 1440, 1080)
      assertEquals(aabb1.intersects(aabb2), false)
      assertEquals(aabb2.intersects(aabb1), false)

  describe "createBoundsAround":

    it "returns the outer bounds of two aabbangles":
      let
        aabb1 = newAABB(0, 0, 100, 100)
        aabb2 = newAABB(-30, 30, 110, 280)

      let sum = createBoundsAround(aabb1, aabb2)
      assertEquals(sum.topLeft, vector(-30, 0))
      assertEquals(sum.bottomRight, vector(110, 280))


