{.experimental: "codeReordering".}

import
  entity,
  ../input/controller as contrllr

type Camera* = ref object of Entity
  trackedEntity*: Entity
  controller: Controller

proc newCamera*(trackedEntity: Entity, controller: Controller): Camera =
  let loc = calcRenderOffset(trackedEntity, controller.mouse.location)
  return Camera(
    flags: {loUpdate},
    center: loc,
    trackedEntity: trackedEntity,
    controller: controller
  )

template calcRenderOffset(trackedEntity: Entity, mouseLoc: Vec2): Vec2 =
  let dist = mouseLoc - trackedEntity.center
  trackedEntity.center + dist * 0.33

proc update*(this: Camera, dt: float) =
  procCall Entity(this).update(dt)
  let loc = this.controller.mouse.location
  let preferredLoc = calcRenderOffset(this.trackedEntity, loc)
  this.translate((preferredLoc - this.center) * (5 * dt))

