import
  node,
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
  this.currentAnimation = this.animations[animationName]

# TODO: etc...

method update*(this: AnimationPlayer, deltaTime: float) =
  procCall Node(this).update(deltaTime)

  if this.currentAnimation != nil:
    this.currentAnimation.update(deltaTime)

