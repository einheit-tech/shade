import ../vector2

type CollisionResult* = ref object
  isCollisionOwnerA*: bool
  intrusion*: float
  contactNormal*: Vector2
  contactRatio*: float
  contactPoint*: Vector2

proc newCollisionResult*(
  isCollisionOwnerA: bool,
  intrusion: float,
  contactNormal: Vector2,
  contactPoint: Vector2,
  contactRatio: float = NaN
): CollisionResult =
  ## @param isCollisionOwnerA:
  ##   If the object that owns this collision result is object A.
  ##
  ## @param intrusion:
  ##   The distance the objects overlap along the contact normal.
  ##
  ## @param contactNormal:
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
    contactNormal: contactNormal,
    contactRatio: contactRatio,
    contactPoint: contactPoint
  )

proc flip*(this: CollisionResult): CollisionResult =
  ## Produces a collision result which reflects information about the opposite object.
  return newCollisionResult(
    not this.isCollisionOwnerA,
    this.intrusion,
    this.contactNormal.negate(),
    this.contactPoint,
    this.contactRatio
  )

proc getMinimumTranslationVector*(this: CollisionResult): Vector2 =
  ## Calculates a vector which can be used to separate the objects.
  ## This vector may be seen abbreviated as `mtv`.
  return this.contactNormal * -this.intrusion

