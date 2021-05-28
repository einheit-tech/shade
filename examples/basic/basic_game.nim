import ../../src/shade

const
  width = 800
  height = 600

# TODO: Show full example with a game rendering.
var game: Game = newGame("Basic Example Game", width, height)
let layer = newLayer()
game.scene.addLayer layer

type CustomEntity = ref object of Entity

proc newCustomEntity(): CustomEntity =
  CustomEntity(
    flags: loUpdateRender,
    material: NULL,
    center: Vec2()
  )

method update*(this: CustomEntity, deltaTime: float) =
  echo "CustomEntity: " & $deltaTime

method render*(this: CustomEntity, ctx: Context) =
  ctx.fillStyle = rgba(255, 0, 0, 255)
  let
    pos = vec2(50, 50)
    size = vec2(100, 100)
  ctx.fillRect(rect(pos, size))

layer.add(newCustomEntity())

game.start()

