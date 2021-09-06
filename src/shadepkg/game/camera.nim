{.experimental: "codeReordering".}

import
  entity,
  ../inputhandler

type Camera* = ref object of Entity
  trackedEntity*: Entity

proc newCamera*(trackedEntity: Entity): Camera =
  let loc = calcRenderOffset(trackedEntity, Input.mouseLocation)
  return Camera(
    flags: {loUpdate},
    center: loc,
    trackedEntity: trackedEntity
  )

template calcRenderOffset(trackedEntity: Entity, loc: Vec2): Vec2 =
  let dist = loc - trackedEntity.center
  trackedEntity.center + dist * 0.33

proc update*(this: Camera, dt: float) =
  procCall Entity(this).update(dt)
  let loc = Input.mouseLocation
  let preferredLoc = calcRenderOffset(this.trackedEntity, loc)
  this.translate((preferredLoc - this.center) * (5 * dt))

