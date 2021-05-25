import tables, sets, math
import
  ../vector2,
  ../rectangle,
  ../../game/entity

export
  sets,
  vector2,
  rectangle,
  entity

type
  CellID = string
  SpatialCell = object
    cellID: CellID
    entities: HashSet[Entity]
  SpatialGrid* = ref object
    # All entities is the grid.
    entities: HashSet[Entity]
    cells: TableRef[CellID, SpatialCell]
    cellSize: Positive
    # Scalar from grid coords to game coords.
    gridToPixelScalar: float

proc newSpatialCell(cellID: CellID): SpatialCell = SpatialCell(cellID: cellID)

template add(this: var SpatialCell, entity: Entity) =
  this.entities.incl(entity)

iterator forEachEntity(this: SpatialCell): Entity =
  for entity in this.entities:
    yield entity

proc newSpatialGrid*(width, height, cellSize: Positive): SpatialGrid =
  ## @param width:
  ##  The width of the grid.
  ##
  ## @param height:
  ##  The height of the grid.
  ##
  ## @param cellSize:
  ##  The size of each cell in the grid.
  ##  This should be approx. double the size of the average entity.
  SpatialGrid(
    cells: newTable[CellID, SpatialCell](width * height),
    cellSize: cellSize.int,
    gridToPixelScalar: 1.0 / cellSize.float
  )

iterator items*(this: SpatialGrid): Entity =
  for e in this.entities:
    yield e

template getCellID(cellX, cellY: int): CellID =
  $cellX & "," & $cellY

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

template addEntityWithBounds(this: SpatialGrid, entity: Entity, bounds: Rectangle) =
  ## Adds an entity to the grid.
  ## Assumes the bounds are not nil.
  this.entities.incl(entity)
  for cell in this.cellInBounds(bounds):
    let cellID = getCellID(cell.x, cell.y)
    var cell = this.cells.getOrDefault(cellID, newSpatialCell(cellID))
    cell.add(entity)
    this.cells[cellID] = cell

template canEntityBeAdded(this: SpatialGrid, entity: Entity): bool =
  entity.bounds() != nil and entity.flags.includes(loPhysics)

proc addStaticEntity*(this: SpatialGrid, entity: Entity) =
  ## Adds an entity to the grid.
  ## If the entity's bounds are nil, this proc will do nothing.
  if not this.canEntityBeAdded(entity):
    return

  # Add the entity to all cells its bounds intersect with.
  let bounds = this.scaleToGrid(entity.bounds())
  this.addEntityWithBounds(entity, bounds)

proc getRectangleMovementBounds(this: Rectangle, delta: Vector2): Rectangle =
  let
    minX = if delta.x > 0.0: this.x else: this.x + delta.x
    minY = if delta.y > 0.0: this.y else: this.y + delta.y
    width = this.width + abs(delta.x)
    height = this.height + abs(delta.y)

  return newRectangle(
    minX, minY,
    width, height
  )

proc addEntity*(this: SpatialGrid, entity: Entity, deltaMovement: Vector2) =
  ## Adds an entity to the grid.
  ## If the entity's bounds are nil, this proc will do nothing.
  if not this.canEntityBeAdded(entity):
    return

  let bounds = entity.bounds.getRectangleMovementBounds(deltaMovement)
  this.addEntityWithBounds(entity, this.scaleToGrid(bounds))

proc removeFromCells*(
  this: var SpatialGrid,
  entity: Entity,
  cellIDs: openArray[CellID]
) =
  ## Removes the entity from all given cells.
  for id in cellIDs:
    if this.cells.hasKey(id):
      this.cells[id].entities.excl(entity)

proc query*(
  this: SpatialGrid,
  bounds: Rectangle
): tuple[entities: HashSet[Entity], cellIDs: seq[CellID]] =

  let scaledBounds: Rectangle = this.scaleToGrid(bounds)
  # Find all cells that intersect with the bounds.
  for x, y in this.cellInBounds(scaledBounds):
    let cellID = getCellID(x, y)
    if this.cells.hasKey(cellID):
      result.cellIDs.add(cellID)
      let cell = this.cells[cellID]
      # Add all entityects in each cell.
      for entity in cell.forEachEntity:
        result.entities.incl(entity)

proc clear*(this: SpatialGrid) =
  ## Clears the entire grid.
  this.cells.clear()
  this.entities.clear()

