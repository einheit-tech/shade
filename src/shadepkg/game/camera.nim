import
  node,
  ../math/[aabb, vector2, mathutils],
  ../game/gamestate

export aabb, vector2, mathutils

type
  Camera* = ref object of Node
    z*: float
    bounds: AABB
    viewport*: AABB

    # For node tracking
    offset*: Vector
    trackedNode*: Node
    completionRatioPerFrame*: CompletionRatio
    easingFunction*: EasingFunction[Vector]

proc updateViewport*(this: Camera)

proc initCamera*(camera: Camera) =
  initNode(Node(camera), {LayerObjectFlags.UPDATE})
  camera.bounds = AABB_ZERO
  camera.viewport = AABB_ZERO
  camera.offset = VECTOR_ZERO
  camera.trackedNode = nil
  camera.completionRatioPerFrame = 1.0
  camera.easingFunction = lerp
  camera.updateViewport()

proc newCamera*(): Camera =
  result = Camera()
  initCamera(result)

proc newCamera*(
  trackedNode: Node,
  completionRatioPerFrame: CompletionRatio,
  easingFunction: EasingFunction[Vector] = lerp
): Camera =
  ## Creates a camera which follows a node.
  ## completionRatioPerFrame: The distance * CompletionRatio to travel each frame.
  ##   If set to 1, it would track the entity perfectly.
  ##   Set to 0, the camera will not move.
  ##   Typically, lower values are desired (0.1 - 0.3).
  ## easingFunction: Determines how the camera follows the tracked node.
  result = Camera()
  initCamera(result)
  result.trackedNode = trackedNode
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

proc setTrackedNode*(this: Camera, n: Node) =
  this.trackedNode = n

proc bounds*(this: Camera): AABB =
  if this.bounds == AABB_ZERO:
    this.bounds = aabb(float.low, float.low, float.high, float.high)
  return this.bounds

template confineToBounds(this: Camera) =
  if this.bounds != AABB_ZERO:
    let
      halfViewportWidth = this.viewport.width * 0.5
      halfViewportHeight = this.viewport.height * 0.5

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
  procCall Node(this).setLocation(x, y)
  this.updateViewport()

method update*(this: Camera, deltaTime: float) =
  procCall Node(this).update(deltaTime)

  if this.trackedNode == nil:
    # Don't need to track a node
    return

  if this.easingFunction == nil:
    this.setLocation(this.trackedNode.getLocation())
  else:
    this.setLocation(
      this.easingFunction(
        this.getLocation(),
        this.trackedNode.getLocation() + this.offset,
        this.completionRatioPerFrame
      )
    )

  this.confineToBounds()

