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
  TrackType = int|float|DVec2|IVec2|DVec3|IVec3|ClosureProc
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
      of tkDVec2:
        framesDVec2: seq[Keyframe[DVec2]]
      of tkIVec2:
        framesIVec2: seq[Keyframe[IVec2]]
      of tkDVec3:
        framesDVec3: seq[Keyframe[DVec3]]
      of tkIVec3:
        IVec3: seq[Keyframe[IVec3]]
      of tkClosureProc:
        framesClosureProc: seq[Keyframe[ClosureProc]]
        lastFiredProcIndex: int

  Animation* = ref object of Node
    currentTime: float
    duration: float
    looping: bool
    tracks: seq[AnimationTrack]

template currentTime*(this: Animation): float = this.currentTime
template duration*(this: Animation): float = this.duration

proc initAnimation*(anim: Animation, duration: float, looping: bool) =
  initNode(Node(anim), {loUpdate})
  anim.duration = duration
  anim.looping = looping

proc newAnimation*(duration: float, looping: bool): Animation =
  ## Creates a new Animation.
  result = Animation()
  initAnimation(result, duration, looping)

proc animateToTime*(this: Animation, currentTime, deltaTime: float) =
  for track in this.tracks.mitems:
    track.animateToTime(track, currentTime, deltaTime, track.wrapInterpolation)

proc reset*(this: Animation) =
  this.currentTime = 0
  for track in this.tracks.mitems:
    if track.kind == tkClosureProc:
      track.lastFiredProcIndex = -1

method update*(this: Animation, deltaTime: float) =
  procCall Node(this).update(deltaTime)

  if this.looping:
    this.currentTime = (this.currentTime + deltaTime) mod this.duration
    this.animateToTime(this.currentTime, deltaTime)
  else:
    if this.currentTime < this.duration:
      this.currentTime += deltaTime
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
  elif field is DVec2:
    result = AnimationTrack(
      kind: tkDVec2,
      framesDVec2: frames,
      wrapInterpolation: wrapInterpolation
    )
  elif field is IVec2:
    result = AnimationTrack(
      kind: tkIVec2,
      framesIVec2: frames,
      wrapInterpolation: wrapInterpolation
    )
  elif field is DVec3:
    result = AnimationTrack(
      kind: tkDVec3,
      framesDVec3: frames,
      wrapInterpolation: wrapInterpolation
    )
  elif field is IVec3:
    result = AnimationTrack(
      kind: IVec3,
      IVec3: frames,
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
          collectiveFrameTime = nextFrame.time - timeInAnim

        if timeInAnim <= `frames`[`frames`.high].time:
          while deltaTime - collectiveFrameTime >= 0:
            if currIndex == track.lastFiredProcIndex:
              break

            nextFrame.value()
            track.lastFiredProcIndex = currIndex
            if currIndex == `frames`.high:
              break

            collectiveFrameTime += `frames`[currIndex + 1].time - nextFrame.time
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
          let modFrameStartTime = frameStartTime mod `this`.duration

          # TODO: Add a special case when frame.time == this.duration

          let timeTillNextFrame =
            # Time in animation is between the last frame and duration of the anim.
            if currIndex == `frames`.low and modFrameStartTime > nextFrame.time:
              `this`.duration - modFrameStartTime + nextFrame.time
            else:
              nextFrame.time - modFrameStartTime

          remainingTime -= timeTillNextFrame
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

