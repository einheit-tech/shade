import tables, sets, math, vmath
import
  ../rectangle,
  ../../game/physicsbody

export
  sets,
  rectangle,
  physicsbody

type
  CellID = tuple[x: int, y: int]
  SpatialCell = ref object
    cellID: CellID
    bodies: HashSet[PhysicsBody]
  SpatialGrid* = ref object
    # All bodies is the grid.
    bodies: HashSet[PhysicsBody]
    cells: Table[CellID, SpatialCell]
    cellSize: Positive
    # Scalar from grid coords to game coords.
    gridToPixelScalar: float

proc newSpatialCell(cellID: CellID): SpatialCell = SpatialCell(cellID: cellID)

template add(this: var SpatialCell, body: PhysicsBody) =
  this.bodies.incl(body)

iterator items(this: SpatialCell): PhysicsBody =
  for body in this.bodies:
    yield body

proc newSpatialGrid*(cellSize: Positive): SpatialGrid =
  ## @param cellSize:
  ##  The size of each cell in the grid.
  ##  This should be approx. double the size of the average body.
  SpatialGrid(
    cells: initTable[CellID, SpatialCell](),
    cellSize: cellSize.int,
    gridToPixelScalar: 1.0 / cellSize.float
  )

iterator items*(this: SpatialGrid): PhysicsBody =
  for e in this.bodies:
    yield e

template getCellID(cellX, cellY: int): CellID = (cellX, cellY)

template scaleToGrid*(this: SpatialGrid, rect: Rectangle): Rectangle =
  rect.getScaledInstance(this.gridToPixelScalar)

iterator cellInBounds*(this: SpatialGrid, queryRect: Rectangle): tuple[x, y: int] =
  ## Finds each cell in the given bounds.
  ## @param queryRect:
  ##   A rectangle scaled to the size of the grid.
  let
    topLeft = queryRect.topLeft()
    bottomRight = queryRect.bottomRight()
  for x in floor(topLeft.x).int .. floor(bottomRight.x).int:
    for y in floor(topLeft.y).int .. floor(bottomRight.y).int:
      yield (x, y)

template addBodyWithBounds(this: SpatialGrid, body: PhysicsBody, bounds: Rectangle) =
  ## Adds a body to the grid.
  ## Assumes the bounds are not nil.
  this.bodies.incl(body)
  for cell in this.cellInBounds(bounds):
    let cellID = getCellID(cell.x, cell.y)
    var cell: SpatialCell
    # TODO: Change when https://github.com/nim-lang/Nim/pull/18255 is merged.
    this.cells.withValue(cellID, storedCell) do:
      cell = storedCell[]
    do:
      cell = newSpatialCell(cellID)
      this.cells[cellID] = cell

    cell.add(body)

template canPhysicsBodyBeAdded(this: SpatialGrid, body: PhysicsBody): bool =
  body.bounds() != nil and loPhysics in body.flags

proc addStaticBody*(this: SpatialGrid, body: PhysicsBody) =
  ## Adds a body to the grid.
  ## If the body's bounds are nil, this proc will do nothing.
  if not this.canPhysicsBodyBeAdded(body):
    return

  # Add the body to all cells its bounds intersect with.
  let bounds = this.scaleToGrid(body.bounds())
  this.addBodyWithBounds(body, bounds)

proc getRectangleMovementBounds(this: Rectangle, delta: Vec2): Rectangle =
  let
    minX = if delta.x > 0.0: this.x else: this.x + delta.x
    minY = if delta.y > 0.0: this.y else: this.y + delta.y
    width = this.width + abs(delta.x)
    height = this.height + abs(delta.y)

  return newRectangle(
    minX, minY,
    width, height
  )

proc addBody*(this: SpatialGrid, body: PhysicsBody, deltaMovement: Vec2 = body.lastMoveVector) =
  ## Adds a body to the grid.
  ## If the body's bounds are nil, this proc will do nothing.
  if not this.canPhysicsBodyBeAdded(body):
    return

  let bounds = body.bounds.getRectangleMovementBounds(deltaMovement)
  this.addBodyWithBounds(body, this.scaleToGrid(bounds))

proc removeFromCells*(
  this: var SpatialGrid,
  body: PhysicsBody,
  cellIDs: openArray[CellID]
) =
  ## Removes the body from all given cells.
  for id in cellIDs:
    if this.cells.hasKey(id):
      this.cells[id].bodies.excl(body)

proc removeFromCell*(
  this: var SpatialGrid,
  body: PhysicsBody,
  cellID: CellID
) =
  if this.cells.hasKey(cellID):
    this.cells[cellID].bodies.excl(body)

proc query*(
  this: SpatialGrid,
  bounds: Rectangle
): tuple[bodies: HashSet[PhysicsBody], cellIDs: seq[CellID]] =

  # var res: tuple[body: PhysicsBody, cellID: CellID] 
  let scaledBounds: Rectangle = this.scaleToGrid(bounds)
  # Find all cells that intersect with the bounds.
  for x, y in this.cellInBounds(scaledBounds):
    let cellID = getCellID(x, y)
    if this.cells.hasKey(cellID):
      result.cellIDs.add(cellID)
      let cell = this.cells[cellID]
      # Add all bodies in each cell.
      for body in cell:
        result.bodies.incl(body)

proc clear*(this: SpatialGrid) =
  ## Clears the entire grid.
  this.bodies.clear()
  # TODO: This is slow for some reason.
  for cell in this.cells.values:
    cell.bodies.clear()

