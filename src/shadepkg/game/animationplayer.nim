import tables
import safeset
import animation, ../math/mathutils

export animation

type
  NamedAnimation* = tuple[name: string, animation: Animation]
  AnimationCallback* = proc(this: AnimationPlayer, namedAnimation: NamedAnimation): bool

  AnimationPlayer* = ref AnimationPlayerObj
  AnimationPlayerObj = object
    # Table[animationName, Animation]
    animations: Table[string, Animation]
    currentTime: float
    currentAnimation: Animation
    currentAnimationName: string
    isCurrentAnimationLooping: bool
    animationFinishedCallbacks: SafeSet[AnimationCallback]

proc addAnimations*(this: AnimationPlayer, animations: openArray[NamedAnimation])

proc initAnimationPlayer*(player: AnimationPlayer, animations: varargs[NamedAnimation]) =
  player.addAnimations(animations)

proc newAnimationPlayer*(animations: varargs[NamedAnimation]): AnimationPlayer =
  result = AnimationPlayer()
  initAnimationPlayer(result, animations)

proc addAnimation*(this: AnimationPlayer, animationName: string, animation: Animation) =
  this.animations[animationName] = animation

proc addAnimations*(this: AnimationPlayer, animations: openArray[NamedAnimation]) =
  for (name, anim) in animations:
    this.addAnimation(name, anim)

proc playAnimation*(this: AnimationPlayer, animationName: string, looping: bool = false) =
  if this.currentAnimation != nil:
    if this.currentAnimationName == animationName:
      return
    else:
      this.currentAnimation.reset()

  this.currentAnimation = this.animations[animationName]
  this.currentAnimationName = animationName
  this.isCurrentAnimationLooping = looping

template currentTime*(this: AnimationPlayer): float =
  this.currentTime

template currentAnimation*(this: AnimationPlayer): Animation =
  this.currentAnimation

template currentAnimationName*(this: AnimationPlayer): string =
  this.currentAnimationName

template invokeAnimationFinishedCallbacks(this: AnimationPlayer) =
  if this.currentAnimation != nil:
    for callback in this.animationFinishedCallbacks:
      if callback(this, (this.currentAnimationName, this.currentAnimation)):
        this.animationFinishedCallbacks.remove(callback)

proc addAnimationFinishedCallback(this: AnimationPlayer, callback: AnimationCallback) =
  this.animationFinishedCallbacks.add(callback)

proc removeAnimationFinishedCallback(this: AnimationPlayer, callback: AnimationCallback) =
  this.animationFinishedCallbacks.remove(callback)

proc update*(this: AnimationPlayer, deltaTime: float) =
  if this.currentAnimation != nil:
    this.currentTime += deltaTime
    if this.currentTime >= this.currentAnimation.duration:
      if this.isCurrentAnimationLooping:
        this.currentTime = this.currentTime mod this.currentAnimation.duration
      else:
        this.currentTime = min(this.currentTime, this.currentAnimation.duration)

      # Tell callbacks the animation has reached its end when we surpass the duration.
      this.invokeAnimationFinishedCallbacks()

    this.currentAnimation.animateToTime(this.currentTime, deltaTime, this.isCurrentAnimationLooping)

