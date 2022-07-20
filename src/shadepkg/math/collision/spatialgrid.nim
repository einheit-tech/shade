import tables, sets, math
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
  CellID = string
  SpatialCell = object
    cellID: CellID
    entities: HashSet[PhysicsBody]
  SpatialGrid* = ref object
    # All entities is the grid.
    entities: HashSet[PhysicsBody]
    cells: TableRef[CellID, SpatialCell]
    cellSize: Positive
    # Scalar from grid coords to game coords.
    gridToPixelScalar: float

proc newSpatialCell(cellID: CellID): SpatialCell = SpatialCell(cellID: cellID)

template add(this: var SpatialCell, body: PhysicsBody) =
  this.entities.incl(body)

iterator forEachPhysicsBody(this: SpatialCell): PhysicsBody =
  for body in this.entities:
    yield body

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
    cellSize: cellSize.int,
    gridToPixelScalar: 1.0 / cellSize.float
  )

iterator items*(this: SpatialGrid): PhysicsBody =
  for e in this.entities:
    yield e

template getCellID(cellX, cellY: int): CellID =
  $cellX & "," & $cellY

template scaleToGrid*(this: SpatialGrid, rect: AABB): AABB =
  rect.getScaledInstance(this.gridToPixelScalar)

iterator cellInBounds*(this: SpatialGrid, queryRect: AABB): tuple[x, y: int] =
  ## Finds each cell in the given bounds.
  ## @param queryRect:
  ##   A rectangle scaled to the size of the grid.
  let
    topLeft = queryRect.topLeft
    bottomRight = queryRect.bottomRight
  for x in floor(topLeft.x).int .. floor(bottomRight.x).int:
    for y in floor(topLeft.y).int .. floor(bottomRight.y).int:
      yield (x, y)

template addPhysicsBodyWithBounds(this: SpatialGrid, body: PhysicsBody, bounds: AABB) =
  ## Adds an body to the grid.
  ## Assumes the bounds are not nil.
  this.entities.incl(body)
  for cell in this.cellInBounds(bounds):
    let cellID = getCellID(cell.x, cell.y)
    var cell = this.cells.getOrDefault(cellID, newSpatialCell(cellID))
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
    minX = if delta.x > 0.0: this.x else: this.x + delta.x
    minY = if delta.y > 0.0: this.y else: this.y + delta.y
    width = this.width + abs(delta.x)
    height = this.height + abs(delta.y)

  return newAABB(minX, minY, minX + width, minY + height)

proc addPhysicsBody*(this: SpatialGrid, body: PhysicsBody, deltaMovement: Vector) =
  ## Adds an body to the grid.
  ## If the body's bounds are nil, this proc will do nothing.
  if not this.canPhysicsBodyBeAdded(body):
    return

  let bounds = body.bounds.getRectangleMovementBounds(deltaMovement)
  this.addPhysicsBodyBounds(body, this.scaleToGrid(bounds))

proc removeFromCells*(
  this: var SpatialGrid,
  body: PhysicsBody,
  cellIDs: openArray[CellID]
) =
  ## Removes the body from all given cells.
  for id in cellIDs:
    if this.cells.hasKey(id):
      this.cells[id].entities.excl(body)

proc query*(
  this: SpatialGrid,
  bounds: AABB
): tuple[entities: HashSet[PhysicsBody], cellIDs: seq[CellID]] =

  let scaledBounds: AABB = this.scaleToGrid(bounds)
  # Find all cells that intersect with the bounds.
  for x, y in this.cellInBounds(scaledBounds):
    let cellID = getCellID(x, y)
    if this.cells.hasKey(cellID):
      result.cellIDs.add(cellID)
      let cell = this.cells[cellID]
      # Add all body in each cell.
      for body in cell.forEachPhysicsBody:
        result.entities.incl(body)

proc clear*(this: SpatialGrid) =
  ## Clears the entire grid.
  this.cells.clear()
  this.entities.clear()

