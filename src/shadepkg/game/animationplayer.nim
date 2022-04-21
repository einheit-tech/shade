import tables
import safeset
import animation

export animation

type
  NamedAnimation* = tuple[name: string, animation: Animation]
  NamedAnimationCallback* = proc(this: AnimationPlayer, namedAnimation: NamedAnimation)

  AnimationPlayer* = ref AnimationPlayerObj
  AnimationPlayerObj = object
    # Table[animationName, Animation]
    animations: Table[string, Animation]
    currentAnimation: Animation
    currentAnimationName: string
    # TODO: Attach a callback to each animation?
    # How would we clean it up?
    # =destroy proc
    animationFinishedCallbacks: SafeSet[NamedAnimationCallback]

proc addAnimations*(this: AnimationPlayer, animations: openArray[NamedAnimation])

proc initAnimationPlayer*(
  player: AnimationPlayer,
  animations: varargs[NamedAnimation]
) =
  player.addAnimations(animations)

# TODO: How will this work to notify the callbacks in AnimationPlayer?
proc animationFinishedCallback(anim: Animation) =
  discard

proc `=destroy`*(this: var AnimationPlayerObj) =
  # TODO: Remove our callbacks from every animation
  discard

proc newAnimationPlayer*(animations: varargs[NamedAnimation]): AnimationPlayer =
  result = AnimationPlayer()
  initAnimationPlayer(result, animations)

proc addAnimation*(this: AnimationPlayer, animationName: string, animation: Animation) =
  this.animations[animationName] = animation
  # We need to hook into each animation to know when it finishes.
  animation.addFinishedCallback(animationFinishedCallback)

proc addAnimations*(this: AnimationPlayer, animations: openArray[NamedAnimation]) =
  for (name, anim) in animations:
    this.addAnimation(name, anim)

proc playAnimation*(this: AnimationPlayer, animationName: string) =
  if this.currentAnimation != nil:
    if this.currentAnimationName == animationName:
      return
    else:
      this.currentAnimation.reset()

  this.currentAnimation = this.animations[animationName]
  this.currentAnimationName = animationName

template currentAnimation*(this: AnimationPlayer): Animation =
  this.currentAnimation

template currentAnimationName*(this: AnimationPlayer): string =
  this.currentAnimationName

proc update*(this: AnimationPlayer, deltaTime: float) =
  if this.currentAnimation != nil:
    this.currentAnimation.update(deltaTime)

