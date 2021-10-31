import
  chipmunk7

import
  constants,
  layer,
  physicsbody,
  ../math/mathutils

export
  layer,
  physicsbody

# TODO: Tune
const DEFAULT_GRAVITY* = dvec2(0, 2000 * pixelToMeterScalar)

type
  PhysicsLayer* = ref object of Layer
    space: Space

proc initPhysicsLayer*(
  layer: PhysicsLayer,
  gravity: DVec2 = DEFAULT_GRAVITY,
  z: float = 1.0
) =
  initLayer(layer, z)
  layer.space = newSpace()
  layer.space.gravity = cast[Vect](gravity)

proc newPhysicsLayer*(gravity: DVec2 = DEFAULT_GRAVITY, z: float = 1.0): PhysicsLayer =
  result = PhysicsLayer()
  initPhysicsLayer(result, gravity, z)

proc destroy*(this: PhysicsLayer) =
  # TODO: Should every node have a destroy proc?
  if this.space != nil:
    this.space.destroy()
  this.removeAllChildren()

method onChildAdded*(this: PhysicsLayer, child: Node) =
  procCall Layer(this).onChildAdded(child)
  if child of PhysicsBody:
    PhysicsBody(child).addToSpace(this.space)

method update*(this: PhysicsLayer, deltaTime: float) =
  procCall Layer(this).update(deltaTime)

  # TODO: I hope there's a better way to do this.
  # Found the solution at:
  # https://www.reddit.com/r/ebiten/comments/mghl4k/using_the_go_port_of_chipmunk2d_in_a_tile_based/gstvdhi/
  for i in 0..<6:
    this.space.step(deltaTime / 6)

