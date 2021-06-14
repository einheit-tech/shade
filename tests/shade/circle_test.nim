import shade

describe "Circle tests":

  let circle = newCircle(vec2(124, 256), 50)

  describe "project":

    it "projects the circle correctly onto a horizontal axis":
      let
        axis = vec2(1, 0)
        projection = circle.project(VEC2_ZERO, axis)
      # circle.center.x - circle.radius
      assertEquals(projection.x, 74)
      # circle.center.x + circle.radius
      assertEquals(projection.y, 174)

    it "projects the circle correctly onto a vertical axis":
      let
        axis = vec2(0, 1)
        projection = circle.project(VEC2_ZERO, axis)
      # circle.center.y - circle.radius
      assertEquals(projection.x, 206)
      # circle.center.y + circle.radius
      assertEquals(projection.y, 306)


