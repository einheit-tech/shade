import ../../src/shade

const
  width = 800
  height = 600

# TODO: Show full example with a game rendering.
var game: Game = newGame(width, height)
let layer = newLayer()
game.scene.addLayer layer

type CustomEntity = ref object of Entity

proc newCustomEntity(): CustomEntity =
  CustomEntity(
    flags: loUpdate,
    material: NULL,
    center: VectorZero
  )

method update*(this: CustomEntity, deltaTime: float) =
  echo "CustomEntity: " & $deltaTime

layer.add(newCustomEntity())

game.start()

