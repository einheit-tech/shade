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

    it "works with single proc frame at 0.0 seconds":
      let testAnim = newAnimation(1.8, true)

      var proc1CallCount = 0
      proc foo1() {.closure.} = proc1CallCount.inc
      let frames: seq[KeyFrame[ClosureProc]] = @[(foo1, 0.0)]
      testAnim.addProcTrack(frames)

      let animPlayer = newAnimationPlayer(("test", testAnim))
      animPlayer.play("test")

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

