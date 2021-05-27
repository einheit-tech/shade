## AnimatedEntity is an `Entity` with an animation system built in.
## AnimatedEntity's `LayerObjectFlags` is set to `loUpdateRender`.
import
  nico,
  pixie,
  tables

import
  entity,
  animation,
  ../graphics/spritesheetloader

export
  entity,
  animation,
  spritesheetloader

type AnimatedEntity* = ref object of Entity
  spritesheetIndex*: int
  spriteWidth*: int
  spriteHeight*: int
  animations: Table[string, Animation]
  currentAnimation*: Animation
  currentAnimationTime: float

proc newAnimatedEntity*(
  spritesheetIndex: int,
  x, y: float,
  spriteWidth, spriteHeight: int = 1
): AnimatedEntity =
  result = AnimatedEntity(
    flags: loUpdateRender,
    spritesheetIndex: spritesheetIndex,
    center: initVector2(x, y),
    spriteWidth: spriteWidth,
    spriteHeight: spriteHeight
  )

method addAnimation*(this: AnimatedEntity, name: string, animation: Animation) {.base.} =
  this.animations[name] = animation

method resetAnimation*(this: AnimatedEntity) {.base.} =
  this.currentAnimationTime = 0f

method setAnimation*(this: AnimatedEntity, name: string) {.base.} =
  this.currentAnimation = this.animations[name]
  this.resetAnimation()

method updateCurrentAnimation(this: AnimatedEntity, deltaTime: float) {.base.} =
  ## Updates the animation based on elapsed time.
  ## This is automatically invoked by update()
  this.currentAnimationTime =
    (this.currentAnimationTime + deltaTime) mod this.currentAnimation.duration

method getCurrentAnimationFrame*(this: AnimatedEntity): AnimationFrame {.base.} =
  ## Gets the current animation frame to render.
  ## By default, it invokes `Animation.getCurrentFrame(this.currentAnimationTime)`
  return this.currentAnimation.getCurrentFrame(this.currentAnimationTime)

method renderCurrentAnimation(this: AnimatedEntity) {.base.} =
  ## Renders the current animation frame.
  ## This is automatically invoked by render()
  setSpritesheet(this.spritesheetIndex)
  let frame = this.getCurrentAnimationFrame()
  if this.rotation == 0.0:
    # Draw the sprite based on the top left coord.
    let topLeft = this.center - initVector2(this.spriteWidth / 2, this.spriteHeight / 2)
    spr(frame.index, topLeft.x, topLeft.y, hflip = frame.hflip, vflip = frame.vflip)
  else:
    # TODO: There's currently no way to flip AND rotate.
    sprRot(
      frame.index,
      this.x + this.collisionHull.center.x,
      this.y + this.collisionHull.center.y,
      this.rotation
    )

method update*(this: AnimatedEntity, deltaTime: float) =
  procCall Entity(this).update(deltaTime)
  this.updateCurrentAnimation(deltaTime)

method render*(this: AnimatedEntity, ctx: Context) =
  procCall Entity(this).render(ctx)
  this.renderCurrentAnimation()

