## A pool of reusable objects.

type ObjectPool*[O] = object
  pool: seq[O]
  factoryFunction: proc: O
  resetObjectFunction: proc(o: var O)
  capacity: int

proc newObjectPool*[O](
  factoryFunction: proc: O,
  resetObjectFunction: proc(o: var O) = nil,
  capacity: int = -1
): ObjectPool[O] =
  result = ObjectPool[O](
    factoryFunction: factoryFunction,
    resetObjectFunction: resetObjectFunction,
    capacity: capacity
  )

proc len*(this: ObjectPool): int =
  ## Returns the number of objects in the pool.
  return this.pool.len

proc isEmpty*(this: ObjectPool): bool =
  return this.pool.len == 0

proc isFull*(this: ObjectPool): bool =
  return this.pool.len == this.capacity

proc getCapacity*(this: ObjectPool): int =
  ## Returns the capacity of the pool.
  ## If the capacity is less than 0, it has no limit.
  return this.capacity

proc setCapacity*(this: ObjectPool, capacity: int) =
  ## Sets the capacity of the pool.
  ## If the capacity is less than 0, it has no limit.
  this.capacity = capacity

proc getRemainingSpace*(this: ObjectPool): int =
  ## Gets the remaining space in the pool.
  if this.capacity < 0:
    return int.high
  return this.capacity - this.pool.len

proc get*[O](this: var ObjectPool[O]): O =
  if this.pool.len > 0:
    result = this.pool.pop()
    if this.resetObjectFunction != nil:
      this.resetObjectFunction(result)
  else:
    return this.factoryFunction()

proc recycle*[O](this: var ObjectPool[O], o: O): bool =
  ## Attempts to add an object to the pool.
  ## Returns if the pool was not full, and added the object.
  if this.isFull():
    return false

  this.pool.add(o)
  return true

