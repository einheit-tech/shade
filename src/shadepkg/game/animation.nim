type
  AnimationFrame* = object
    index: int
    hflip, vflip: bool

  Animation* = object
    frameDuration: float
    frames: seq[AnimationFrame]
    duration: float
    reverseAtEnd: bool

template index*(this: AnimationFrame): int = this.index
template hflip*(this: AnimationFrame): bool = this.hflip
template vflip*(this: AnimationFrame): bool = this.vflip
template duration*(this: Animation): float = this.duration

proc newAnimationFrame*(index: int, hflip, vflip: bool = false): AnimationFrame =
  AnimationFrame(index: index, hflip: hflip, vflip: vflip)

proc newAnimation*(
  frameDuration: float,
  frames: openArray[AnimationFrame],
  reverseAtEnd: bool = false
): Animation =
  ## Creates a new Animation.
  ## frameDuration: The length of each frame in seconds.
  ## frames: The animation frames to play, in order.
  ## reverseAtEnd: If the animation should play in reverse
  ## once the end of the animation has been reached.
  if frames.len < 1:
    raise newException(Exception, "Animation must have at least one frame.")

  # No need to reverse a single frame.
  let reverse = reverseAtEnd and frames.len > 1

  var duration = frameDuration * frames.len.float
  if reverse:
    # Add duration of all frames except start and end.
    duration += frameDuration * (frames.len - 2).float

  return Animation(
    frameDuration: frameDuration,
    frames: @frames,
    duration: duration,
    reverseAtEnd: reverse
  )

proc newAnimation*(
  frameDuration: float,
  frameIndices: openArray[int],
  reverseAtEnd: bool = false
): Animation =
  ## Creates a new Animation.
  ## frameDuration: The length of each frame in seconds.
  ## frameIndices: The indices of the animation frames to play, in order.
  ## reverseAtEnd: If the animation should play in reverse
  ## once the end of the animation has been reached.

  var frames: seq[AnimationFrame]
  for i in frameIndices:
    frames.add(newAnimationFrame(i))

  return newAnimation(
    frameDuration,
    @frames,
    reverseAtEnd
  )

template `[]`*(this: Animation, index: Natural): AnimationFrame =
  this.frames[index]

proc frameCount*(this: Animation): Natural =
  this.frames.len

proc getCurrentFrame*(this: Animation, elapsed: float): AnimationFrame =
  ## Gets the frame index based on the time elapsed
  ## since the animation first started.
  var currentTime: float
  for i in countup(this.frames.low, this.frames.high):
    currentTime += this.frameDuration
    if currentTime > elapsed:
      return this.frames[i]

  if this.reverseAtEnd:
    for i in countdown(this.frames.high - 1, this.frames.low + 1):
      currentTime += this.frameDuration
      if currentTime > elapsed:
        return this.frames[i]

  raise newException(
    Exception,
    "failed to get AnimationFrame at elapsed time " & $elapsed
  )

