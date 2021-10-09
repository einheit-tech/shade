{.experimental: "codeReordering".}

import
  node,
  ../input/inputhandler

type Camera* = ref object of Node
  trackedNode*: Node

proc newCamera*(trackedNode: Node): Camera =
  # let loc = calcRenderOffset(trackedNode, Input.mouseLocation)
  return Camera(
    flags: {loUpdate},
    trackedNode: trackedNode
  )

template calcRenderOffset(trackedNode: Node, loc: DVec2): DVec2 =
  let dist = loc - trackedNode.center
  trackedNode.center + dist * 0.33

proc update*(this: Camera, dt: float) =
  procCall Node(this).update(dt)
  # TODO
  # let loc = Input.mouseLocation
  # let preferredLoc = calcRenderOffset(this.trackedNode, loc)
  # this.translate((preferredLoc - this.center) * (5 * dt))

