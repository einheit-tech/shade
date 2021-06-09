import
  pixie,
  hashes,
  macros

import
  ../math/rectangle,
  ../math/collision/collisionhull,
  ../math/mathutils,
  material

export pixie, rectangle, collisionhull, material, mathutils

type 
  ## Flags indicating how the object should be treated by a layer.
  LayerObjectFlags* = enum
    loUpdate
    loRender
    loPhysics

  Entity* = ref object of RootObj
    flags*: set[LayerObjectFlags]
    center*: Vec2
    rotation*: float
    # Pixels per second.
    velocity*: Vec2
    lastMoveVector*: Vec2

proc newEntity*(
  flags: set[LayerObjectFlags],
  centerX, centerY: float = 0.0
): Entity =
  return Entity(
    flags: flags,
    center: vec2(centerX, centerY)
  )

template x*(this: Entity): float = this.center.x
template y*(this: Entity): float = this.center.y

template translate*(this: Entity, delta: Vec2) =
  this.center += delta

template rotate*(this: Entity, deltaRotation: float) =
  this.rotation += deltaRotation
  this.collisionHull.rotate(deltaRotation)

method hash*(this: Entity): Hash {.base.} = hash(this[].unsafeAddr)

method update*(this: Entity, deltaTime: float) {.base.} =
  this.lastMoveVector = this.velocity * deltaTime
  this.center += this.lastMoveVector

method render*(
  this: Entity,
  ctx: Context,
  callback: proc() = nil
) {.base.} =
  ctx.translate(this.center)
  ctx.rotate(this.rotation)

  if callback != nil:
    callback()

  ctx.translate(-this.center)
  ctx.rotate(-this.rotation)

macro render*(this: typedesc, parent: typedesc, body: untyped): untyped =
  ## Macro as a helper for the render method.
  ## `this`, `ctx`, and `callback` are all injected.
  ## All code in the macro is ran inside the parent's render callback.
  ##
  ## Example:
  ## render(B, A):
  ##   ctx.fillStyle = rgba(255, 0, 0, 255)
  ##   let
  ##     pos = vec2(50, 50)
  ##     wh = vec2(100, 100)
  ##   ctx.fillRect(rect(pos, wh))
  ##   if callback != nil:
  ##    callback()

  quote do:
    method render*(
      this {.inject.}: `this`,
      ctx {.inject.}: Context,
      callback {.inject.}: proc() = nil
    ) =
      procCall `parent`(this).render(ctx, proc =
        `body`
      )

