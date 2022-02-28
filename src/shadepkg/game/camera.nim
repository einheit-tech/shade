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

proc updateViewportSize*(this: Camera)

proc initCamera*(camera: Camera) =
  initNode(Node(camera), {loUpdate})
  camera.bounds = newRectangle(float.low, float.low, float.high, float.high)
  camera.updateViewportSize()

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

proc updateViewportSize*(this: Camera) =
  ## Updates the camera's viewport to fit the gamestate's resolution.
  if this.viewport == nil:
    this.viewport = newRectangle(
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

proc confineToBounds(this: Camera) =
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

