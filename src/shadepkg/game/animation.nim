## Animations consist of one or more "tracks" (AnimationTrack).
## Each track updates the value a variable over the couse of the animation.
## The value is updated to match provided "frames" (Keyframe),
## which is a pairing of a value and a time.
## E.g.: A track updating a player's rotation may have:
##       1. A frame at 0.0 seconds with a value of 0
##       2. Another frame at 0.8 seconds with a value of 5
## When the animation time reaches 0.8 seconds, the value will be 5.

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
    wrapInterpolation: bool
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

template currentTime*(this: Animation): float = this.currentTime
template duration*(this: Animation): float = this.duration

proc newAnimation*(duration: float): Animation =
  ## Creates a new Animation.
  return Animation(duration: duration)

proc animateToTime*(this: Animation, currentTime, deltaTime: float) =
  for track in this.tracks:
    track.animateToTime(currentTime, deltaTime, track.wrapInterpolation)

method update*(this: Animation, deltaTime: float) =
  procCall Node(this).update(deltaTime)
  this.currentTime = (this.currentTime + deltaTime) mod this.duration
  this.animateToTime(this.currentTime, deltaTime)

proc newAnimationTrack*[T: TrackType](
  field: T,
  frames: seq[Keyframe[T]],
  animateToTime: AnimateProc,
  wrapInterpolation: bool = false
): AnimationTrack =
  # NOTE: This has to cover all cases of TrackType.
  when field is int:
    result = AnimationTrack(
      kind: tkInt,
      framesInt: frames,
      wrapInterpolation: wrapInterpolation
    )
  elif field is float:
    result = AnimationTrack(
      kind: tkFloat,
      framesFloat: frames,
      wrapInterpolation: wrapInterpolation
    )
  elif field is Vec2:
    result = AnimationTrack(
      kind: tkVec2,
      framesVec2: frames,
      wrapInterpolation: wrapInterpolation
    )
  elif field is Vec3:
    result = AnimationTrack(
      kind: tkVec3,
      framesVec3: frames,
      wrapInterpolation: wrapInterpolation
    )
  elif field is ClosureProc:
    result = AnimationTrack(
      kind: tkClosureProc,
      framesClosureProc: frames,
      wrapInterpolation: wrapInterpolation
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
  wrapInterpolation: bool = false,
  ease: EasingFunction[T] = lerp
) =
  ## Adds a new "track" to the animation.
  ## This is a value that's updated at set intervals as the animation is updated.
  ## @param {T} field The variable to update.
  ## @param {openArray[Keyframe[T]]} frames The frames used to animate the track. 
  ## @param {bool} wrapInterpolation If the track should interpolate
  ##        from the last frame back to the first frame.
  ## @param {EasingFunction[T]} ease The function used to interpolate the given field.
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

        # Between last and first frames
        if currIndex == -1:
          currIndex = `frames`.high

        let currentFrame = `frames`[currIndex]
        # Between last and first frame, and NOT interpolating between them.
        if currIndex == `frames`.high and not wrapInterpolation:
          `field` = currentFrame.value
          return

        # Ease between current and next frames
        let nextFrame = `frames`[(currIndex + 1) mod `frames`.len]

        let timeBetweenFrames =
          if currIndex == `frames`.high:
            `this`.duration - currentFrame.time + nextFrame.time
          else:
            nextFrame.time - currentFrame.time

        let completionRatio = (currentTime - currentFrame.time) / timeBetweenFrames

        `field` = `ease`(
          currentFrame.value,
          nextFrame.value,
          completionRatio
        )

      else:

        # Find the start time
        var timeInAnim = currentTime - deltaTime
        if timeInAnim < 0:
          timeInAnim += `this`.duration

        var currIndex = -1
        for i in `frames`.low..<`frames`.high:
          if timeInAnim == `frames`[i].time:
            currIndex = i
            break
          elif timeInAnim > `frames`[i].time and timeInAnim <= `frames`[i + 1].time:
            currIndex = i + 1
            break

        # Between last and 1st frames
        if currIndex == -1:
          currIndex = `frames`.low

        var remainingTime = deltaTime
        while remainingTime > 0:
          let nextFrame = `frames`[currIndex]
          remainingTime =
            if timeInAnim != 0 and currIndex == `frames`.low:
              remainingTime - (`this`.duration - timeInAnim) + nextFrame.time
            else:
              remainingTime - (nextFrame.time - timeInAnim)

          timeInAnim = nextFrame.time
          currIndex = (currIndex + 1) mod `frames`.len

          if remainingTime >= 0 and lastFiredProcIndex != currIndex:
            nextFrame.value()
            lastFiredProcIndex = currIndex

    let `trackName` = newAnimationTrack(
      `field`,
      `frames`,
      `procName`,
      `wrapInterpolation`
    )

    when (`field` is not proc):
      # Set track state to correct starting point.
      # Don't do this for procs - we don't want to invoke them until the animation is played.
      `trackName`.animateToTime(`this`.currentTime, 0)

    `this`.tracks.add(`trackName`)

