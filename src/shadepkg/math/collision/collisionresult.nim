import ../mathutils

type CollisionResult* = ref object
  isCollisionOwnerA*: bool
  intrusion*: float
  normal*: Vector
  contactRatio*: float
  contactPoint*: Vector

proc newCollisionResult*(
  isCollisionOwnerA: bool,
  intrusion: float,
  normal: Vector,
  contactPoint: Vector,
  contactRatio: float = NaN
): CollisionResult =
  ## @param isCollisionOwnerA:
  ##   If the object that owns this collision result is object A.
  ##
  ## @param intrusion:
  ##   The distance the objects overlap along the contact normal.
  ##
  ## @param normal:
  ##   The axis that the objects first make contact along.
  ##   The vector points away from the object that owns this collision result.
  ##
  ## @param contactRatio:
  ##   The ratio of the distance moved before the objects first collide.
  ##   If equal to `NaN`, there is no ratio because this was a static collision.
  ##
  ## @param contactPoint:
  ##   An estimated location of the collision. 
  CollisionResult(
    isCollisionOwnerA: isCollisionOwnerA,
    intrusion: intrusion,
    normal: normal,
    contactRatio: contactRatio,
    contactPoint: contactPoint
  )

proc flip*(this: CollisionResult): CollisionResult =
  ## Produces a collision result which reflects information about the opposite object.
  return newCollisionResult(
    not this.isCollisionOwnerA,
    this.intrusion,
    this.normal.negate(),
    this.contactPoint,
    this.contactRatio
  )

template getMinimumTranslationVector*(this: CollisionResult): Vector =
  ## Calculates a vector which can be used to separate the objects.
  ## This vector may be seen abbreviated as `mtv`.
  this.normal * -this.intrusion

