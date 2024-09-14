import
  entity,
  ../math/[aabb, vector2, mathutils],
  ../game/gamestate

export entity, aabb, vector2, mathutils

type
  Camera* = ref object of Entity
    z*: float
    bounds*: AABB
    viewport*: AABB

    # For entity tracking
    offset*: Vector
    trackedEntity*: Entity
    completionRatioPerFrame*: CompletionRatio
    easingFunction*: EasingFunction[Vector]

proc updateViewport*(this: Camera)

proc initCamera*(camera: Camera) =
  initEntity(Entity(camera), UPDATE)
  camera.bounds = AABB_ZERO
  camera.viewport = AABB_ZERO
  camera.offset = VECTOR_ZERO
  camera.trackedEntity = nil
  camera.completionRatioPerFrame = 1.0
  camera.easingFunction = lerp
  camera.updateViewport()

proc newCamera*(): Camera =
  result = Camera()
  initCamera(result)

proc newCamera*(
  trackedEntity: Entity,
  completionRatioPerFrame: CompletionRatio,
  easingFunction: EasingFunction[Vector] = lerp
): Camera =
  ## Creates a camera which follows a entity.
  ## completionRatioPerFrame: The distance * CompletionRatio to travel each frame.
  ##   If set to 1, it would track the entity perfectly.
  ##   Set to 0, the camera will not move.
  ##   Typically, lower values are desired (0.1 - 0.3).
  ## easingFunction: Determines how the camera follows the tracked entity.
  result = Camera()
  initCamera(result)
  result.trackedEntity = trackedEntity
  result.completionRatioPerFrame = completionRatioPerFrame
  result.easingFunction = easingFunction

proc updateViewport*(this: Camera) =
  ## Updates the camera's viewport to fit the gamestate's resolution.
  if this.viewport == AABB_ZERO:
    this.viewport = aabb(
      this.x - gamestate.resolution.x * 0.5,
      this.y - gamestate.resolution.y * 0.5,
      this.x + gamestate.resolution.x * 0.5,
      this.y + gamestate.resolution.y * 0.5
    )
  else:
    this.viewport.topLeft = vector(
      this.x - gamestate.resolution.x * 0.5,
      this.y - gamestate.resolution.y * 0.5,
    )
    this.viewport.bottomRight = vector(
      this.x + gamestate.resolution.x * 0.5,
      this.y + gamestate.resolution.y * 0.5
    )

proc setTrackingEasingFunction*(this: Camera, easingFunction: EasingFunction[Vector]) =
  this.easingFunction = easingFunction

proc setTrackedEntity*(this: Camera, n: Entity) =
  this.trackedEntity = n

proc bounds*(this: Camera): AABB =
  if this.bounds == AABB_ZERO:
    this.bounds = aabb(float.low, float.low, float.high, float.high)
  return this.bounds

template confineToBounds(this: Camera) =
  if this.bounds != AABB_ZERO:
    let
      distToPlane = 1.0 - this.z
      halfViewportWidth = this.viewport.width * 0.5 * distToPlane
      halfViewportHeight = this.viewport.height * 0.5 * distToPlane

    this.x = clamp(
      this.bounds.left + halfViewportWidth,
      this.x,
      this.bounds.right - halfViewportWidth
    )

    this.y = clamp(
      this.bounds.top + halfViewportHeight,
      this.y,
      this.bounds.bottom - halfViewportHeight
    )

proc screenToWorldCoord*(this: Camera, screenPoint: Vector, relativeZ: float = 1.0): Vector =
  if relativeZ == 1.0:
    return this.viewport.topLeft + screenPoint
  else:
    let
      screenCenter = this.viewport.getSize() * 0.5
      screenCenterToPoint = screenPoint - screenCenter
      scaledScreenPoint = screenCenterToPoint * relativeZ
    return this.viewport.center + scaledScreenPoint

template screenToWorldCoord*(this: Camera, x, y: float|int, relativeZ: float = 1.0): Vector =
  this.screenToWorldCoord(vector(x, y), relativeZ)

method setLocation*(this: Camera, x, y: float) =
  procCall Entity(this).setLocation(x, y)
  this.updateViewport()

method update*(this: Camera, deltaTime: float) =
  procCall Entity(this).update(deltaTime)

  if this.trackedEntity == nil:
    # Don't need to track a entity
    return

  if this.easingFunction == nil:
    this.setLocation(this.trackedEntity.getLocation())
  else:
    this.setLocation(
      this.easingFunction(
        this.getLocation(),
        this.trackedEntity.getLocation() + this.offset,
        this.completionRatioPerFrame
      )
    )

  this.confineToBounds()

