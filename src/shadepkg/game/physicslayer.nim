import
  layer,
  physicsbody,
  ../math/mathutils

export
  layer,
  physicsbody

# TODO: Tune
const DEFAULT_GRAVITY* = vector(0, 2000)

type PhysicsLayer* = ref object of Layer

proc initPhysicsLayer*(
  layer: PhysicsLayer,
  gravity: Vector = DEFAULT_GRAVITY,
  z: float = 1.0
) =
  initLayer(layer, z)

proc newPhysicsLayer*(gravity: Vector = DEFAULT_GRAVITY, z: float = 1.0): PhysicsLayer =
  result = PhysicsLayer()
  initPhysicsLayer(result, gravity, z)

