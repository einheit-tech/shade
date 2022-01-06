import ../mathutils

type CollisionResult* = ref object
  intrusion*: float
  normal*: Vector

proc newCollisionResult*(
  intrusion: float,
  normal: Vector
): CollisionResult =
  ## @param intrusion:
  ##   The distance the objects overlap along the contact normal.
  ##
  ## @param normal:
  ##   The axis that the objects first make contact along.
  ##   The vector points toward the object that owns this collision result.
  ##
  CollisionResult(
    intrusion: intrusion,
    normal: normal
  )

template getMinimumTranslationVector*(this: CollisionResult): Vector =
  ## Calculates a vector which can be used to separate the objects.
  ## This vector may be seen abbreviated as `mtv`.
  this.normal * this.intrusion

