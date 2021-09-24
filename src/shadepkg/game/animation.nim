import macros

import
  node,
  ../math/mathutils,
  ../util/types

type
  ClosureProc* = proc() {.closure.}
  TrackType = int|float|Vec2|Vec3|ClosureProc
makeEnum(TrackType, TrackKind, "tk")

type
  Keyframe*[T] = tuple[value: T, time: float]
  AnimateProc* = proc(currentTime, deltaTime: float, wrapInterpolation: bool = false)
  AnimationTrack* = object
    animateToTime*: AnimateProc
    case kind: TrackKind:
      of tkInt:
        framesInt: seq[Keyframe[int]]
      of tkFloat:
        framesFloat: seq[Keyframe[float]]
      of tkVec2:
        framesVec2: seq[Keyframe[Vec2]]
      of tkVec3:
        framesVec3: seq[Keyframe[Vec3]]
      of tkClosureProc:
        framesClosureProc: seq[Keyframe[ClosureProc]]

  Animation* = ref object of Node
    currentTime: float
    duration: float
    tracks: seq[AnimationTrack]

template duration*(this: Animation): float = this.duration

proc newAnimation*(duration: float): Animation =
  ## Creates a new Animation.
  return Animation(duration: duration)

proc animateToTime*(this: Animation, currentTime, deltaTime: float) =
  for track in this.tracks:
    track.animateToTime(currentTime, deltaTime)

method update*(this: Animation, deltaTime: float) =
  procCall Node(this).update(deltaTime)
  this.currentTime = (this.currentTime + deltaTime) mod this.duration
  this.animateToTime(this.currentTime, deltaTime)

proc newAnimationTrack*[T: TrackType](
  field: T,
  frames: seq[Keyframe[T]],
  animateToTime: AnimateProc
): AnimationTrack =
  # NOTE: This has to cover all cases of TrackType.
  when field is int:
    result = AnimationTrack(
      kind: tkInt,
      framesInt: frames
    )
  elif field is float:
    result = AnimationTrack(
      kind: tkFloat,
      framesFloat: frames
    )
  elif field is Vec2:
    result = AnimationTrack(
      kind: tkVec2,
      framesVec2: frames
    )
  elif field is Vec3:
    result = AnimationTrack(
      kind: tkVec3,
      framesVec3: frames
    )
  elif field is ClosureProc:
    result = AnimationTrack(
      kind: tkClosureProc,
      framesClosureProc: frames
    )
  else:
    raise newException(Exception, "Unsupported animation track type: " & typeof field)

  result.animateToTime = animateToTime

proc lerp(startValue, endValue: proc(), completionRatio: float): proc() =
  return (proc() = discard)

macro addNewAnimationTrack*[T: TrackType](
  this: Animation,
  field: T,
  frames: openArray[Keyframe[T]],
  easingFunc: proc(startValue, endValue: T, completionRatio: float): T = lerp
) =
  let
    procName = gensym(nskProc, "sample" & $field.repr)
    trackName = gensym(nskLet, "track")

  result = quote do:
    when (`field` is proc):
      var lastFiredProcIndex: int = -1

    # TODO: Figure out how to extract this into separate functions.
    proc `procName`(currentTime, deltaTime: float, wrapInterpolation: bool = false) =
      when (`field` is not proc):
        var currIndex = -1
        for i in `frames`.low..<`frames`.high:
          if currentTime >= `frames`[i].time and currentTime <= `frames`[i + 1].time:
            currIndex = i
            break

        # Between last and 1st frames
        if currIndex == -1:
          currIndex = `frames`.low

        let 
          timeBetweenFrames = (`frames`[currIndex + 1].time - `frames`[currIndex].time)
          completionRatio = (currentTime - `frames`[currIndex].time) / timeBetweenFrames

        `field` = `easingFunc`(
          `frames`[currIndex].value,
          `frames`[currIndex + 1].value, completionRatio
        )

      else:

        # Find the start time
        let startTime = currentTime - deltaTime
        var startTimeConfined = startTime mod `this`.duration
        if startTimeConfined < 0:
          startTimeConfined += `this`.duration

        var currIndex = -1
        for i in `frames`.low..<`frames`.high:
          # TODO: Test edge cases for this logic
          if startTimeConfined == `frames`[i].time:
            currIndex = i
            break
          elif startTimeConfined > `frames`[i].time and startTimeConfined <= `frames`[i + 1].time:
            currIndex = i + 1
            break

        # Between last and 1st frames
        if currIndex == -1:
          currIndex = `frames`.low

        var remainingTime = deltaTime
        while remainingTime > 0:
          let nextFrame = `frames`[currIndex]

          # TODO: != 0 might not be right? Test more cases
          remainingTime =
            if startTimeConfined != 0 and currIndex == `frames`.low:
              remainingTime - (`this`.duration - startTimeConfined) + nextFrame.time
            else:
              remainingTime - (nextFrame.time - startTimeConfined)

          startTimeConfined = nextFrame.time
          currIndex = (currIndex + 1) mod `frames`.len

          if remainingTime > 0 and lastFiredProcIndex != currIndex:
            nextFrame.value()
            lastFiredProcIndex = currIndex

        # jump to the "next" keyframe (proc to call), subtrack that time from the deltaTime.
        # if >= 0, invoke the proc.

    let `trackName` = newAnimationTrack(
      `field`,
      `frames`,
      `procName`
    )

    when (`field` is not proc):
      # Set track state to correct starting point.
      # Don't do this for procs - we don't want to invoke them until the animation is played.
      `trackName`.animateToTime(`this`.currentTime, 0)

    `this`.tracks.add(`trackName`)

