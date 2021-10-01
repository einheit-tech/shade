import ../../src/shade

const
  width = 1920
  height = 1080

initEngineSingleton("Basic Example Game", width, height)
let layer = newLayer()
Game.scene.addLayer layer

let (_, image) = Images.loadImage("./examples/basic/assets/images/king.png")
image.setImageFilter(FILTER_NEAREST)

let king = newSprite(image, 11, 8)
king.scale = vec2(3.0, 3.0)

# Set up the run animation
let runAnim = newAnimation(1.1)
let frames: seq[KeyFrame[IVec2]] =
  @[
    (ivec2(0, 7), 0.0),
    (ivec2(7, 7), 1.0),
  ]

runAnim.addNewAnimationTrack(
  king.frameCoords,
  frames
)

let animPlayer = newAnimationPlayer(("run", runAnim))
animPlayer.playAnimation("run")
king.addChild(animPlayer)

king.center = vec2(200, 200)
layer.addChild king

Game.start()

