import
  tables,
  sets

type
  SafeSet*[T] = ref object
    elements: OrderedSet[T]
    iterationDepth: int
    pendingElements: CountTable[T]

proc newSafeSet*[T](): SafeSet[T] =
  SafeSet[T]()

proc areElementsLocked*[T](this: SafeSet[T]): bool =
  this.iterationDepth > 0

template addNow*[T](this: SafeSet[T], t: T) =
  this.elements.incl(t)

template removeNow[T](this: SafeSet[T], t: T) =
  ## Unsafe immediate removal of elements.
  this.elements.excl(t)

proc add*[T](this: SafeSet[T], t: T) =
  ## Adds an item to the set.
  if this.areElementsLocked():
    this.pendingElements.inc(t)
  else:
    this.addNow(t)

proc remove*[T](this: SafeSet[T], t: T) =
  ## Removes an item from the set.
  if this.areElementsLocked():
    this.pendingElements.inc(t, -1)
  else:
    this.removeNow(t)

iterator items*[T](this: SafeSet[T]): T =
  ## Safely iterates over the items in the set.
  ## You may attempt to add and remove items during this iteration;
  ## however, additions/removals will not take effect until the next iteration.

  if not this.areElementsLocked():
    # Process and clear pending elements.
    for element, counter in this.pendingElements.pairs():
      if counter > 0:
        this.addNow(element)
      elif counter < 0:
        this.removeNow(element)
    this.pendingElements.clear()

  # Lock the elements
  this.iterationDepth += 1
  # Yield all elements currently in the set.
  for e in this.elements.items:
    yield e
  # Finally "unlock" the SafeSet.
  this.iterationDepth -= 1

proc len*(this: SafeSet): int =
  ## The number of effective elements in the set.
  result = this.elements.len
  for counter in this.pendingElements.values():
    result += counter

