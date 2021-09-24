import animationplayer

type FakeEntity* = ref object
  animationPlayer: AnimationPlayer
  foo*: float
  bar*: int
  procVal*: proc() {.closure.}

proc generateAnimations*(this: FakeEntity)

proc newFakeEntity*(): FakeEntity =
  result = FakeEntity(
    animationPlayer: newAnimationPlayer()
  )
  result.generateAnimations()

proc generateAnimations*(this: FakeEntity) =
  let testAnim = newAnimation(1.8)

  # const intFrames: seq[KeyFrame[int]] = @[
  #   (1, 0.0),
  #   (2, 0.5),
  #   (3, 1.1)
  # ]

  # testAnim.addNewAnimationTrack(
  #   this.bar,
  #   intFrames
  # )

  # const floatFrames: seq[KeyFrame[float]] = @[
  #   (0.0, 0.0),
  #   (4.2, 0.5),
  #   (12.8, 1.1)
  # ]

  # testAnim.addNewAnimationTrack(
  #   this.foo,
  #   floatFrames
  # )

  # TODO: procs break the compiler.
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
  # TODO: This is redundant for procs.
  # proc lerpProc(start, last: proc(), f: float): proc() =
  #   return (proc() = discard)

  testAnim.addNewAnimationTrack(
    this.procVal,
    procFrames
  )

  this.animationPlayer.addAnimation("test", testAnim)
  this.animationPlayer.playAnimation("test")

when isMainModule:
  let e = newFakeEntity()
  e.generateAnimations()

  # assert e.foo == 0.0
  # assert e.bar == 1

  # e.animationplayer.update(0.5)
  # assert e.foo == 4.2
  # assert e.bar == 2

  # e.animationPlayer.update(0.6)
  # assert e.foo == 12.8
  # assert e.bar == 3

  # e.animationPlayer.update(0.7)
  # assert e.foo == 0.0
  # assert e.bar == 1

