## Animations consist of one or more "tracks" (AnimationTrack).
## Each track updates the value a variable over the couse of the animation.
## The value is updated to match provided "frames" (Keyframe),
## which is a pairing of a value and a time.
## E.g.: A track updating a player's rotation may have:
##       1. A frame at 0.0 seconds with a value of 0
##       2. Another frame at 0.8 seconds with a value of 5
## When the animation time reaches 0.8 seconds, the value will be 5.

import macros

import safeset

import
  node,
  ../math/mathutils,
  ../util/types,
  ../render/color

type
  ClosureProc* = proc() {.closure.}
  TrackType = int|float|bool|Vector|IVector|Color|ClosureProc
makeEnum(TrackType, TrackKind, "tk")

type
  Keyframe*[T] = tuple[value: T, time: float]
  AnimateProc* = proc(
    track: var AnimationTrack,
    currentTime: float,
    deltaTime: float,
    wrapInterpolation: bool = false
  )
  AnimationTrack* = object
    animateToTime*: AnimateProc
    wrapInterpolation: bool
    case kind*: TrackKind:
      of tkInt:
        framesInt: seq[Keyframe[int]]
      of tkFloat:
        framesFloat: seq[Keyframe[float]]
      of tkBool:
        framesBool: seq[Keyframe[bool]]
      of tkVector:
        framesVector: seq[Keyframe[Vector]]
      of tkIVector:
        framesIVector: seq[Keyframe[IVector]]
      of tkColor:
        framesColor: seq[Keyframe[Color]]
      of tkClosureProc:
        framesClosureProc: seq[Keyframe[ClosureProc]]
        lastFiredProcIndex: int

  AnimationCallback* = proc(this: Animation)

  Animation* = ref object
    currentTime: float
    duration: float
    looping: bool
    tracks: seq[AnimationTrack]
    onFinishedCallbacks: SafeSet[AnimationCallback]

template currentTime*(this: Animation): float = this.currentTime
template duration*(this: Animation): float = this.duration

template isFinished*(this: Animation): bool =
  ## If a non-looping Animation has reached its end.
  not this.looping and this.currentTime == this.duration

proc initAnimation*(anim: Animation, duration: float, looping: bool) =
  anim.duration = duration
  anim.looping = looping

proc newAnimation*(duration: float, looping: bool): Animation =
  ## Creates a new Animation.
  result = Animation()
  initAnimation(result, duration, looping)

proc addFinishedCallback*(this: Animation, callback: AnimationCallback) =
  if this.onFinishedCallbacks == nil:
    this.onFinishedCallbacks = newSafeSet[AnimationCallback]()
  this.onFinishedCallbacks.add(callback)

proc removeFinishedCallback*(this: Animation, callback: AnimationCallback) =
  if this.onFinishedCallbacks != nil:
    this.onFinishedCallbacks.remove(callback)

template onFinished*(this: Animation, body: untyped) =
  this.addFinishedCallback(
    proc(`this` {.inject.}: Animation) =
      body
  )

proc notifyFinishedCallbacks*(this: Animation) =
  if this.onFinishedCallbacks != nil:
    for callback in this.onFinishedCallbacks:
      callback(this)

proc animateToTime*(this: Animation, currentTime, deltaTime: float) =
  for track in this.tracks.mitems:
    track.animateToTime(track, currentTime, deltaTime, track.wrapInterpolation)

proc reset*(this: Animation) =
  this.currentTime = 0
  for track in this.tracks.mitems:
    if track.kind == tkClosureProc:
      track.lastFiredProcIndex = -1

proc update*(this: Animation, deltaTime: float) =
  if this.looping:
    this.currentTime = (this.currentTime + deltaTime) mod this.duration
    this.animateToTime(this.currentTime, deltaTime)
  else:
    if this.currentTime < this.duration:
      this.currentTime = min(this.currentTime + deltaTime, this.duration)
      this.animateToTime(this.currentTime, deltaTime)
      # Just reached the end of the animation
      if this.currentTime == this.duration:
        this.notifyFinishedCallbacks()

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
  elif field is bool:
    result = AnimationTrack(
      kind: tkBool,
      framesBool: frames,
      wrapInterpolation: wrapInterpolation
    )
  elif field is Vector:
    result = AnimationTrack(
      kind: tkVector,
      framesVector: frames,
      wrapInterpolation: wrapInterpolation
    )
  elif field is IVector:
    result = AnimationTrack(
      kind: tkIVector,
      framesIVector: frames,
      wrapInterpolation: wrapInterpolation
    )
  elif field is Color:
    result = AnimationTrack(
      kind: tkColor,
      framesColor: frames,
      wrapInterpolation: wrapInterpolation
    )
  elif field is ClosureProc:
    result = AnimationTrack(
      kind: tkClosureProc,
      framesClosureProc: frames,
      wrapInterpolation: wrapInterpolation,
      lastFiredProcIndex: -1
    )
  else:
    raise newException(Exception, "Unsupported animation track type: " & typeof field)

  result.animateToTime = animateToTime

