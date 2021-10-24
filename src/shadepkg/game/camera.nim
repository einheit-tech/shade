import
  node,
  ../input/inputhandler

type Camera* = ref object of Node
  # TODO: Maybe give camera a DVec3 for z order?
  offset*: DVec2
  trackedNode*: Node
  completionRatioPerFrame*: CompletionRatio
  easingFunction*: EasingFunction[DVec2]

proc initCamera*(camera: Camera) =
  initNode(Node(camera), {loUpdate})

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

  let targetPosition = this.trackedNode.center + this.offset

  if this.easingFunction == nil:
    this.center = targetPosition
  else:
    this.center = this.easingFunction(this.center, targetPosition, this.completionRatioPerFrame)

