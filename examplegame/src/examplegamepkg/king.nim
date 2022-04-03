import shade

proc createIdleAnimation(king: Sprite): Animation =
  const
    frameSpeed = 0.10
    frameCount = 8
    animDuration = frameCount * frameSpeed

  # Set up the idle animation
  let idleAnim = newAnimation(animDuration, true)

  # Change the spritesheet coordinate
  let animCoordFrames: seq[KeyFrame[IVector]] =
    @[
      (ivector(0, 5), 0.0),
      (ivector(10, 5), animDuration - frameSpeed),
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
  let animCoordFrames: seq[KeyFrame[IVector]] =
    @[
      (ivector(0, 7), 0.0),
      (ivector(7, 7), animDuration - frameSpeed),
    ]
  runAnim.addNewAnimationTrack(
    king.frameCoords,
    animCoordFrames
  )
  return runAnim

proc createKingSprite(): Sprite =
  let (_, image) = Images.loadImage("./assets/king.png", FILTER_NEAREST)
  result = newSprite(image, 11, 8)

proc createAnimPlayer(sprite: Sprite): AnimationPlayer =
  result = newAnimationPlayer()
  result.addAnimation("idle", createIdleAnimation(sprite))
  result.addAnimation("run", createRunAnimation(sprite))
  result.playAnimation("idle")

proc createCollisionShape(): CollisionShape =
  result = newCollisionShape(newAABB(-8, -13, 8, 13))
  result.material = initMaterial(1, 0, 0.97)

type King* = ref object of PhysicsBody
  animationPlayer: AnimationPlayer
  sprite: Sprite

proc createNewKing*(): King =
  result = King()
  initPhysicsBody(PhysicsBody(result))

  let sprite = createKingSprite()
  sprite.offset = vector(8.0, 1.0)
  result.sprite = sprite
  result.animationPlayer = createAnimPlayer(sprite)

  let collisionShape = createCollisionShape()
  result.collisionShape = collisionShape

proc playAnimation*(king: King, name: string) =
  king.animationPlayer.playAnimation(name)

method update*(this: King, deltaTime: float) =
  procCall PhysicsBody(this).update(deltaTime)
  this.animationPlayer.update(deltaTime)

King.renderAsChildOf(PhysicsBody):
  this.sprite.render(ctx)

