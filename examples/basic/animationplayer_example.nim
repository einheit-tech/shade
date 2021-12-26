import ../../src/shade

const
  width = 1920
  height = 1080

initEngineSingleton("Animation Player Example", width, height)
let layer = newLayer()
Game.scene.addLayer layer

let (_, image) = Images.loadImage("./examples/assets/images/king.png")
image.setImageFilter(FILTER_NEAREST)

let king = newSprite(image, 11, 8)

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
  king.frameCoords,
  animCoordFrames
)

# Change the scale
let scaleFrames: seq[KeyFrame[Vector]] =
  @[
    (vector(3, 3), 0.0),
    (vector(3.3, 3.3), animDuration / 2),
  ]

runAnim.addNewAnimationTrack(
  king.scale,
  scaleFrames,
  true
)

let animPlayer = newAnimationPlayer(("run", runAnim))
animPlayer.playAnimation("run")
king.addChild(animPlayer)

king.center = vector(200, 200) * pixelToMeterScalar
layer.addChild king

echo "start"
Game.start()

