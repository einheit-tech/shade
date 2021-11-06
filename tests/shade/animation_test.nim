import
  shade,
  math

describe "Animation":

  type FakeNode* = ref object
    intVal*: int
    floatVal*: float
    vec2Val*: DVec2
    vec3Val*: DVec3

  describe "Animates all possible field types":
    var callCount = 0

    let
      startingIntVal: int = 8
      startingFloatVal: float = 2.0
      startingDVec2Val: DVec2 = dvec2(2.9, 32.7)
      startingDVec3Val: DVec3 = dvec3(48.2, 831.0, 12.8)

    var this = FakeNode()

    proc resetThis() =
      this = FakeNode(
        intVal: startingIntVal,
        floatVal: startingFloatVal,
        vec2Val: startingDVec2Val,
        vec3Val: startingDVec3Val
      )

    it "without wrap interpolation":
      resetThis()
      let testAnim = newAnimation(1.8, true)

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

      # DVec2
      const vec2Frames: seq[KeyFrame[DVec2]] = @[
        (dvec2(0.0, 2.1), 0.0),
        (dvec2(14.1, 124.4), 0.5),
        (dvec2(19.4, 304.8), 1.1)
      ]
      testAnim.addNewAnimationTrack(
        this.vec2Val,
        vec2Frames
      )

      # DVec3
      const vec3Frames: seq[KeyFrame[DVec3]] = @[
        (dvec3(1.0, 2.1, 12.5), 0.0),
        (dvec3(4.2, 3.2, 39.4), 0.5),
        (dvec3(12.8, 34.8, 12.8), 1.1)
      ]
      testAnim.addNewAnimationTrack(
        this.vec3Val,
        vec3Frames
      )

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

      testAnim.addProcTrack(procFrames)

      ### INITIAL STATE ###

      assertEquals(this.intVal, startingIntVal)
      assertEquals(this.floatVal, startingFloatVal)
      assertEquals(this.vec2Val, startingDVec2Val)
      assertEquals(this.vec3Val, startingDVec3Val)
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

      # DVec2
      var expectedDVec2Val = lerp(
        vec2Frames[0].value,
        vec2Frames[1].value,
        testAnim.currentTime / (vec2Frames[1].time - vec2Frames[0].time),
      )
      assertEquals(this.vec2Val, expectedDVec2Val)

      # DVec3
      var expectedDVec3Val = lerp(
        vec3Frames[0].value,
        vec3Frames[1].value,
        testAnim.currentTime / (vec3Frames[1].time - vec3Frames[0].time),
      )
      assertEquals(this.vec3Val, expectedDVec3Val)

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

      # DVec2
      completionRatio = 
        (testAnim.currentTime - vec2Frames[1].time) / (vec2Frames[2].time - vec2Frames[1].time)
      expectedDVec2Val = lerp(
        vec2Frames[1].value,
        vec2Frames[2].value,
        completionRatio
      )
      assertEquals(this.vec2Val, expectedDVec2Val)

      # DVec3
      completionRatio = 
        (testAnim.currentTime - vec3Frames[1].time) / (vec3Frames[2].time - vec3Frames[1].time)
      expectedDVec3Val = lerp(
        vec3Frames[1].value,
        vec3Frames[2].value,
        completionRatio
      )
      assertEquals(this.vec3Val, expectedDVec3Val)

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

      # DVec2
      assertEquals(this.vec2Val, vec2Frames[2].value)

      # DVec2
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

      # DVec2
      assertEquals(this.vec2Val, vec2Frames[0].value)

      # DVec3
      assertEquals(this.vec3Val, vec3Frames[0].value)

      # TODO: Wrapping proc tracks.
      assertEquals(proc1CallCount, 2)
      assertEquals(proc2CallCount, 1)
      assertEquals(proc3CallCount, 1)

    it "with wrap interpolation":
      resetThis()
      let testAnim = newAnimation(1.8, true)

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

      # DVec2
      const vec2Frames: seq[KeyFrame[DVec2]] = @[
        (dvec2(0.0, 2.1), 0.0),
        (dvec2(14.1, 124.4), 0.5),
        (dvec2(19.4, 304.8), 1.1)
      ]
      testAnim.addNewAnimationTrack(
        this.vec2Val,
        vec2Frames,
        true
      )

      # DVec3
      const vec3Frames: seq[KeyFrame[DVec3]] = @[
        (dvec3(1.0, 2.1, 12.5), 0.0),
        (dvec3(4.2, 3.2, 39.4), 0.5),
        (dvec3(12.8, 34.8, 12.8), 1.1)
      ]
      testAnim.addNewAnimationTrack(
        this.vec3Val,
        vec3Frames,
        true
      )

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

      testAnim.addProcTrack(procFrames)

      ### INITIAL STATE ###

      assertEquals(this.intVal, startingIntVal)
      assertEquals(this.floatVal, startingFloatVal)
      assertEquals(this.vec2Val, startingDVec2Val)
      assertEquals(this.vec3Val, startingDVec3Val)
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

      # DVec2
      let expectedDVec2Val = lerp(vec2Frames[2].value, vec2Frames[0].value, completionRatio)
      assertEquals(this.vec2Val, expectedDVec2Val)

      # DVec3
      let expectedDVec3Val = lerp(vec3Frames[2].value, vec3Frames[0].value, completionRatio)
      assertEquals(this.vec3Val, expectedDVec3Val)

      assertEquals(proc1CallCount, 1)
      assertEquals(proc2CallCount, 1)
      assertEquals(proc3CallCount, 1)

    it "works with single proc frame at 0.0 seconds":
      resetThis()
      let testAnim = newAnimation(1.8, true)

      var proc1CallCount = 0
      proc foo1() {.closure.} = proc1CallCount.inc

      let procFrames: seq[KeyFrame[ClosureProc]] = @[(foo1, 0.0)]

      testAnim.addProcTrack(procFrames)

      # Initial state
      assertEquals(proc1CallCount, 0)

      testAnim.update(0.01)

      assertEquals(proc1CallCount, 1)

    it "works with single non-proc frame at 0.0 seconds":
      resetThis()
      let testAnim = newAnimation(1.8, true)

      # int
      const intFrames: seq[KeyFrame[int]] = @[(1, 0.0)]
      testAnim.addNewAnimationTrack(
        this.intVal,
        intFrames
      )

      # Initial state
      assertEquals(this.intVal, startingIntVal)

      testAnim.update(0.0)
      assertEquals(this.intVal, intFrames[0][0])

      testAnim.update(0.0)
      assertEquals(this.intVal, intFrames[0][0])

  describe "AnimationTrack[ClosureProc]":
    describe "Non-looping":
      it "Calls a single proc at 0.0":
        let testAnim = newAnimation(1.8, false)
        var procCallCount = 0

        proc foo1() {.closure.} = procCallCount.inc
        let procFrames: seq[KeyFrame[ClosureProc]] = @[(foo1, 0.0)]

        testAnim.addProcTrack(procFrames)

        # Initial state
        assertEquals(procCallCount, 0)

        testAnim.update(0.01)
        assertEquals(procCallCount, 1)

      it "Calls a single proc at 0.0 only once":
        let testAnim = newAnimation(1.8, false)
        var procCallCount = 0

        proc foo1() {.closure.} = procCallCount.inc
        let procFrames: seq[KeyFrame[ClosureProc]] = @[(foo1, 0.0)]

        testAnim.addProcTrack(procFrames)

        # Initial state
        assertEquals(procCallCount, 0)

        testAnim.update(0.0)
        assertEquals(procCallCount, 1)

        testAnim.update(0.0)
        assertEquals(procCallCount, 1)

      it "Calls a single proc at the end of a track and animation":
        let testAnim = newAnimation(1.8, false)
        var procCallCount = 0

        proc foo1() {.closure.} = procCallCount.inc
        let procFrames: seq[KeyFrame[ClosureProc]] = @[(foo1, testAnim.duration)]

        testAnim.addProcTrack(procFrames)

        # Initial state
        assertEquals(procCallCount, 0)

        testAnim.update(0.01)
        assertEquals(procCallCount, 0)

        testAnim.update(testAnim.duration - 0.01)
        assertEquals(procCallCount, 1)

      it "Calls a single proc at the end of a track, before the animation has ended":
        let testAnim = newAnimation(1.8, false)
        var procCallCount = 0

        proc foo1() {.closure.} = procCallCount.inc
        let procFrames: seq[KeyFrame[ClosureProc]] = @[(foo1, 1.1)]

        testAnim.addProcTrack(procFrames)

        # Initial state
        assertEquals(procCallCount, 0)

        testAnim.update(0.1)
        assertEquals(procCallCount, 0)

        testAnim.update(1.0)
        assertEquals(procCallCount, 1)

      it "Calls multiple procs at the right times":
        let testAnim = newAnimation(1.8, false)
        var
          proc1CallCount = 0
          proc2CallCount = 0
          proc3CallCount = 0

        proc foo1() {.closure.} = proc1CallCount.inc
        proc foo2() {.closure.} = proc2CallCount.inc
        proc foo3() {.closure.} = proc3CallCount.inc

        let procFrames: seq[KeyFrame[ClosureProc]] = @[
          (foo1, 0.1),
          (foo2, 0.5),
          (foo3, 1.6)
        ]

        testAnim.addProcTrack(procFrames)

        # Initial state
        assertEquals(proc1CallCount, 0)
        assertEquals(proc2CallCount, 0)
        assertEquals(proc3CallCount, 0)

        testAnim.update(0)
        assertEquals(proc1CallCount, 0)
        assertEquals(proc2CallCount, 0)
        assertEquals(proc3CallCount, 0)

        testAnim.update(0.01)
        assertEquals(proc1CallCount, 0)
        assertEquals(proc2CallCount, 0)
        assertEquals(proc3CallCount, 0)

        testAnim.update(0.1)
        assertEquals(proc1CallCount, 1)
        assertEquals(proc2CallCount, 0)
        assertEquals(proc3CallCount, 0)

    describe "Looping":
      it "Calls a single proc at 0.0":
        let testAnim = newAnimation(1.8, true)
        var procCallCount = 0

        proc foo1() {.closure.} = procCallCount.inc
        let procFrames: seq[KeyFrame[ClosureProc]] = @[(foo1, 0.0)]

        testAnim.addProcTrack(procFrames)

        # Initial state
        assertEquals(procCallCount, 0)

        testAnim.update(0.01)
        assertEquals(procCallCount, 1)

      it "Calls a single proc at 0.0 only once":
        let testAnim = newAnimation(1.8, true)
        var procCallCount = 0

        proc foo1() {.closure.} = procCallCount.inc
        let procFrames: seq[KeyFrame[ClosureProc]] = @[(foo1, 0.0)]

        testAnim.addProcTrack(procFrames)

        # Initial state
        assertEquals(procCallCount, 0)

        testAnim.update(0.0)
        assertEquals(procCallCount, 1)

        testAnim.update(0.0)
        assertEquals(procCallCount, 1)

      it "Calls a single proc at the end of a track and animation":
        let testAnim = newAnimation(1.8, true)
        var procCallCount = 0

        proc foo1() {.closure.} = procCallCount.inc
        let procFrames: seq[KeyFrame[ClosureProc]] = @[(foo1, testAnim.duration)]

        testAnim.addProcTrack(procFrames)

        # Initial state
        assertEquals(procCallCount, 0)

        testAnim.update(0.01)
        assertEquals(procCallCount, 0)

        # TODO: Issue here is that we've hit 0.0 (from modulo)
        testAnim.update(testAnim.duration - 0.01)
        assertEquals(procCallCount, 1)

      it "Calls a single proc at the end of a track, before the animation has ended":
        let testAnim = newAnimation(1.8, true)
        var procCallCount = 0

        proc foo1() {.closure.} = procCallCount.inc
        let procFrames: seq[KeyFrame[ClosureProc]] = @[(foo1, 1.1)]

        testAnim.addProcTrack(procFrames)

        # Initial state
        assertEquals(procCallCount, 0)

        testAnim.update(0.1)
        assertEquals(procCallCount, 0)

        testAnim.update(1.0)
        assertEquals(procCallCount, 1)

      it "Calls multiple procs at the right times":
        let testAnim = newAnimation(1.8, true)
        var
          proc1CallCount = 0
          proc2CallCount = 0
          proc3CallCount = 0

        proc foo1() {.closure.} = proc1CallCount.inc
        proc foo2() {.closure.} = proc2CallCount.inc
        proc foo3() {.closure.} = proc3CallCount.inc

        let procFrames: seq[KeyFrame[ClosureProc]] = @[
          (foo1, 0.1),
          (foo2, 0.5),
          (foo3, 1.6)
        ]

        testAnim.addProcTrack(procFrames)

        # Initial state
        assertEquals(proc1CallCount, 0)
        assertEquals(proc2CallCount, 0)
        assertEquals(proc3CallCount, 0)

        testAnim.update(0)
        assertEquals(proc1CallCount, 0)
        assertEquals(proc2CallCount, 0)
        assertEquals(proc3CallCount, 0)

        testAnim.update(0.01)
        assertEquals(proc1CallCount, 0)
        assertEquals(proc2CallCount, 0)
        assertEquals(proc3CallCount, 0)

        testAnim.update(0.1)
        assertEquals(proc1CallCount, 1)
        assertEquals(proc2CallCount, 0)
        assertEquals(proc3CallCount, 0)


