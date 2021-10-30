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
  this.space.step(deltaTime)

