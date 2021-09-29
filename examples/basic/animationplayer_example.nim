import ../../src/shade

const
  width = 1920
  height = 1080

initEngineSingleton("Basic Example Game", width, height)
let layer = newPhysicsLayer(newSpatialGrid(150))
Game.scene.addLayer layer

type King = ref object of Entity
  sprite*: Sprite
  animPlayer*: AnimationPlayer

let (_, image) = Images.loadImage("./examples/basic/assets/images/king.png")
let king = King(
  sprite: newSprite(image, 11, 8),
  animPlayer: nil,
  flags: {loUpdate, loRender, loPhysics}
)

# Set up the run animation
let runAnim = newAnimation(1.1)
let frames: seq[KeyFrame[IVec2]] =
  @[
    (ivec2(0, 5), 0.0),
    (ivec2(10, 5), 1.0),
  ]

runAnim.addNewAnimationTrack(
  king.sprite.frameCoords,
  frames
)

king.animPlayer = newAnimationPlayer(("run", runAnim))
king.animPlayer.playAnimation("run")

method update(this: King, deltaTime: float) =
  procCall Entity(this).update(deltaTime)
  this.animPlayer.update(deltaTime)

render(King, Entity):
  this.sprite.render(ctx)

  if callback != nil:
    callback()

king.center = vec2(200, 200)
layer.add king

Game.start()

