import nico

import
  options,
  math,
  random,
  algorithm,
  sequtils

import
  vector2,
  rectangle

export
  vector2,
  rectangle

type Polygon* = ref object
  vertices: seq[Vector2]
  bounds: Rectangle
  center: Option[Vector2]
  clockwise: Option[bool]
  area: Option[float]

proc newPolygon*(vertices: openArray[Vector2]): Polygon =
  if vertices.len < 3:
    raise newException(Exception, "Polygon must have at least 3 vertices.")
  result = Polygon(vertices: toSeq(vertices))

func len*(this: Polygon): int = this.vertices.len

func `[]`*(this: Polygon, i: int): Vector2 = this.vertices[i]
proc `[]=`*(this: var Polygon, i: int, vector: Vector2) =
  this.vertices[i] = vector

iterator items*(this: Polygon): Vector2 =
  for v in this.vertices:
    yield v

iterator pairs*(this: Polygon): (int, Vector2) =
  for i, v in this.vertices:
    yield (i, v)

func project*(this: Polygon, location, axis: Vector2): Vector2 =
  let startLoc = this[0] + location
  var
    dotProduct = axis.dotProduct(startLoc)
    min = dotProduct
    max = dotProduct
  for i in 0..<this.len:
    let currLoc = this[i] + location
    dotProduct = axis.dotProduct(currLoc)
    if dotProduct < min:
      min = dotProduct
    if dotProduct > max:
      max = dotProduct
  return initVector2(min, max)

func getLinePixels*(v1, v2: Vector2, outPixels: var seq[Vector2]) =
  ## Generates an array of points which lie on the parameterized line.
  ## @param v1:
  ##   The starting point on the line.
  ##
  ## @param v2:
  ##   The end point of the line.
  ##
  ## @param outPixels:
  ##   The array of pixels to add the pixel locations to.
  let
    edgeX = v2.x - v1.x
    edgeY = v2.y - v1.y
  var slope = edgeY / edgeX

  if edgeX == 0 or slope > 1.0:
    ## Steep slopes
    let
      signY = sgn(edgeY).float
      inverseSlope = (edgeX / edgeY) * signY
      v1y = round(v1.y)
      v2y = round(v2.y)

    var
      x = v1.x
      y = v1y
    while y != v2y:
      outPixels.add(initVector2(round(x), y))
      x += inverseSlope
      y += signY
  else:
    ## Gentle slopes
    let
      signX = sgn(edgeX).float
      v1x = round(v1.x)
      v2x = round(v2.x)
    slope *= signX

    var
      x = v1x
      y = v1.y
    while x != v2x:
      outPixels.add(initVector2(x, round(y)))
      x += signX
      y += slope

func generatePerimeterPixels*(this: Polygon): seq[Vector2] =
  ## Generates an array of points which lie on the Polygon's perimeter.
  var lastVertex = this.vertices[this.vertices.high]
  for i, vertex in this:
    getLinePixels(lastVertex, vertex, result)
    lastVertex = vertex

func getAverage*(this: Polygon): Vector2 =
  ## Calculates the average of all of the vertices in the polygon.
  var
    x = 0f
    y = 0f
  for i, v in this:
    x += v.x;
    y += v.y;
  let d = 1.0 / this.len.float;
  return initVector2(x * d, y * d)

func getBounds*(this: Polygon): Rectangle =
  ## Calculates the bounds of the polygon.
  if this.bounds != nil:
    # Bounds are lazy initialized.
    return this.bounds
  var
    minX = Inf
    minY = Inf
    maxX = NegInf
    maxY = NegInf
  for i, v in this:
    minX = min(minX, v.x)
    minY = min(minY, v.y)
    maxX = max(maxX, v.x)
    maxY = max(maxY, v.y)
  this.bounds =
    newRectangle(
      minX,
      minY,
      maxX - minX,
      maxY - minY
    )
  return this.bounds

func getArea*(this: Polygon): float =
  if this.area.isNone:
    var
      area: float = 0
      lastV: Vector2 = this[this.vertices.high]

    for i, v in this:
      let cross = lastV.crossProduct(v)
      area += cross
      lastV = v

    this.area = abs(area * 0.5).option

  return this.area.get

func center*(this: Polygon): Vector2 =
  ## Gets the centroid of the Polygon.
  if this.center.isSome:
    return this.center.get

  var
    area, x, y: float
    lastV = this[this.vertices.high]

  for i, v in this:
    let cross = lastV.crossProduct(v)
    area += cross
    x += (lastV.x + v.x) * cross
    y += (lastV.y + v.y) * cross
    lastV = v

  area *= 0.5
  let area6 = 1.0 / (area * 6.0)
  x *= area6
  y *= area6
  this.center = some(initVector2(x, y))
  return this.center.get

