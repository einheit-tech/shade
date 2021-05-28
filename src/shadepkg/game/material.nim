type Material* = object
  density*: 0.0 .. Inf
  restitution*: 0.0 .. Inf

proc initMaterial*(density, restitution: float): Material =
  Material(
    density: density,
    restitution: restitution
  )

const
  #  A material with the properties of a rock.
  #  @returns {Material}
  ROCK*: Material = initMaterial(0.6, 0.5)

  #  A material with the properties of metal.
  #  @returns {Material}
  METAL*: Material = initMaterial(1.2, 0.5)

    #  A material for objects with ghost-like physics.
  #  @type {Material}
  NULL*: Material = initMaterial(0, 0)

