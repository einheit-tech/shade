import
  nimtest,
  shade,
  math

describe "AnimationPlayer":

  type FakeNode* = ref object
    intVal*: int
    floatVal*: float
    vec2Val*: Vector

  describe "Animates all possible field types":
    let
      startingIntVal: int = 8
      startingFloatVal: float = 2.0
      startingVectorVal: Vector = vector(2.9, 32.7)

    var this = FakeNode()

    proc resetThis() =
      this = FakeNode(
        intVal: startingIntVal,
        floatVal: startingFloatVal,
        vec2Val: startingVectorVal,
      )

    # it "int frames without wrap interpolation":
    #   resetThis()
    #   let testAnim = newAnimation(1.8)

    #   # int
    #   const intFrames: seq[KeyFrame[int]] = @[
    #     (1, 0.0),
    #     (2, 0.5),
    #     (3, 1.1)
    #   ]
    #   testAnim.addNewAnimationTrack(
    #     this.intVal,
    #     intFrames
    #   )

    #   var
    #     currentTime = 0.0
    #     deltaTime = 0.0

    #   block initialState:
    #     assertEquals(this.intVal, startingIntVal)

    #   block firstUpdate:
    #     deltaTime = 0.2
    #     currentTime += deltaTime
    #     testAnim.animateToTime(currentTime, deltaTime)
    #     assertEquals(this.intVal, intFrames[0].value)

    #   block secondUpdate:
    #     deltaTime = 0.3
    #     currentTime += deltaTime
    #     testAnim.animateToTime(currentTime, deltaTime)
    #     assertEquals(this.intVal, intFrames[1].value)

    #   block thirdUpdate:
    #     deltaTime = 0.7
    #     currentTime += deltaTime
    #     testAnim.animateToTime(currentTime, deltaTime)
    #     assertEquals(this.intVal, intFrames[2].value)

    #   block fourthUpdate:
    #     # Update till the start of the animation.
    #     deltaTime = testAnim.duration - currentTime
    #     currentTime += deltaTime
    #     testAnim.animateToTime(currentTime, deltaTime)
    #     assertEquals(this.intVal, intFrames[2].value)

    it "without wrap interpolation":
      resetThis()
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

      # Vector
      const vec2Frames: seq[KeyFrame[Vector]] = @[
        (vector(0.0, 2.1), 0.0),
        (vector(14.1, 124.4), 0.5),
        (vector(19.4, 304.8), 1.1)
      ]
      testAnim.addNewAnimationTrack(
        this.vec2Val,
        vec2Frames
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
      # 0.5 -> 1.2

      testAnim.addProcTrack(procFrames)

      ### INITIAL STATE ###

      assertEquals(this.intVal, startingIntVal)
      assertEquals(this.floatVal, startingFloatVal)
      assertEquals(this.vec2Val, startingVectorVal)
      assertEquals(proc1CallCount, 0)
      assertEquals(proc2CallCount, 0)
      assertEquals(proc3CallCount, 0)

      ### FIRST UPDATE (after first frame) ###

      var
        currentTime = 0.0
        deltaTime = 0.2

      currentTime += deltaTime
      testAnim.animateToTime(currentTime, deltaTime)

      # int
      assertEquals(this.intVal, intFrames[0].value)

      # float
      var expectedFloatVal = lerp(
        floatFrames[0].value,
        floatFrames[1].value,
        currentTime / (floatFrames[1].time - floatFrames[0].time)
      )
      assertAlmostEquals(this.floatVal, expectedFloatVal)

      # Vector
      var expectedVectorVal = lerp(
        vec2Frames[0].value,
        vec2Frames[1].value,
        currentTime / (vec2Frames[1].time - vec2Frames[0].time),
      )
      assertEquals(this.vec2Val, expectedVectorVal)

      # Proc calls
      assertEquals(proc1CallCount, 1)
      assertEquals(proc2CallCount, 0)
      assertEquals(proc3CallCount, 0)

      ### SECOND UPDATE (past 2nd frame) ###

      deltaTime = 0.3
      currentTime += deltaTime
      testAnim.animateToTime(currentTime, deltaTime)

      # int
      assertEquals(this.intVal, intFrames[1].value)

      # float
      var completionRatio = 
        (currentTime - floatFrames[1].time) / (floatFrames[2].time - floatFrames[1].time)

      expectedFloatVal = lerp(
        floatFrames[1].value,
        floatFrames[2].value,
        completionRatio
      )
      assertAlmostEquals(this.floatVal, expectedFloatVal)

      # Vector
      completionRatio = 
        (currentTime - vec2Frames[1].time) / (vec2Frames[2].time - vec2Frames[1].time)
      expectedVectorVal = lerp(
        vec2Frames[1].value,
        vec2Frames[2].value,
        completionRatio
      )
      assertEquals(this.vec2Val, expectedVectorVal)

      assertEquals(proc1CallCount, 1)
      assertEquals(proc2CallCount, 1)
      assertEquals(proc3CallCount, 0)

      ### THIRD UPDATE (past 3rd and final frame, animation still playing) ###

      deltaTime = 0.7
      currentTime += deltaTime
      testAnim.animateToTime(currentTime, deltaTime)

      # int
      assertEquals(this.intVal, intFrames[2].value)

      # float
      assertAlmostEquals(this.floatVal, floatFrames[2].value)

      # Vector
      assertEquals(this.vec2Val, vec2Frames[2].value)

      echo "currentTime: ", currentTime
      echo "deltaTime: ", deltaTime
      assertEquals(proc1CallCount, 1)
      assertEquals(proc2CallCount, 1)
      assertEquals(proc3CallCount, 1)

      ### FOURTH UPDATE (exact start of animation after wrapping) ###

      # Update till the start of the animation.
      deltaTime = testAnim.duration - currentTime
      currentTime += deltaTime
      testAnim.animateToTime(currentTime, deltaTime)

      # int
      assertEquals(this.intVal, intFrames[0].value)

      # float
      assertAlmostEquals(this.floatVal, floatFrames[0].value)

      # Vector
      assertEquals(this.vec2Val, vec2Frames[0].value)

      # TODO: Wrapping proc tracks.
      assertEquals(proc1CallCount, 2)
      assertEquals(proc2CallCount, 1)
      assertEquals(proc3CallCount, 1)

    # it "with wrap interpolation":
    #   resetThis()
    #   let testAnim = newAnimation(1.8)

    #   # int
    #   const intFrames: seq[KeyFrame[int]] = @[
    #     (1, 0.0),
    #     (2, 0.5),
    #     (3, 1.1)
    #   ]
    #   testAnim.addNewAnimationTrack(
    #     this.intVal,
    #     intFrames,
    #     true
    #   )

    #   # float
    #   const floatFrames: seq[KeyFrame[float]] = @[
    #     (0.0, 0.0),
    #     (4.2, 0.5),
    #     (12.8, 1.1)
    #   ]
    #   testAnim.addNewAnimationTrack(
    #     this.floatVal,
    #     floatFrames,
    #     true
    #   )

    #   # Vector
    #   const vec2Frames: seq[KeyFrame[Vector]] = @[
    #     (vector(0.0, 2.1), 0.0),
    #     (vector(14.1, 124.4), 0.5),
    #     (vector(19.4, 304.8), 1.1)
    #   ]
    #   testAnim.addNewAnimationTrack(
    #     this.vec2Val,
    #     vec2Frames,
    #     true
    #   )

    #   var
    #     proc1CallCount = 0
    #     proc2CallCount = 0
    #     proc3CallCount = 0

    #   proc foo1() {.closure.} = proc1CallCount.inc
    #   proc foo2() {.closure.} = proc2CallCount.inc
    #   proc foo3() {.closure.} = proc3CallCount.inc

    #   let procFrames: seq[KeyFrame[ClosureProc]] = @[
    #     (foo1, 0.0),
    #     (foo2, 0.5),
    #     (foo3, 1.1)
    #   ]

    #   testAnim.addProcTrack(procFrames)

    #   ### INITIAL STATE ###

    #   assertEquals(this.intVal, startingIntVal)
    #   assertEquals(this.floatVal, startingFloatVal)
    #   assertEquals(this.vec2Val, startingVectorVal)
    #   assertEquals(proc1CallCount, 0)
    #   assertEquals(proc2CallCount, 0)
    #   assertEquals(proc3CallCount, 0)

    #   ### Update past 3rd and final frame, animation still playing ###

    #   let
    #     deltaTime = testAnim.duration - 0.4
    #     currentTime = testAnim.duration
    #     timeBetweenFrames = testAnim.duration - intFrames[2].time - intFrames[0].time
    #     completionRatio = (deltaTime - intFrames[2].time) / timeBetweenFrames
    #   testAnim.animateToTime(currentTime, deltaTime)

    #   # int
    #   let expectedIntVal = lerp(intFrames[2].value, intFrames[0].value, completionRatio)
    #   assertEquals(this.intVal, expectedIntVal)

    #   # float
    #   let expectedFloatVal = lerp(floatFrames[2].value, floatFrames[0].value, completionRatio)
    #   assertAlmostEquals(this.floatVal, expectedFloatVal)

    #   # Vector
    #   let expectedVectorVal = lerp(vec2Frames[2].value, vec2Frames[0].value, completionRatio)
    #   assertEquals(this.vec2Val, expectedVectorVal)

    #   assertEquals(proc1CallCount, 1)
    #   assertEquals(proc2CallCount, 1)
    #   assertEquals(proc3CallCount, 1)

    # it "works with single proc frame at 0.0 seconds":
    #   resetThis()
    #   let testAnim = newAnimation(1.8)

    #   var proc1CallCount = 0
    #   proc foo1() {.closure.} = proc1CallCount.inc

    #   let procFrames: seq[KeyFrame[ClosureProc]] = @[(foo1, 0.0)]

    #   testAnim.addProcTrack(procFrames)

    #   # Initial state
    #   assertEquals(proc1CallCount, 0)

    #   testAnim.animateToTime(0.01, 0.01)

    #   assertEquals(proc1CallCount, 1)

    # it "works with single non-proc frame at 0.0 seconds":
    #   resetThis()
    #   let testAnim = newAnimation(1.8)

    #   # int
    #   const intFrames: seq[KeyFrame[int]] = @[(1, 0.0)]
    #   testAnim.addNewAnimationTrack(
    #     this.intVal,
    #     intFrames
    #   )

    #   # Initial state
    #   assertEquals(this.intVal, startingIntVal)

    #   testAnim.animateToTime(0.0, 0.0)
    #   assertEquals(this.intVal, intFrames[0][0])

    #   testAnim.animateToTime(0.0, 0.0)
    #   assertEquals(this.intVal, intFrames[0][0])

  # describe "AnimationTrack[ClosureProc]":
    # describe "Non-looping":
    #   it "Calls a single proc at 0.0":
    #     let testAnim = newAnimation(1.8)
    #     var procCallCount = 0

    #     proc foo1() {.closure.} = procCallCount.inc
    #     let procFrames: seq[KeyFrame[ClosureProc]] = @[(foo1, 0.0)]

    #     testAnim.addProcTrack(procFrames)

    #     # Initial state
    #     assertEquals(procCallCount, 0)

    #     testAnim.animateToTime(0.01, 0.01)
    #     assertEquals(procCallCount, 1)

    #   it "Calls a single proc at 0.0 only once":
    #     let testAnim = newAnimation(1.8)
    #     var procCallCount = 0

    #     proc foo1() {.closure.} = procCallCount.inc
    #     let procFrames: seq[KeyFrame[ClosureProc]] = @[(foo1, 0.0)]

    #     testAnim.addProcTrack(procFrames)

    #     # Initial state
    #     assertEquals(procCallCount, 0)

    #     testAnim.animateToTime(0.0, 0.0)
    #     assertEquals(procCallCount, 1)

    #     testAnim.animateToTime(0.0, 0.0)
    #     assertEquals(procCallCount, 1)

    #   it "Calls a single proc at the end of a track and animation":
    #     let testAnim = newAnimation(1.8)
    #     var procCallCount = 0

    #     proc foo1() {.closure.} = procCallCount.inc
    #     let procFrames: seq[KeyFrame[ClosureProc]] = @[(foo1, testAnim.duration)]

    #     testAnim.addProcTrack(procFrames)

    #     # Initial state
    #     assertEquals(procCallCount, 0)

    #     testAnim.animateToTime(0.01, 0.01)
    #     assertEquals(procCallCount, 0)

    #     testAnim.animateToTime(testAnim.duration, testAnim.duration - 0.01)
    #     assertEquals(procCallCount, 1)

    #   it "Calls a single proc at the end of a track, before the animation has ended":
    #     let testAnim = newAnimation(1.8)
    #     var procCallCount = 0

    #     proc foo1() {.closure.} = procCallCount.inc
    #     let procFrames: seq[KeyFrame[ClosureProc]] = @[(foo1, 1.1)]

    #     testAnim.addProcTrack(procFrames)

    #     # Initial state
    #     assertEquals(procCallCount, 0)

    #     testAnim.animateToTime(0.1, 0.1)
    #     assertEquals(procCallCount, 0)

    #     testAnim.animateToTime(1.0, 0.9)
    #     assertEquals(procCallCount, 1)

    #   it "Calls multiple procs at the right times":
    #     let testAnim = newAnimation(1.8)
    #     var
    #       proc1CallCount = 0
    #       proc2CallCount = 0
    #       proc3CallCount = 0

    #     proc foo1() {.closure.} = proc1CallCount.inc
    #     proc foo2() {.closure.} = proc2CallCount.inc
    #     proc foo3() {.closure.} = proc3CallCount.inc

    #     let procFrames: seq[KeyFrame[ClosureProc]] = @[
    #       (foo1, 0.1),
    #       (foo2, 0.5),
    #       (foo3, 1.6)
    #     ]

    #     testAnim.addProcTrack(procFrames)

    #     # Initial state
    #     assertEquals(proc1CallCount, 0)
    #     assertEquals(proc2CallCount, 0)
    #     assertEquals(proc3CallCount, 0)

    #     testAnim.animateToTime(0, 0)
    #     assertEquals(proc1CallCount, 0)
    #     assertEquals(proc2CallCount, 0)
    #     assertEquals(proc3CallCount, 0)

    #     testAnim.animateToTime(0.01, 0.01)
    #     assertEquals(proc1CallCount, 0)
    #     assertEquals(proc2CallCount, 0)
    #     assertEquals(proc3CallCount, 0)

    #     testAnim.animateToTime(0.11, 0.1)
    #     assertEquals(proc1CallCount, 1)
    #     assertEquals(proc2CallCount, 0)
    #     assertEquals(proc3CallCount, 0)

    # describe "Looping":
    #   it "Calls a single proc at 0.0":
    #     let testAnim = newAnimation(1.8)
    #     var procCallCount = 0

    #     proc foo1() {.closure.} = procCallCount.inc
    #     let procFrames: seq[KeyFrame[ClosureProc]] = @[(foo1, 0.0)]

    #     testAnim.addProcTrack(procFrames)

    #     # Initial state
    #     assertEquals(procCallCount, 0)

    #     testAnim.animateToTime(0.01, 0.01)
    #     assertEquals(procCallCount, 1)

    #   it "Calls a single proc at 0.0 only once":
    #     let testAnim = newAnimation(1.8)
    #     var procCallCount = 0

    #     proc foo1() {.closure.} = procCallCount.inc
    #     let procFrames: seq[KeyFrame[ClosureProc]] = @[(foo1, 0.0)]

    #     testAnim.addProcTrack(procFrames)

    #     # Initial state
    #     assertEquals(procCallCount, 0)

    #     testAnim.animateToTime(0, 0)
    #     assertEquals(procCallCount, 1)

    #     testAnim.animateToTime(0, 0)
    #     assertEquals(procCallCount, 1)

    #   it "Calls a single proc at the end of a track and animation":
    #     let testAnim = newAnimation(1.8)
    #     var procCallCount = 0

    #     proc foo1() {.closure.} = procCallCount.inc
    #     let procFrames: seq[KeyFrame[ClosureProc]] = @[(foo1, testAnim.duration)]

    #     testAnim.addProcTrack(procFrames)

    #     # Initial state
    #     assertEquals(procCallCount, 0)

    #     testAnim.animateToTime(0.01, 0.01)
    #     assertEquals(procCallCount, 0)

    #     testAnim.animateToTime(testAnim.duration, testAnim.duration - 0.01)
    #     assertEquals(procCallCount, 1)

    #   it "Calls a single proc at the end of a track, before the animation has ended":
    #     let testAnim = newAnimation(1.8)
    #     var procCallCount = 0

    #     proc foo1() {.closure.} = procCallCount.inc
    #     let procFrames: seq[KeyFrame[ClosureProc]] = @[(foo1, 1.1)]

    #     testAnim.addProcTrack(procFrames)

    #     # Initial state
    #     assertEquals(procCallCount, 0)

    #     testAnim.animateToTime(0.1, 0.1)
    #     assertEquals(procCallCount, 0)

    #     testAnim.animateToTime(1.1, 1.0)
    #     assertEquals(procCallCount, 1)

    #   it "Calls multiple procs at the right times":
    #     let testAnim = newAnimation(1.8)
    #     var
    #       proc1CallCount = 0
    #       proc2CallCount = 0
    #       proc3CallCount = 0

    #     proc foo1() {.closure.} = proc1CallCount.inc
    #     proc foo2() {.closure.} = proc2CallCount.inc
    #     proc foo3() {.closure.} = proc3CallCount.inc

    #     let procFrames: seq[KeyFrame[ClosureProc]] = @[
    #       (foo1, 0.1),
    #       (foo2, 0.5),
    #       (foo3, 1.6)
    #     ]

    #     testAnim.addProcTrack(procFrames)

    #     # Initial state
    #     assertEquals(proc1CallCount, 0)
    #     assertEquals(proc2CallCount, 0)
    #     assertEquals(proc3CallCount, 0)

    #     testAnim.animateToTime(0, 0)
    #     assertEquals(proc1CallCount, 0)
    #     assertEquals(proc2CallCount, 0)
    #     assertEquals(proc3CallCount, 0)

    #     testAnim.animateToTime(0.01, 0.01)
    #     assertEquals(proc1CallCount, 0)
    #     assertEquals(proc2CallCount, 0)
    #     assertEquals(proc3CallCount, 0)

    #     testAnim.animateToTime(0.11, 0.1)
    #     assertEquals(proc1CallCount, 1)
    #     assertEquals(proc2CallCount, 0)
    #     assertEquals(proc3CallCount, 0)

