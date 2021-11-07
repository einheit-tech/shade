import
  ../testutils,
  shade,
  math

describe "Animation":

  it "calls procs when looping":
    let testAnim = newAnimation(1.1, true)

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
      (foo3, 1.0)
    ]

    testAnim.addProcTrack(procFrames)

    ## INITIAL STATE

    assertEquals(proc1CallCount, 0)
    assertEquals(proc2CallCount, 0)
    assertEquals(proc3CallCount, 0)

    ## FIRST UPDATE (after first frame)

    var updateTime = 0.2
    testAnim.update(updateTime)

    assertEquals(proc1CallCount, 1)
    assertEquals(proc2CallCount, 0)
    assertEquals(proc3CallCount, 0)

    ## SECOND UPDATE (ON second frame)

    updateTime = 0.3
    testAnim.update(updateTime)

    assertEquals(proc1CallCount, 1)
    assertEquals(proc2CallCount, 1)
    assertEquals(proc3CallCount, 0)

    ## THIRD UPDATE (after second frame, before 3rd)

    updateTime = 0.3
    testAnim.update(updateTime)

    assertEquals(proc1CallCount, 1)
    assertEquals(proc2CallCount, 1)
    assertEquals(proc3CallCount, 0)

    ## FOURTH UPDATE (ON 3rd frame)

    updateTime = 0.2
    testAnim.update(updateTime)

    assertEquals(proc1CallCount, 1)
    assertEquals(proc2CallCount, 1)
    assertEquals(proc3CallCount, 1)

    ## FIFTH UPDATE (After 3rd frame before anim duration has been reached)

    updateTime = 0.05
    testAnim.update(updateTime)

    assertEquals(proc1CallCount, 1)
    assertEquals(proc2CallCount, 1)
    assertEquals(proc3CallCount, 1)

    ## 6th UPDATE (At anim duration, should fire first proc at 0.0)

    updateTime = 0.05
    testAnim.update(updateTime)

    assertEquals(proc1CallCount, 2)
    assertEquals(proc2CallCount, 1)
    assertEquals(proc3CallCount, 1)

  it "calls procs when looping with very large deltaTime values":
    let testAnim = newAnimation(1.1, true)

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
      (foo3, 1.0)
    ]

    testAnim.addProcTrack(procFrames)

    ## INITIAL STATE

    assertEquals(proc1CallCount, 0)
    assertEquals(proc2CallCount, 0)
    assertEquals(proc3CallCount, 0)

    ## FIRST UPDATE (after first frame)

    var updateTime = 1.1
    testAnim.update(updateTime)

    assertEquals(proc1CallCount, 2)
    assertEquals(proc2CallCount, 1)
    assertEquals(proc3CallCount, 1)

  it "works with single proc frame at 0.0 seconds":
    # TODO: This gets in an inf loop.
    # Should be solved by using lastFiredProcIndex?
    let testAnim = newAnimation(1.8, true)

    var proc1CallCount = 0
    proc foo1() {.closure.} = proc1CallCount.inc

    let procFrames: seq[KeyFrame[ClosureProc]] = @[(foo1, 0.0)]

    testAnim.addProcTrack(procFrames)

    # Initial state
    assertEquals(proc1CallCount, 0)

    testAnim.update(0.01)

    assertEquals(proc1CallCount, 1)

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

