import
  node,
  animation,
  tables

export animation

type
  NamedAnimation* = tuple[name: string, animation: Animation]
  AnimationPlayer* = ref object of Node
    # Table[animationName, Animation]
    animations: Table[string, Animation]
    currentAnimation: Animation
    currentAnimationName: string

proc addAnimations*(this: AnimationPlayer, animations: openArray[NamedAnimation])

proc initAnimationPlayer*(
  player: AnimationPlayer,
  animations: varargs[NamedAnimation]
) =
  initNode(Node(player), {loUpdate})
  player.addAnimations(animations)

proc newAnimationPlayer*(animations: varargs[NamedAnimation]): AnimationPlayer =
  result = AnimationPlayer()
  initAnimationPlayer(result, animations)

proc addAnimation*(this: AnimationPlayer, animationName: string, animation: Animation) =
  this.animations[animationName] = animation

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

# TODO: etc...

method update*(this: AnimationPlayer, deltaTime: float) =
  procCall Node(this).update(deltaTime)

  if this.currentAnimation != nil:
    this.currentAnimation.update(deltaTime)

