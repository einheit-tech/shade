import std/[tables, sets, math]

import seq2d

import
  ../vector2,
  ../aabb,
  ../../game/physicsbody,
  ../../render/[render, color]

export
  sets,
  vector2,
  rectangle,
  node

type
  CellID = tuple[x: int, y: int]
  SpatialGrid* = ref object
   # Size in grid cells
    width: int
    height: int
    # All bodies is the grid.
    bodies: HashSet[PhysicsBody]
    cells: Seq2D[HashSet[PhysicsBody]]
    cellSize: Positive
    # Scalar from grid coords to game coords.
    gridToPixelScalar: float

proc newSpatialGrid*(width, height: static int, cellSize: Positive): SpatialGrid =
  ## @param width:
  ##  The width of the grid.
  ##
  ## @param height:
  ##  The height of the grid.
  ##
  ## @param cellSize:
  ##  The size of each cell in the grid.
  ##  This should be approx. double the size of the average body.
  SpatialGrid(
    width: width,
    height: height,
    cells: newSeq2D[HashSet[PhysicsBody]](width, height),
    cellSize: cellSize,
    gridToPixelScalar: 1.0 / cellSize.float
  )

iterator items*(this: SpatialGrid): PhysicsBody =
  for e in this.bodies:
    yield e

template scaleToGrid*(this: SpatialGrid, aabb: AABB): AABB =
  aabb.getScaledInstance(this.gridToPixelScalar)

iterator cellCoordsInBounds*(this: SpatialGrid, queryRect: AABB): tuple[x, y: int] =
  ## Finds each cell in the given bounds.
  ## @param queryRect:
  ##   A rectangle scaled to the size of the grid.
  let
    minX = max(0, floor(queryRect.left).int)
    maxX = min(this.width - 1, floor(queryRect.right).int)
    minY = max(0, floor(queryRect.top).int)
    maxY = min(this.height - 1, floor(queryRect.bottom).int)

  for x in minX .. maxX:
    for y in  minY .. maxY:
      yield (x, y)

template addPhysicsBodyWithBounds(this: SpatialGrid, body: PhysicsBody, bounds: AABB) =
  ## Adds an body to the grid.
  ## Assumes the bounds are not nil.
  this.bodies.incl(body)
  for x, y in this.cellCoordsInBounds(bounds):
    this.cells[x, y].incl(body)

template canPhysicsBodyBeAdded(this: SpatialGrid, body: PhysicsBody): bool =
  body.getBounds() != AABB_ZERO

proc getRectangleMovementBounds(this: AABB, delta: Vector): AABB =
  let
    minX = min(this.left, this.left + delta.x)
    minY = min(this.top, this.top + delta.y)
    width = this.width + abs(delta.x)
    height = this.height + abs(delta.y)
  return aabb(minX, minY, minX + width, minY + height)

proc add*(this: SpatialGrid, body: PhysicsBody, deltaMovement: Vector = VECTOR_ZERO) =
  ## Adds a body to the grid.
  ## If the body's bounds are == AABB_ZERO, this proc will do nothing.
  if not this.canPhysicsBodyBeAdded(body):
    return

  let bounds =
    if deltaMovement == VECTOR_ZERO:
      body.getBounds()
    else:
      body.getBounds().getRectangleMovementBounds(deltaMovement)

  this.addPhysicsBodyWithBounds(body, this.scaleToGrid(bounds))

proc removeFromCells*(this: var SpatialGrid, body: PhysicsBody, cellIDs: openArray[CellID]) =
  ## Removes the body from all given cells.
  for id in cellIDs:
    this.cells[id.x, id.y].excl(body)

proc query*(this: SpatialGrid, bounds: AABB): tuple[bodies: HashSet[PhysicsBody], cellIDs: seq[CellID]] =
  let scaledBounds: AABB = this.scaleToGrid(bounds)
  # Find all cells that intersect with the bounds.
  for x, y in this.cellCoordsInBounds(scaledBounds):
    let bodies = this.cells[x, y]
    if bodies.len > 0:
      # Add all bodies in the cell.
      result.bodies.incl(bodies)
      result.cellIDs.add((x, y))

proc clear*(this: SpatialGrid) =
  ## Clears the entire grid.
  this.cells.clear()
  this.bodies.clear()

SpatialGrid.render:
  let
    widthInPixels = float(this.width * this.cellSize)
    heightInPixels = float(this.height * this.cellSize)

  for x in 0..<this.width:
    let xInPixels = float(x * this.cellSize)
    ctx.line(
      offsetX + xInPixels,
      offsetY + 0,
      offsetX + xInPixels,
      offsetY + heightInPixels,
      GREEN
    )

  for y in 0..<this.height:
    let yInPixels = float(y * this.cellSize)
    ctx.line(
      offsetX + 0,
      offsetY + yInPixels,
      offsetX + widthInPixels,
      offsetY + yInPixels,
      GREEN
    )

