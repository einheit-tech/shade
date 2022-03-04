import deques

type
  SafeSet*[T] = ref object
    elements: seq[T]
    areElementsLocked: bool
    elementsToAdd: Deque[T]
    elementsToRemove: Deque[T]

proc newSafeSet*[T](): SafeSet[T] =
  SafeSet[T]()

proc add*[T](this: SafeSet[T], t: T) =
  ## Adds an item to the set.
  if this.areElementsLocked:
    this.elementsToAdd.addLast(t)
  else:
    this.elements.add(t)

proc removeNow[T](this: SafeSet[T], t: T) =
  ## Unsafe immediate removal of elements.
  var index = -1
  for i, l in this.elements:
    if l == t:
      index = i
      break
  
  if index >= 0:
    this.elements.delete(index)

proc remove*[T](this: SafeSet[T], t: T) =
  ## Removes an item from the set.
  if this.areElementsLocked:
    this.elementsToRemove.addLast(t)
  else:
    this.removeNow(t)

iterator items*[T](this: SafeSet[T]): lent T =
  ## Safely iterates over the items in the set.
  ## You may attempt to add and remove items during this iteration;
  ## however, additions/removals will not take effect until the next iteration.

  # Lock the elements
  this.areElementsLocked = true

  # Remove all elements in the removal queue.
  while this.elementsToRemove.len > 0:
    this.removeNow(this.elementsToRemove.popFirst())

  # Add all elements in the addition queue.
  while this.elementsToAdd.len > 0:
    this.elements.add(this.elementsToAdd.popFirst())

  # Yield all elements currently in the set.
  for e in this.elements:
    yield e

  # Finally "unlock" the SafeSet.
  this.areElementsLocked = false

iterator mitems*[T](this: SafeSet[T]): T =
  ## Safely iterates over the items in the set, with the items being mutable.
  ## You may attempt to add and remove items during this iteration;
  ## however, additions/removals will not take effect until the next iteration.

  # Lock the elements
  this.areElementsLocked = true

  # Remove all elements in the removal queue.
  while this.elementsToRemove.len > 0:
    this.removeNow(this.elementsToRemove.popFirst())

  # Add all elements in the addition queue.
  while this.elementsToAdd.len > 0:
    this.elements.add(this.elementsToAdd.popFirst())

  # Yield all elements currently in the set.
  for e in this.elements:
    yield e

  # Finally "unlock" the SafeSet.
  this.areElementsLocked = false

proc len*(this: SafeSet): int =
  ## The number of effective elements in the set.
  max(0, this.elements.len - this.elementsToRemove.len + this.elementsToAdd.len)

