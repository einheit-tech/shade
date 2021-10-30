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

let runAnim = newAnimation(animDuration)

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

# Change the scale
let scaleFrames: seq[KeyFrame[DVec2]] =
  @[
    (dvec2(3, 3), 0.0),
    (dvec2(3.3, 3.3), animDuration / 2),
  ]

runAnim.addNewAnimationTrack(
  king.scale,
  scaleFrames,
  true
)

let animPlayer = newAnimationPlayer(("run", runAnim))
animPlayer.playAnimation("run")
king.addChild(animPlayer)

king.center = dvec2(200, 200) * pixelToMeterScalar
layer.addChild king

Game.start()

