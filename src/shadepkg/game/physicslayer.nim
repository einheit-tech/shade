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

type PhysicsLayer* = ref object of Layer

proc initPhysicsLayer*(
  layer: PhysicsLayer,
  gravity: DVec2 = DEFAULT_GRAVITY,
  z: float = 1.0
) =
  initLayer(layer, z)

proc newPhysicsLayer*(gravity: DVec2 = DEFAULT_GRAVITY, z: float = 1.0): PhysicsLayer =
  result = PhysicsLayer()
  initPhysicsLayer(result, gravity, z)

proc destroy*(this: PhysicsLayer) =
  this.removeAllChildren()

method onChildAdded*(this: PhysicsLayer, child: Node) =
  procCall Layer(this).onChildAdded(child)
  if child of PhysicsBody:
    # TODO: Add to quadtree/spatial hash/etc for broad phase.
    discard

method update*(this: PhysicsLayer, deltaTime: float) =
  procCall Layer(this).update(deltaTime)
  # TODO: Process physics

