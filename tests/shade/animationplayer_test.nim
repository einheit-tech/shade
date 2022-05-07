import
  ../../src/shade,
  nimtest,
  math

describe "AnimationPlayer":

  type FakeNode* = ref object
    intVal*: int
    floatVal*: float
    boolVal*: bool
    vecVal*: Vector
    ivecVal*: IVector
    colorVal*: Color

  describe "Animates all possible field types":
    let
      startingIntVal: int = 8
      startingFloatVal: float = 2.0
      startingBoolVal: bool = false
      startingVectorVal: Vector = vector(2.9, 32.7)
      startingIVectorVal: IVector = ivector(2, -15)
      startingColor: Color = BLACK

    proc initFakeNode(fakeNode: FakeNode) =
      fakeNode.intVal = startingIntVal
      fakeNode.floatVal = startingFloatVal
      fakeNode.boolVal = startingBoolVal
      fakeNode.vecVal = startingVectorVal
      fakeNode.ivecVal = startingIVectorVal
      fakeNode.colorVal = startingColor

    proc newFakeNode(): FakeNode =
      result = FakeNode()
      initFakeNode(result)

    it "without wrap interpolation":
      let 
        testAnim = newAnimation(1.8, true)
        animPlayer = newAnimationPlayer(("test", testAnim))
        fakeNode = newFakeNode()

      animPlayer.play("test")

      # int
      const intFrames: seq[KeyFrame[int]] = @[
        (1, 0.0),
        (2, 0.5),
        (3, 1.1)
      ]
      testAnim.addNewAnimationTrack(
        fakeNode.intVal,
        intFrames
      )

      # float
      const floatFrames: seq[KeyFrame[float]] = @[
        (0.0, 0.0),
        (4.2, 0.5),
        (12.8, 1.1)
      ]
      testAnim.addNewAnimationTrack(
        fakeNode.floatVal,
        floatFrames
      )

      # Vector
      const vecFrames: seq[KeyFrame[Vector]] = @[
        (vector(0.0, 2.1), 0.0),
        (vector(14.1, 124.4), 0.5),
        (vector(19.4, 304.8), 1.1)
      ]
      testAnim.addNewAnimationTrack(
        fakeNode.vecVal,
        vecFrames
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

      assertEquals(fakeNode.intVal, startingIntVal)
      assertEquals(fakeNode.floatVal, startingFloatVal)
      assertEquals(fakeNode.vecVal, startingVectorVal)
      assertEquals(proc1CallCount, 0)
      assertEquals(proc2CallCount, 0)
      assertEquals(proc3CallCount, 0)

      ### FIRST UPDATE (after first frame ###

      var updateTime = 0.2
      animPlayer.update(updateTime)

      # int
      assertEquals(fakeNode.intVal, intFrames[0].value)

      # float
      var expectedFloatVal = lerp(
        floatFrames[0].value,
        floatFrames[1].value,
        animPlayer.currentTime / (floatFrames[1].time - floatFrames[0].time)
      )
      assertAlmostEquals(fakeNode.floatVal, expectedFloatVal)

      # Vector
      var expectedVectorVal = lerp(
        vecFrames[0].value,
        vecFrames[1].value,
        animPlayer.currentTime / (vecFrames[1].time - vecFrames[0].time),
      )
      assertEquals(fakeNode.vecVal, expectedVectorVal)

      # Proc calls
      assertEquals(proc1CallCount, 1)
      assertEquals(proc2CallCount, 0)
      assertEquals(proc3CallCount, 0)

      ### SECOND UPDATE (past 2nd frame) ###

      updateTime = 0.5
      animPlayer.update(updateTime)

      # int
      assertEquals(fakeNode.intVal, intFrames[1].value)

      # float
      var completionRatio = 
        (animPlayer.currentTime - floatFrames[1].time) / (floatFrames[2].time - floatFrames[1].time)

      expectedFloatVal = lerp(
        floatFrames[1].value,
        floatFrames[2].value,
        completionRatio
      )
      assertAlmostEquals(fakeNode.floatVal, expectedFloatVal)

      # Vector
      completionRatio = 
        (animPlayer.currentTime - vecFrames[1].time) / (vecFrames[2].time - vecFrames[1].time)
      expectedVectorVal = lerp(
        vecFrames[1].value,
        vecFrames[2].value,
        completionRatio
      )
      assertEquals(fakeNode.vecVal, expectedVectorVal)

      assertEquals(proc1CallCount, 1)
      assertEquals(proc2CallCount, 1)
      assertEquals(proc3CallCount, 0)

      ### THIRD UPDATE (past 3rd and final frame, animation still playing) ###

      updateTime = 0.7
      animPlayer.update(updateTime)

      # int
      assertEquals(fakeNode.intVal, intFrames[2].value)

      # float
      assertAlmostEquals(fakeNode.floatVal, floatFrames[2].value)

      # Vector
      assertEquals(fakeNode.vecVal, vecFrames[2].value)

      assertEquals(proc1CallCount, 1)
      assertEquals(proc2CallCount, 1)
      assertEquals(proc3CallCount, 1)

      ### FOURTH UPDATE (exact start of animation after wrapping) ###

      # Update till the start of the animation.
      updateTime = testAnim.duration - animPlayer.currentTime
      animPlayer.update(updateTime)

      # int
      assertEquals(fakeNode.intVal, intFrames[0].value)

      # float
      assertAlmostEquals(fakeNode.floatVal, floatFrames[0].value)

      # Vector
      assertEquals(fakeNode.vecVal, vecFrames[0].value)

      # TODO: Wrapping proc tracks.
      assertEquals(proc1CallCount, 2)
      assertEquals(proc2CallCount, 1)
      assertEquals(proc3CallCount, 1)

    it "with wrap interpolation":
      let
        testAnim = newAnimation(1.8, true)
        animPlayer = newAnimationPlayer(("test", testAnim))
        fakeNode = newFakeNode()

      animPlayer.play("test")

      # int
      const intFrames: seq[KeyFrame[int]] = @[
        (1, 0.0),
        (2, 0.5),
        (3, 1.1)
      ]
      testAnim.addNewAnimationTrack(
        fakeNode.intVal,
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
        fakeNode.floatVal,
        floatFrames,
        true
      )

      # Vector
      const vecFrames: seq[KeyFrame[Vector]] = @[
        (vector(0.0, 2.1), 0.0),
        (vector(14.1, 124.4), 0.5),
        (vector(19.4, 304.8), 1.1)
      ]
      testAnim.addNewAnimationTrack(
        fakeNode.vecVal,
        vecFrames,
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

      assertEquals(fakeNode.intVal, startingIntVal)
      assertEquals(fakeNode.floatVal, startingFloatVal)
      assertEquals(fakeNode.vecVal, startingVectorVal)
      assertEquals(proc1CallCount, 0)
      assertEquals(proc2CallCount, 0)
      assertEquals(proc3CallCount, 0)

      ### Update past 3rd and final frame, animation still playing ###

      let
        updateTime = testAnim.duration - 0.4
        timeBetweenFrames = testAnim.duration - intFrames[2].time - intFrames[0].time
        completionRatio = (updateTime - intFrames[2].time) / timeBetweenFrames
      animPlayer.update(updateTime)

      # int
      let expectedIntVal = lerp(intFrames[2].value, intFrames[0].value, completionRatio)
      assertEquals(fakeNode.intVal, expectedIntVal)

      # float
      let expectedFloatVal = lerp(floatFrames[2].value, floatFrames[0].value, completionRatio)
      assertAlmostEquals(fakeNode.floatVal, expectedFloatVal)

      # Vector
      let expectedVectorVal = lerp(vecFrames[2].value, vecFrames[0].value, completionRatio)
      assertEquals(fakeNode.vecVal, expectedVectorVal)

      assertEquals(proc1CallCount, 1)
      assertEquals(proc2CallCount, 1)
      assertEquals(proc3CallCount, 1)

    it "works with single proc frame at 0.0 seconds":
      let testAnim = newAnimation(1.8, true)
      let animPlayer = newAnimationPlayer(("test", testAnim))
      animPlayer.play("test")

      var proc1CallCount = 0
      proc foo1() {.closure.} = proc1CallCount.inc
      let frames: seq[KeyFrame[ClosureProc]] = @[(foo1, 0.0)]
      testAnim.addProcTrack(frames)

      # Initial state
      assertEquals(proc1CallCount, 0)

      animPlayer.update(0.01)

      assertEquals(proc1CallCount, 1)

    it "works with single non-proc frame at 0.0 seconds":
      let 
        testAnim = newAnimation(1.8, true)
        fakeNode = newFakeNode()

      const intFrames: seq[KeyFrame[int]] = @[(1, 0.0)]
      testAnim.addNewAnimationTrack(fakeNode.intVal, intFrames)

      let animPlayer = newAnimationPlayer(("test", testAnim))
      animPlayer.play("test")

      # Initial state
      assertEquals(fakeNode.intVal, startingIntVal)

      animPlayer.update(0.0)
      assertEquals(fakeNode.intVal, intFrames[0][0])

      animPlayer.update(0.0)
      assertEquals(fakeNode.intVal, intFrames[0][0])

  describe "AnimationTrack[ClosureProc]":

    describe "Non-looping":

      it "Calls a single proc at 0.0":
        let testAnim = newAnimation(1.8, false)
        let animPlayer = newAnimationPlayer(("test", testAnim))
        animPlayer.play("test")

        var procCallCount = 0
        proc foo1() {.closure.} = procCallCount.inc
        let procFrames: seq[KeyFrame[ClosureProc]] = @[(foo1, 0.0)]

        testAnim.addProcTrack(procFrames)

        # Initial state
        assertEquals(procCallCount, 0)

        animPlayer.update(0.01)
        assertEquals(procCallCount, 1)

      it "Calls a single proc at 0.0 only once":
        let testAnim = newAnimation(1.8, false)
        let animPlayer = newAnimationPlayer(("test", testAnim))
        animPlayer.play("test")

        var procCallCount = 0
        proc foo1() {.closure.} = procCallCount.inc
        let procFrames: seq[KeyFrame[ClosureProc]] = @[(foo1, 0.0)]

        testAnim.addProcTrack(procFrames)

        # Initial state
        assertEquals(procCallCount, 0)

        animPlayer.update(0.0)
        assertEquals(procCallCount, 1)

        animPlayer.update(0.0)
        assertEquals(procCallCount, 1)

      it "Calls a single proc at the end of a track and animation":
        let testAnim = newAnimation(1.8, false)
        let animPlayer = newAnimationPlayer(("test", testAnim))
        animPlayer.play("test")

        var procCallCount = 0
        proc foo1() {.closure.} = procCallCount.inc
        let procFrames: seq[KeyFrame[ClosureProc]] = @[(foo1, testAnim.duration)]

        testAnim.addProcTrack(procFrames)

        # Initial state
        assertEquals(procCallCount, 0)

        animPlayer.update(0.01)
        assertEquals(procCallCount, 0)

        animPlayer.update(testAnim.duration - 0.01)
        assertEquals(procCallCount, 1)

      it "Calls a single proc at the end of a track, before the animation has ended":
        let testAnim = newAnimation(1.8, false)
        let animPlayer = newAnimationPlayer(("test", testAnim))
        animPlayer.play("test")

        var procCallCount = 0
        proc foo1() {.closure.} = procCallCount.inc
        let procFrames: seq[KeyFrame[ClosureProc]] = @[(foo1, 1.1)]

        testAnim.addProcTrack(procFrames)

        # Initial state
        assertEquals(procCallCount, 0)

        animPlayer.update(0.1)
        assertEquals(procCallCount, 0)

        animPlayer.update(1.0)
        assertEquals(procCallCount, 1)

      it "Calls multiple procs at the right times":
        let testAnim = newAnimation(1.8, false)
        let animPlayer = newAnimationPlayer(("test", testAnim))
        animPlayer.play("test")

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

        animPlayer.update(0)
        assertEquals(proc1CallCount, 0)
        assertEquals(proc2CallCount, 0)
        assertEquals(proc3CallCount, 0)

        animPlayer.update(0.01)
        assertEquals(proc1CallCount, 0)
        assertEquals(proc2CallCount, 0)
        assertEquals(proc3CallCount, 0)

        animPlayer.update(0.1)
        assertEquals(proc1CallCount, 1)
        assertEquals(proc2CallCount, 0)
        assertEquals(proc3CallCount, 0)

    describe "Looping":
      it "Calls a single proc at 0.0":
        let testAnim = newAnimation(1.8, true)
        let animPlayer = newAnimationPlayer(("test", testAnim))
        animPlayer.play("test")

        var procCallCount = 0
        proc foo1() {.closure.} = procCallCount.inc
        let procFrames: seq[KeyFrame[ClosureProc]] = @[(foo1, 0.0)]

        testAnim.addProcTrack(procFrames)

        # Initial state
        assertEquals(procCallCount, 0)

        animPlayer.update(0.01)
        assertEquals(procCallCount, 1)

      it "Calls a single proc at 0.0 only once":
        let testAnim = newAnimation(1.8, true)
        let animPlayer = newAnimationPlayer(("test", testAnim))
        animPlayer.play("test")

        var procCallCount = 0
        proc foo1() {.closure.} = procCallCount.inc
        let procFrames: seq[KeyFrame[ClosureProc]] = @[(foo1, 0.0)]

        testAnim.addProcTrack(procFrames)

        # Initial state
        assertEquals(procCallCount, 0)

        animPlayer.update(0.0)
        assertEquals(procCallCount, 1)

        animPlayer.update(0.0)
        assertEquals(procCallCount, 1)

      it "Calls a single proc at the end of a track and animation":
        let testAnim = newAnimation(1.8, true)
        let animPlayer = newAnimationPlayer(("test", testAnim))
        animPlayer.play("test")

        var procCallCount = 0
        proc foo1() {.closure.} = procCallCount.inc
        let procFrames: seq[KeyFrame[ClosureProc]] = @[(foo1, testAnim.duration)]

        testAnim.addProcTrack(procFrames)

        # Initial state
        assertEquals(procCallCount, 0)

        animPlayer.update(0.01)
        assertEquals(procCallCount, 0)

        animPlayer.update(testAnim.duration - 0.01)
        assertEquals(procCallCount, 1)

      it "Calls a single proc at the end of a track, before the animation has ended":
        let testAnim = newAnimation(1.8, true)
        let animPlayer = newAnimationPlayer(("test", testAnim))
        animPlayer.play("test")
        var procCallCount = 0

        proc foo1() {.closure.} = procCallCount.inc
        let procFrames: seq[KeyFrame[ClosureProc]] = @[(foo1, 1.1)]

        testAnim.addProcTrack(procFrames)

        # Initial state
        assertEquals(procCallCount, 0)

        animPlayer.update(0.1)
        assertEquals(procCallCount, 0)

        animPlayer.update(1.0)
        assertEquals(procCallCount, 1)

      it "Calls multiple procs at the right times":
        let testAnim = newAnimation(1.8, true)
        let animPlayer = newAnimationPlayer(("test", testAnim))
        animPlayer.play("test")

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

        animPlayer.update(0)
        assertEquals(proc1CallCount, 0)
        assertEquals(proc2CallCount, 0)
        assertEquals(proc3CallCount, 0)

        animPlayer.update(0.01)
        assertEquals(proc1CallCount, 0)
        assertEquals(proc2CallCount, 0)
        assertEquals(proc3CallCount, 0)

        animPlayer.update(0.1)
        assertEquals(proc1CallCount, 1)
        assertEquals(proc2CallCount, 0)
        assertEquals(proc3CallCount, 0)