macro assignField[T: TrackType](field: typed, value: T): untyped =
  ## Assigns `value` to `field`.
  ## This also handles if `field` is a setter proc.
  if field.kind == nnkCall and field[0].symKind in {nskMethod, nskProc, nskFunc}:
    let
      ident = nnkAccQuoted.newTree(ident($field[0] & "="))
      setter = copyNimTree(field)

    setter[0] = ident
    setter.add value
    result = quote do:
      when compiles(`setter`):
        `setter`
      else:
        `field` = `value`
  else:
    result = quote do:
      `field` = `value`

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
    proc `procName`(
      track: var AnimationTrack,
      currentTime: float,
      deltaTime: float,
      wrapInterpolation: bool = false
    ) =
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
        assignField(`field`, currentFrame.value)
        return

      # Ease between current and next frames
      let nextFrame = `frames`[(currIndex + 1) mod `frames`.len]

      let timeBetweenFrames =
        if currIndex == `frames`.high:
          `this`.duration - currentFrame.time + nextFrame.time
        else:
          nextFrame.time - currentFrame.time

      let
        completionRatio = (currentTime - currentFrame.time) / timeBetweenFrames
        easedValue = `ease`(
          currentFrame.value,
          nextFrame.value,
          completionRatio
        )

      assignField(`field`, easedValue)

    let `trackName` = newAnimationTrack(
      `field`,
      `frames`,
      `procName`,
      `wrapInterpolation`
    )

    `this`.tracks.add(`trackName`)

macro addProcTrack*(this: Animation, frames: openArray[Keyframe[ClosureProc]]) =
  ## Adds a new "track" to the animation.
  ## This is a value that's updated at set intervals as the animation is updated.
  ## @param {T} field The variable to update.
  ## @param {openArray[Keyframe[T]]} frames The frames used to animate the track. 
  ## @param {bool} wrapInterpolation If the track should interpolate
  ##        from the last frame back to the first frame.
  ## @param {EasingFunction[T]} ease The function used to interpolate the given field.

  let
    procName = gensym(nskProc, "sample")
    trackName = gensym(nskLet, "track")

  result = quote do:
    proc `procName`(
      track: var AnimationTrack,
      currentTime: float,
      deltaTime: float,
      wrapInterpolation: bool = false
    ) =
      # Find the start time
      var timeInAnim = currentTime - deltaTime
      if timeInAnim < 0:
        timeInAnim = euclMod(timeInAnim, `this`.duration)

      # Finds the next frame we will "play"
      var currIndex = -1
      for i in `frames`.low..<`frames`.high:
        if almostEqual(timeInAnim, `frames`[i].time):
          currIndex = i
          break
        elif timeInAnim > `frames`[i].time and timeInAnim <= `frames`[i + 1].time:
          currIndex = i + 1
          break
      # Between last and 1st frames
      if currIndex == -1:
        currIndex = `frames`.low

      if not `this`.looping:
        var
          nextFrame = `frames`[currIndex]
          collectiveFrameTime = round(nextFrame.time - timeInAnim, 2)

        while deltaTime - collectiveFrameTime >= 0:
          if currIndex == track.lastFiredProcIndex:
            break

          nextFrame.value()
          track.lastFiredProcIndex = currIndex
          if currIndex == `frames`.high:
            break

          collectiveFrameTime = round(
            collectiveFrameTime + `frames`[currIndex + 1].time - nextFrame.time,
            2
          )
          currIndex += 1

          if currIndex > `frames`.high:
            break
          nextFrame = `frames`[currIndex]
      else:
        var
          remainingTime = deltaTime
          nextFrame: Keyframe[ClosureProc]
          frameStartTime = currentTime - deltaTime

        while true:
          if currIndex == track.lastFiredProcIndex:
            if `frames`.len == 1:
              break
            currIndex = euclMod(currIndex + 1, `frames`.len)
            continue

          nextFrame = `frames`[currIndex]
          # Find time from frameStartTime to the current frame,
          # we'll sutract it from remainingTime
          # then play the proc if remainingTime >= 0
          let modFrameStartTime = euclMod(frameStartTime, `this`.duration)

          let timeTillNextFrame =
            # Time in animation is between the last frame and duration of the anim.
            if currIndex == `frames`.low and modFrameStartTime > nextFrame.time:
              round(`this`.duration - modFrameStartTime + nextFrame.time, 2)
            else:
              round(nextFrame.time - modFrameStartTime, 2)

          remainingTime = round(remainingTime - timeTillNextFrame, 2)
          if remainingTime < 0:
            break
          
          nextFrame.value()
          track.lastFiredProcIndex = currIndex
          currIndex = euclMod(currIndex + 1, `frames`.len)
          frameStartTime = nextFrame.time

    let `trackName` = newAnimationTrack[ClosureProc](
      nil,
      `frames`,
      `procName`
    )

    `this`.tracks.add(`trackName`)

