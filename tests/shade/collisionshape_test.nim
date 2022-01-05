import
  ../testutils,
  shade

describe "CollisionShape tests":

  describe "Projection":

    let 
      circleA = newCircle(vector(124, 256), 50)
      circleB = newCircle(vector(240, 100), 120)
      rectPoly = newPolygon([
        vector(15, 45),
        vector(15, -45),
        vector(-15, -45),
        vector(-15, 45)
      ])

    it "getCircleToCircleProjectionAxes":
      let
        aToB = vector(-56, 331)
        projections = circleA.getCircleToCircleProjectionAxes(circleB, aToB)

      assertEquals(projections.len, 1)

      let projection = projections[0]
      assertEquals(projection.getMagnitude(), 1.0)

      let expected = normalize(circleB.center - circleA.center + aToB)
      assertEquals(projection, expected)

    it "getPolygonProjectionAxes":
      let projections = rectPoly.getPolygonProjectionAxes()

      assertEquals(projections.len, rectPoly.len)

      let expectedProjections = [
        normalize(rectPoly[1] - rectPoly[0]).perpendicular(),
        normalize(rectPoly[2] - rectPoly[1]).perpendicular(),
        normalize(rectPoly[3] - rectPoly[2]).perpendicular(),
        normalize(rectPoly[0] - rectPoly[3]).perpendicular()
      ]

      assertEquals(expectedProjections.contains(projections[0]), true)
      assertEquals(expectedProjections.contains(projections[1]), true)
      assertEquals(expectedProjections.contains(projections[2]), true)
      assertEquals(expectedProjections.contains(projections[3]), true)
