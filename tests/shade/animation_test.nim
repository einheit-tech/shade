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

    it "without wrap interpolation":
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
        (vec2(14.1, 124.4), 0.5),
        (vec2(19.4, 304.8), 1.1)
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

      testAnim.addNewAnimationTrack(
        someProc,
        procFrames
      )

      ### INITIAL STATE ###

      assertEquals(this.intVal, intFrames[0][0])
      assertEquals(this.floatVal, floatFrames[0][0])
      assertEquals(this.vec2Val, vec2Frames[0][0])
      assertEquals(this.vec3Val, vec3Frames[0][0])
      assertEquals(proc1CallCount, 0)
      assertEquals(proc2CallCount, 0)
      assertEquals(proc3CallCount, 0)

      ### FIRST UPDATE (after first frame ###

      var updateTime = 0.2
      testAnim.update(updateTime)

      # int
      assertEquals(this.intVal, intFrames[0].value)

      # float
      var expectedFloatVal = lerp(
        floatFrames[0].value,
        floatFrames[1].value,
        testAnim.currentTime / (floatFrames[1].time - floatFrames[0].time)
      )
      assertAlmostEquals(this.floatVal, expectedFloatVal)

      # Vec2
      var expectedVec2Val = lerp(
        vec2Frames[0].value,
        vec2Frames[1].value,
        testAnim.currentTime / (vec2Frames[1].time - vec2Frames[0].time),
      )
      assertEquals(this.vec2Val, expectedVec2Val)

      # Vec3
      var expectedVec3Val = lerp(
        vec3Frames[0].value,
        vec3Frames[1].value,
        testAnim.currentTime / (vec3Frames[1].time - vec3Frames[0].time),
      )
      assertEquals(this.vec3Val, expectedVec3Val)

      # Proc calls
      assertEquals(proc1CallCount, 1)
      assertEquals(proc2CallCount, 0)
      assertEquals(proc3CallCount, 0)

      ### SECOND UPDATE (past 2nd frame) ###

      updateTime = 0.5
      testAnim.update(updateTime)

      # int
      assertEquals(this.intVal, intFrames[1].value)

      # float
      var completionRatio = 
        (testAnim.currentTime - floatFrames[1].time) / (floatFrames[2].time - floatFrames[1].time)

      expectedFloatVal = lerp(
        floatFrames[1].value,
        floatFrames[2].value,
        completionRatio
      )
      assertAlmostEquals(this.floatVal, expectedFloatVal)

      # Vec2
      completionRatio = 
        (testAnim.currentTime - vec2Frames[1].time) / (vec2Frames[2].time - vec2Frames[1].time)
      expectedVec2Val = lerp(
        vec2Frames[1].value,
        vec2Frames[2].value,
        completionRatio
      )
      assertEquals(this.vec2Val, expectedVec2Val)

      # Vec3
      completionRatio = 
        (testAnim.currentTime - vec3Frames[1].time) / (vec3Frames[2].time - vec3Frames[1].time)
      expectedVec3Val = lerp(
        vec3Frames[1].value,
        vec3Frames[2].value,
        completionRatio
      )
      assertEquals(this.vec3Val, expectedVec3Val)

      assertEquals(proc1CallCount, 1)
      assertEquals(proc2CallCount, 1)
      assertEquals(proc3CallCount, 0)

      ### THIRD UPDATE (past 3rd and final frame, animation still playing) ###

      updateTime = 0.7
      testAnim.update(updateTime)

      # int
      assertEquals(this.intVal, intFrames[2].value)

      # float
      assertAlmostEquals(this.floatVal, floatFrames[2].value)

      # Vec2
      assertEquals(this.vec2Val, vec2Frames[2].value)

      # Vec2
      assertEquals(this.vec3Val, vec3Frames[2].value)

      assertEquals(proc1CallCount, 1)
      assertEquals(proc2CallCount, 1)
      assertEquals(proc3CallCount, 1)

      ### FOURTH UPDATE (exact start of animation after wrapping) ###

      # Update till the start of the animation.
      updateTime = testAnim.duration - testAnim.currentTime
      testAnim.update(updateTime)

      # int
      assertEquals(this.intVal, intFrames[0].value)

      # float
      assertAlmostEquals(this.floatVal, floatFrames[0].value)

      # Vec2
      assertEquals(this.vec2Val, vec2Frames[0].value)

      # Vec3
      assertEquals(this.vec3Val, vec3Frames[0].value)

      assertEquals(proc1CallCount, 2)
      assertEquals(proc2CallCount, 1)
      assertEquals(proc3CallCount, 1)

    it "with wrap interpolation":
      let testAnim = newAnimation(1.8)

      # int
      const intFrames: seq[KeyFrame[int]] = @[
        (1, 0.0),
        (2, 0.5),
        (3, 1.1)
      ]
      testAnim.addNewAnimationTrack(
        this.intVal,
        intFrames,
        true
      )

      # float
      const floatFrames: seq[KeyFrame[float]] = @[
        (0.0, 0.0),
        (4.2, 0.5),
        (12.8, 1.1)
      ]
      testAnim.addNewAnimationTrack(
        this.floatVal,
        floatFrames,
        true
      )

      # Vec2
      const vec2Frames: seq[KeyFrame[Vec2]] = @[
        (vec2(0.0, 2.1), 0.0),
        (vec2(14.1, 124.4), 0.5),
        (vec2(19.4, 304.8), 1.1)
      ]
      testAnim.addNewAnimationTrack(
        this.vec2Val,
        vec2Frames,
        true
      )

      # Vec3
      const vec3Frames: seq[KeyFrame[Vec3]] = @[
        (vec3(1.0, 2.1, 12.5), 0.0),
        (vec3(4.2, 3.2, 39.4), 0.5),
        (vec3(12.8, 34.8, 12.8), 1.1)
      ]
      testAnim.addNewAnimationTrack(
        this.vec3Val,
        vec3Frames,
        true
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

      testAnim.addNewAnimationTrack(
        someProc,
        procFrames,
        true
      )

      ### INITIAL STATE ###

      assertEquals(this.intVal, intFrames[0].value)
      assertEquals(this.floatVal, floatFrames[0].value)
      assertEquals(this.vec2Val, vec2Frames[0].value)
      assertEquals(this.vec3Val, vec3Frames[0].value)
      assertEquals(proc1CallCount, 0)
      assertEquals(proc2CallCount, 0)
      assertEquals(proc3CallCount, 0)

      ### Update past 3rd and final frame, animation still playing ###

      let
        updateTime = testAnim.duration - 0.4
        timeBetweenFrames = testAnim.duration - intFrames[2].time - intFrames[0].time
        completionRatio = (updateTime - intFrames[2].time) / timeBetweenFrames
      testAnim.update(updateTime)

      # int
      let expectedIntVal = lerp(intFrames[2].value, intFrames[0].value, completionRatio)
      assertEquals(this.intVal, expectedIntVal)

      # float
      let expectedFloatVal = lerp(floatFrames[2].value, floatFrames[0].value, completionRatio)
      assertAlmostEquals(this.floatVal, expectedFloatVal)

      # Vec2
      let expectedVec2Val = lerp(vec2Frames[2].value, vec2Frames[0].value, completionRatio)
      assertEquals(this.vec2Val, expectedVec2Val)

      # Vec3
      let expectedVec3Val = lerp(vec3Frames[2].value, vec3Frames[0].value, completionRatio)
      assertEquals(this.vec3Val, expectedVec3Val)

      assertEquals(proc1CallCount, 1)
      assertEquals(proc2CallCount, 1)
      assertEquals(proc3CallCount, 1)

