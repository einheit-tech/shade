import ../../src/shade

const
  width = 400
  height = 300

initEngineSingleton("Animation Player Example", width, height)
let layer = newLayer()
Game.scene.addLayer(layer)

let (_, image) = Images.loadImage("./examples/assets/images/king.png", FILTER_NEAREST)

let king = newSpriteEntity(newSprite(image, 11, 8))

# Set up the run animation
const
  frameSpeed = 0.08
  frameCount = 8
  animDuration = frameCount * frameSpeed

let runAnim = newAnimation(animDuration, true)

# Change the spritesheet coordinate
let animCoordFrames: seq[KeyFrame[IVector]] =
  @[
    (ivector(0, 7), 0.0),
    (ivector(7, 7), animDuration - frameSpeed),
  ]

runAnim.addNewAnimationTrack(
  king.sprite.frameCoords,
  animCoordFrames
)

# Change the scale
let scaleFrames: seq[KeyFrame[Vector]] =
  @[
    (vector(3, 3), 0.0),
    (vector(3.3, 3.3), animDuration / 2),
  ]

runAnim.addNewAnimationTrack(
  king.sprite.scale,
  scaleFrames,
  true
)

let animPlayer = newAnimationPlayer(("run", runAnim))
animPlayer.playAnimation("run")

king.onUpdate = proc(this: Node, deltaTime: float) =
  animPlayer.update(deltaTime)

king.setLocation(vector(width / 2, height / 2))
layer.addChild king

Input.onKeyPressed(K_ESCAPE):
  Game.stop()

Game.start()

