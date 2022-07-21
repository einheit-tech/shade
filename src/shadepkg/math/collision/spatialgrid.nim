import std/[tables, sets, math]

import
  ../vector2,
  ../aabb,
  ../../game/physicsbody

export
  sets,
  vector2,
  rectangle,
  node

type
  CellID = uint32
  SpatialCell = object
    cellID: CellID
    bodies: HashSet[PhysicsBody]
  SpatialGrid* = ref object
    # All bodies is the grid.
    bodies: HashSet[PhysicsBody]
    cells: TableRef[CellID, SpatialCell]
    cellSize: Positive
    # Scalar from grid coords to game coords.
    gridToPixelScalar: float

proc newSpatialCell(cellID: CellID): SpatialCell =
  SpatialCell(cellID: cellID)

template add(this: var SpatialCell, body: PhysicsBody) =
  this.bodies.incl(body)

proc newSpatialGrid*(width, height, cellSize: Positive): SpatialGrid =
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
    cells: newTable[CellID, SpatialCell](width * height),
    cellSize: cellSize,
    gridToPixelScalar: 1.0 / cellSize.float
  )

iterator items*(this: SpatialGrid): PhysicsBody =
  for e in this.bodies:
    yield e

template getCellID(cellX, cellY: uint16): CellID = 
  ## Aligns bits beside each other to create a unique cell id.
  (cellX.uint32 shl 16) or cellY

template scaleToGrid*(this: SpatialGrid, aabb: AABB): AABB =
  aabb.getScaledInstance(this.gridToPixelScalar)

iterator cellCoordsInBounds*(this: SpatialGrid, queryRect: AABB): tuple[x, y: uint16] =
  ## Finds each cell in the given bounds.
  ## @param queryRect:
  ##   A rectangle scaled to the size of the grid.
  for x in floor(queryRect.left).int .. floor(queryRect.right).int:
    for y in floor(queryRect.top).int .. floor(queryRect.bottom).int:
      yield (uint16 x, uint16 y)

template addPhysicsBodyWithBounds(this: SpatialGrid, body: PhysicsBody, bounds: AABB) =
  ## Adds an body to the grid.
  ## Assumes the bounds are not nil.
  this.bodies.incl(body)
  for x, y in this.cellCoordsInBounds(bounds):
    let cellID = getCellID(x, y)
    if this.cells.hasKey(cellID):
      this.cells[cellID].add(body)
    else:
      var cell = newSpatialCell(cellID)
      cell.add(body)
      this.cells[cellID] = cell

template canPhysicsBodyBeAdded(this: SpatialGrid, body: PhysicsBody): bool =
  body.getBounds() != nil

proc addStaticPhysicsBody*(this: SpatialGrid, body: PhysicsBody) =
  ## Adds an body to the grid.
  ## If the body's bounds are nil, this proc will do nothing.
  if not this.canPhysicsBodyBeAdded(body):
    return

  # Add the body to all cells its bounds intersect with.
  let bounds = this.scaleToGrid(body.getBounds())
  this.addPhysicsBodyWithBounds(body, bounds)

proc getRectangleMovementBounds(this: AABB, delta: Vector): AABB =
  let
    minX = min(this.left, this.left + delta.x)
    minY = min(this.top, this.top + delta.y)
    width = this.width + abs(delta.x)
    height = this.height + abs(delta.y)
  return newAABB(minX, minY, minX + width, minY + height)

proc addPhysicsBody*(this: SpatialGrid, body: PhysicsBody, deltaMovement: Vector) =
  ## Adds an body to the grid.
  ## If the body's bounds are nil, this proc will do nothing.
  if not this.canPhysicsBodyBeAdded(body):
    return

  let bounds = body.getBounds().getRectangleMovementBounds(deltaMovement)
  this.addPhysicsBodyWithBounds(body, this.scaleToGrid(bounds))

proc removeFromCells*(this: var SpatialGrid, body: PhysicsBody, cellIDs: openArray[CellID]) =
  ## Removes the body from all given cells.
  for id in cellIDs:
    if this.cells.hasKey(id):
      this.cells[id].bodies.excl(body)

proc query*(this: SpatialGrid, bounds: AABB): tuple[bodies: HashSet[PhysicsBody], cellIDs: seq[CellID]] =
  let scaledBounds: AABB = this.scaleToGrid(bounds)
  # Find all cells that intersect with the bounds.
  for x, y in this.cellCoordsInBounds(scaledBounds):
    let cellID = getCellID(x, y)
    if this.cells.hasKey(cellID):
      result.cellIDs.add(cellID)
      # Add all bodies in the cell.
      result.bodies.incl(this.cells[cellID].bodies)

proc clear*(this: SpatialGrid) =
  ## Clears the entire grid.
  this.cells.clear()
  this.bodies.clear()

