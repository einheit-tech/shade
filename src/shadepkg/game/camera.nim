import
  node,
  ../math/rectangle,
  ../game/gamestate

export rectangle

type
  Camera* = ref object of Node
    z*: float
    bounds*: Rectangle
    viewport*: Rectangle

    # For node tracking
    offset*: Vector
    trackedNode*: Node
    completionRatioPerFrame*: CompletionRatio
    easingFunction*: EasingFunction[Vector]

proc initCamera*(camera: Camera) =
  initNode(Node(camera), {loUpdate})
  camera.bounds = newRectangle(float.low, float.low, float.high, float.high)
  camera.viewport =
    newRectangle(
      camera.x - gamestate.resolutionMeters.x * 0.5,
      camera.y - gamestate.resolutionMeters.y * 0.5,
      camera.x + gamestate.resolutionMeters.x * 0.5,
      camera.y + gamestate.resolutionMeters.y * 0.5
    )

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

proc setTrackingEasingFunction*(this: Camera, easingFunction: EasingFunction[Vector]) =
  this.easingFunction = easingFunction

proc setTrackedNode*(this: Camera, n: Node) =
  this.trackedNode = n

proc confineToBounds(this: Camera) =
  let halfResSize = resolutionMeters * 0.5
  this.x = clamp(
    this.bounds.left + halfResSize.x,
    this.center.x,
    this.bounds.right - halfResSize.x
  )

  this.y = clamp(
    this.bounds.top + halfResSize.y,
    this.center.y,
    this.bounds.bottom - halfResSize.y
  )

method update*(this: Camera, deltaTime: float) =
  procCall Node(this).update(deltaTime)

  if this.trackedNode == nil:
    # Don't need to track a node
    return

  if this.easingFunction == nil:
    this.center = this.trackedNode.center
  else:
    this.center = this.easingFunction(
      this.center,
      this.trackedNode.center + this.offset,
      this.completionRatioPerFrame
    )

  this.confineToBounds()

