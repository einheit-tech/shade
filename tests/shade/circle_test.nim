import
  ../testutils,
  shade

describe "Circle tests":

  let circle = newCircle(vector(124, 256), 50)

  describe "Projection":

    it "projects the circle correctly onto a horizontal axis":
      let
        axis = vector(1, 0)
        projection = circle.project(VEC2_ZERO, axis)
      # circle.center.x - circle.radius
      assertEquals(projection.x, 74)
      # circle.center.x + circle.radius
      assertEquals(projection.y, 174)

    it "projects the circle correctly onto a vertical axis":
      let
        axis = vector(0, 1)
        projection = circle.project(VEC2_ZERO, axis)
      # circle.center.y - circle.radius
      assertEquals(projection.x, 206)
      # circle.center.y + circle.radius
      assertEquals(projection.y, 306)

