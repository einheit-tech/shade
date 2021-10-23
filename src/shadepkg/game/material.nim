type Material* = object
  density*: 0.0 .. 1.0
  elasticity*: 0.0 .. 1.0
  friction*: 0.0 .. 1.0

proc initMaterial*(density, elasticity, friction: float): Material =
  Material(
    density: density,
    elasticity: elasticity,
    friction: friction
  )

const
  ROCK*: Material = initMaterial(0.8, 0.6, 0.1)
  METAL*: Material = initMaterial(0.98, 0.8, 0.03)
  PLATFORM*: Material = initMaterial(1, 1, 0.15)
  NULL*: Material = initMaterial(1, 0, 0)

