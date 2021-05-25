import math, random

import vector2, mathutils

type
  PerlinGrid = object
    gradientVectors: seq[seq[Vector2]]
    width, height: int

proc newPerlinGrid*(width, height: int): PerlinGrid =
  ## gradientVectors are random unit vectors stored at each node in the grid.
  ## They are used to calculate the noise value at random points within neighboring nodes.

  ## Creates a two dimensional grid used to calculate Perlin noise values.
  ## This grid has a random unit vector at each whole number coordinate.
  ## The width and height of this grid must be whole numbers,
  ## and will be rounded up the parameters do not reflect this rule.
  ##
  ## @param {int} width The width of the grid.
  ## @param {int} height The height of the grid.
  result = PerlinGrid(width: width, height: height)

  ## Generate and store gradient vectors.
  for x in 0..result.width:
    for y in 0..result.height:
      ## These vectors are used for random directional purposes only.
      result.gradientVectors[x][y] =
        initVector2(
          rand(-1..1),
          rand(-1..1)
        ).normalize()

template getWidth*(this: PerlinGrid): int =
  ## @return {int} The width of the grid.
  this.width

template getHeight*(this: PerlinGrid): int =
  ## @return {int} The height of the grid.
  this.height

func getGradientVector*(this: PerlinGrid, x, y: int): Vector2 =
  ## Returns the gradient vector of the parent node where the parametrized point lies.
  ## @param {int} x An x coordinate within the grid.
  ## @param {int} y A y coordinate within the grid.
  if x < 0 or x > this.width or y < 0 or y > this.height:
    raise newException(Exception, "x and y must be within the grid's bounds.")
  return this.gradientVectors[x][y]

func getGridGradientDot*(this: PerlinGrid, nodeX, nodeY, x, y: float): float =
  ## Returns the dot product of the gradient and distance vectors
  ## relative to the random point on the grid.
  ## The return value is normalized to fall between 0 and 1.0.
  ## @param {float} nodeX The x coordinate of the node on the grid.
  ## @param {float} nodeY The y coordinate of the node on the grid.
  ## @param {float} x The random x coordinate on the grid.
  ## @param {float} y The random y coordinate on the grid.
  ## @return {float}
  let v = initVector2(x - nodeX, y - nodeY)
  return (this.getGradientVector(nodeX.int, nodeY.int).dotProduct(v) + 1) / 2

func getNoise*(this: PerlinGrid, x, y: float): float =
  ## Returns a value between 0.0 and 1.0,
  ## determined by the grid's characteristics and the random coordinate.
  ## @param {float} x The random x coordinate on the grid.
  ## @param {float} y The random y coordinate on the grid.
  ## @return {float}

  # Constrain for functions such as PerlinNoise#getNoiseAtOctaves.
  let
    x0: float = x mod this.width.float
    x1 = x0 + 1
    y0 = y mod this.width.float
    y1 = y0 + 1
    sx = smootherStep((x - x0).float)
    sy = smootherStep((y - y0).float)

  let
    a = lerp(
      this.getGridGradientDot(x0, y0, x, y),
      this.getGridGradientDot(x1, y0, x, y),
      sx
    )
    b = lerp(
      this.getGridGradientDot(x0, y1, x, y),
      this.getGridGradientDot(x1, y1, x, y),
      sx
    )
  return lerp(a, b, sy)

func getNoiseAtOctaves*(this: PerlinGrid, x, y, persistence: float, octaves: int): float =
  ## Returns Perlin Noise (see PerlinNoise#getNoise())
  ## @param {PerlinGrid} grid The grid used to calculate the noise values.
  ## @param {float} x The random x location in the grid.
  ## @param {float} y The random y location in the grid.
  ## @param {float} persistence The quantity of influence each successive octave.
  ## @param {int} octaves The number of octaves to sample from.
  ## should have on noise generation.
  ## @return {float}
  var
    ## The period at which data is sampled.
    total = 0f
    ## The range in which the result can lie.
    frequency = 1f
    amplitude = 1f
    maxValue = 0f

  for i in 0..octaves:
    total += this.getNoise(x * frequency, y * frequency) * amplitude.float
    maxValue += amplitude
    amplitude *= persistence
    frequency *= 2
  return total / maxValue.float

