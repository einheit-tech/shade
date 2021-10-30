import
  node,
  constants,
  ../math/rectangle,
  ../game/gamestate

type
  Camera* = ref object of Node
    z*: float
    bounds*: Rectangle
    viewport: Rectangle

    # For node tracking
    offset*: DVec2
    trackedNode*: Node
    completionRatioPerFrame*: CompletionRatio
    easingFunction*: EasingFunction[DVec2]

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
  easingFunction: EasingFunction[DVec2] = lerp
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

proc setTrackingEasingFunction*(this: Camera, easingFunction: EasingFunction[DVec2]) =
  this.easingFunction = easingFunction

proc setTrackedNode*(this: Camera, n: Node) =
  this.trackedNode = n

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

proc calcTranslation(this: Camera): DVec2 =
  result = this.center - gamestate.resolutionMeters * 0.5

  if result.x < this.bounds.left:
    result.x = this.bounds.left
  elif (result.x + gamestate.resolutionMeters.x) > this.bounds.right:
    result.x = this.bounds.right - gamestate.resolutionMeters.x

  if result.y < this.bounds.top:
    result.y = this.bounds.top
  elif (result.y + gamestate.resolutionMeters.y) > this.bounds.bottom:
    result.y = this.bounds.bottom - gamestate.resolutionMeters.y

template renderInViewportSpace*(this: Camera, body: untyped): untyped =
  let translation = calcTranslation(this) * meterToPixelScalar
  translate(-translation.x, -translation.y, 0)
  body
  translate(translation.x, translation.y, 0)

