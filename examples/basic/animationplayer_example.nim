import ../../src/shade

# 12x11 sprite sheet
# 5 missing from end
# 132 - 5 = 127 images
# Let's render each image (change coord after a time interval)

const
  width = 1920
  height = 1080

var game: Game = newGame("Basic Example Game", width, height)
let layer = newPhysicsLayer(newSpatialGrid(150))
game.scene.addLayer layer

type Red = ref object of Entity
  sprite*: Sprite
  animPlayer*: AnimationPlayer

# Loads the individual sprite images.
let spritesheet = newSpritesheet("./examples/basic/assets/images/red-riding-hood.png", 11, 12)
spritesheet.loadSprites()

let red = Red(
  sprite: newSprite(spritesheet),
  animPlayer: nil,
  flags: {loUpdate, loRender, loPhysics}
)

# Set up the run animation
let runAnim = newAnimation(0.6)
let frames: seq[KeyFrame[IVec2]] =
  @[
    (ivec2(0, 1), 0.0),
    (ivec2(1, 1), 0.05),
    (ivec2(2, 1), 0.10),
    (ivec2(3, 1), 0.15),
    (ivec2(4, 1), 0.20),
    (ivec2(5, 1), 0.25),
    (ivec2(6, 1), 0.35),
    (ivec2(7, 1), 0.40),
    (ivec2(8, 1), 0.45),
    (ivec2(9, 1), 0.50),
    (ivec2(10, 1), 0.55),
  ]

runAnim.addNewAnimationTrack(
  red.sprite.frameCoords,
  frames
)

red.animPlayer = newAnimationPlayer(("run", runAnim))
red.animPlayer.playAnimation("run")

method update(this: Red, deltaTime: float) =
  procCall Entity(this).update(deltaTime)
  this.animPlayer.update(deltaTime)

render(Red, Entity):
  this.sprite.render(ctx)

  if callback != nil:
    callback()

layer.add red

game.start()

