import ../../src/shade

proc createIdleAnimation(king: Sprite): Animation =
  const
    frameSpeed = 0.10
    frameCount = 8
    animDuration = frameCount * frameSpeed

  # Set up the idle animation
  let idleAnim = newAnimation(animDuration, true)

  # Change the spritesheet coordinate
  let animCoordFrames: seq[KeyFrame[IVec2]] =
    @[
      (ivec2(0, 5), 0.0),
      (ivec2(10, 5), animDuration - frameSpeed),
    ]
  idleAnim.addNewAnimationTrack(
    king.frameCoords,
    animCoordFrames
  )
  return idleAnim

proc createRunAnimation(king: Sprite): Animation =
  const
    frameSpeed = 0.08
    frameCount = 8
    animDuration = frameCount * frameSpeed

  # Set up the run animation
  var runAnim = newAnimation(animDuration, true)

  # Change the spritesheet coordinate
  let animCoordFrames: seq[KeyFrame[IVec2]] =
    @[
      (ivec2(0, 7), 0.0),
      (ivec2(7, 7), animDuration - frameSpeed),
    ]
  runAnim.addNewAnimationTrack(
    king.frameCoords,
    animCoordFrames
  )
  return runAnim

proc createKingSprite(): Sprite =
  let (_, image) = Images.loadImage("./examples/assets/images/king.png")
  image.setImageFilter(FILTER_NEAREST)
  result = newSprite(image, 11, 8)

proc createAnimPlayer(sprite: Sprite): AnimationPlayer =
  result = newAnimationPlayer()
  result.addAnimation("idle", createIdleAnimation(sprite))
  result.addAnimation("run", createRunAnimation(sprite))
  result.playAnimation("idle")
  sprite.addChild(result)

proc createCollisionShape(): CollisionShape =
  result = newPolygonCollisionShape(
    newPolygon([
      dvec2(8, 13),
      dvec2(8, -13),
      dvec2(-8, -13),
      dvec2(-8, 13),
    ]).getScaledInstance(VEC2_PIXELS_TO_METERS)
  )

type King* = ref object of PhysicsBody
  animationPlayer: AnimationPlayer

proc createNewKing*(): King =
  result = King()
  initPlayerBody(
    PhysicsBody(result),
    material = NULL
  )

  let sprite = createKingSprite()
  sprite.x = 8.0 * pixelToMeterScalar
  result.addChild(sprite)
  result.animationPlayer = createAnimPlayer(sprite)

  let collisionShape = createCollisionShape()
  collisionShape.y = -2 * pixelToMeterScalar
  result.addChild(collisionShape)

proc playAnimation*(king: King, name: string) =
  king.animationPlayer.playAnimation(name)