template getWidth*(this: Vector2): float = this.getBounds().width
template getHeight*(this: Vector2): float = this.getBounds().height
template getSize*(this: Vector2): Vector2 =
  Vector2(this.getWidth(), this.getHeight())

func getTranslatedInstance*(this: Polygon, delta: Vector2): Polygon =
  var verts: seq[Vector2]
  for v in this:
    verts.add(v + delta)
  return newPolygon(verts)

proc createRandomConvex*(vertexCount: int, width, height: float): Polygon =
  ## Generates a random convex polygon.
  ##
  ## http://cglab.ca/~sander/misc/ConvexGeneration/convex.html
  ##
  ## @param vertexCount:
  ##   The number of vertices the polygon should have.
  ##
  ## @param width:
  ##   The width of the polygon to generate.
  ##
  ## @param height:
  ##   The height of the polygon to generate.
  var
    xCoords: seq[float]
    yCoords: seq[float]

  # Generate lists of sorted random X and Y coordinates.
  for i in 0..<vertexCount:
    xCoords.add rand(1.0)
    yCoords.add rand(1.0)

  xCoords.sort()
  yCoords.sort()

  # Get min and max X and Y values.
  block _:
    let
      minX = xCoords[0]
      maxX = xCoords[vertexCount - 1] - minX
      minY = yCoords[0]
      maxY = yCoords[vertexCount - 1] - minY
      xRatio = width / maxX
      yRatio = height / maxY

    for i in 0..<vertexCount:
      xCoords[i] = (xCoords[i] - minX) * xRatio
      yCoords[i] = (yCoords[i] - minY) * yRatio

  # Divide interior points into two chains, and convert them to vector components.
  var
    xComponents: seq[float]
    yComponents: seq[float]
    topX, bottomX, leftY, rightY: float

  for i in 1..<vertexCount:
    # Find X
    let x = xCoords[i]
    # Pick true/false by random.
    if sample([true, false]):
      xComponents[i] = x - topX
      topX = x
    else:
      xComponents[i] = bottomX - x
      bottomX = x

    # Find Y
    let y = yCoords[i]
    if sample([true, false]):
      yComponents[i] = y - leftY
      leftY = y
    else:
      yComponents[i] = rightY - y
      rightY = y

  xComponents[0] = width - topX
  xComponents[vertexCount - 1] = bottomX - width
  yComponents[0] = height - leftY
  yComponents[vertexCount - 1] = rightY - height

  # Randomly pair X and Y components (only need to shuffle one of the arrays)
  shuffle(yComponents)

  # Combine the paired up components into vectors.
  var vectors: seq[Vector2]
  for i in 0..<vertexCount:
    vectors.add(initVector2(xComponents[i], yComponents[i]))

  # Sort the vectors by angle.
  vectors = vectors.sortedByIt(it.getAngleRadians())

  # Lay the vectors end-to-end.
  var
    x, y, minPolyX, minPolyY: float
    points: seq[Vector2]

  for i in 0..<vertexCount:
    points.add(initVector2(x, y))
    x += vectors[i].x
    y += vectors[i].y
    minPolyX = min(minPolyX, x)
    minPolyY = min(minPolyY, y)

  # Move the polygon to the origin.
  if minPolyX != 0 or minPolyY != 0:
    for i in 0..<vertexCount:
      points[i] = points[i].subtract(minPolyX, minPolyY)

  return newPolygon(points)

proc isClockwise*(this: Polygon): bool =
  ## Determines whether the polygon's vertices wind in the clockwise direction.
  ##
  ## How to determine if a list of polygon points are in clockwise-order:
  ## http://stackoverflow.com/questions/1165647/how-to-determine-if-a-list-of-polygon-points-are-in-clockwise-order
  ##
  ## Complexity: O(n), where 'n' is the number of vertices in the polygon.
  ## @returns {boolean} true if the polygon vertices wind the clockwise direction,
  ## or false if they wind in the counter-clockwise direction.
  if this.clockwise.isNone:
    var
      sum = 0f
      lastV = this[this.len - 1]
      currV: Vector2
    for i in 0..<this.len:
      currV = this[i]
      sum += (currV.x - lastV.x) * (currV.y + lastV.y)
      lastV = currV
    this.clockwise = (sum < 0.0).option
  return this.clockwise.get

proc rotate*(this: var Polygon, deltaRotation: float) =
  if deltaRotation == 0.0:
    return

  let center = center(this)
  for i, vertex in this:
    this[i] = vertex.rotateAround(deltaRotation, center)

  this.center = none(Vector2)

proc render*(this: Polygon, offset: Vector2 = VectorZero) =
  for i, v in this:
    let nextVert = this[(i + 1) mod this.len]
    line(
      offset.x + v.x,
      offset.y + v.y,
      offset.x + nextVert.x,
      offset.y + nextVert.y
    )

