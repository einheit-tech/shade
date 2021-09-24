import
  shade,
  math

describe "Animation":

  type FakeEntity* = ref object
    intVal*: int
    floatVal*: float
    vec2Val*: Vec2
    vec3Val*: Vec3

  describe "Animates all possible field types":
    var callCount = 0

    let
      startingIntVal: int = 8
      startingFloatVal: float = 2.0
      startingVec2Val: Vec2 = vec2(2.9, 32.7)
      startingVec3Val: Vec3 = vec3(48.2, 831.0, 12.8)

    let
      this = FakeEntity(
        intVal: startingIntVal,
        floatVal: startingFloatVal,
        vec2Val: startingVec2Val,
        vec3Val: startingVec3Val
      )

    it "updates all components":
      let testAnim = newAnimation(1.8)

      # int
      const intFrames: seq[KeyFrame[int]] = @[
        (1, 0.0),
        (2, 0.5),
        (3, 1.1)
      ]
      testAnim.addNewAnimationTrack(
        this.intVal,
        intFrames
      )

      # float
      const floatFrames: seq[KeyFrame[float]] = @[
        (0.0, 0.0),
        (4.2, 0.5),
        (12.8, 1.1)
      ]
      testAnim.addNewAnimationTrack(
        this.floatVal,
        floatFrames
      )

      # Vec2
      const vec2Frames: seq[KeyFrame[Vec2]] = @[
        (vec2(0.0, 2.1), 0.0),
        (vec2(4.2, 3.2), 0.5),
        (vec2(12.8, 34.8), 1.1)
      ]
      testAnim.addNewAnimationTrack(
        this.vec2Val,
        vec2Frames
      )

      # Vec3
      const vec3Frames: seq[KeyFrame[Vec3]] = @[
        (vec3(1.0, 2.1, 12.5), 0.0),
        (vec3(4.2, 3.2, 39.4), 0.5),
        (vec3(12.8, 34.8, 12.8), 1.1)
      ]
      testAnim.addNewAnimationTrack(
        this.vec3Val,
        vec3Frames
      )

      # ClosureProc
      var someProc: ClosureProc = proc() {.closure.} =
        echo "someProc called"
        callCount.inc

      var
        proc1CallCount = 0
        proc2CallCount = 0
        proc3CallCount = 0

      proc foo1() {.closure.} = proc1CallCount.inc
      proc foo2() {.closure.} = proc2CallCount.inc
      proc foo3() {.closure.} = proc3CallCount.inc

      let procFrames: seq[KeyFrame[ClosureProc]] = @[
        (foo1, 0.0),
        (foo2, 0.5),
        (foo3, 1.1)
      ]

      # expandMacros:
      testAnim.addNewAnimationTrack(
        someProc,
        procFrames
      )

      assertEquals(this.intVal, intFrames[0][0])
      assertEquals(this.floatVal, floatFrames[0][0])
      assertEquals(this.vec2Val, vec2Frames[0][0])
      assertEquals(this.vec3Val, vec3Frames[0][0])

      assertEquals(this.intVal, intFrames[0][0])
      assertEquals(this.floatVal, floatFrames[0][0])

      # Proc calls
      assertEquals(proc1CallCount, 0)
      assertEquals(proc2CallCount, 0)
      assertEquals(proc3CallCount, 0)

      testAnim.update(0.2)
      assertEquals(this.intVal, intFrames[0][0])
      assertAlmostEquals(this.floatVal, 1.68)

      assertEquals(proc1CallCount, 1)
      assertEquals(proc2CallCount, 0)
      assertEquals(proc3CallCount, 0)

      testAnim.update(0.5)
      assertEquals(this.intVal, intFrames[1][0])
      assertAlmostEquals(this.floatVal, 7.06666666)

      assertEquals(proc1CallCount, 1)
      assertEquals(proc2CallCount, 1)
      assertEquals(proc3CallCount, 0)

      testAnim.update(0.7)
      assertEquals(this.intVal, intFrames[2][0])
      assertAlmostEquals(this.floatVal, 11.76)

      assertEquals(proc1CallCount, 1)
      assertEquals(proc2CallCount, 1)
      assertEquals(proc3CallCount, 1)

