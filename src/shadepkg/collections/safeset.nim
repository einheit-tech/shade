import
  tables,
  sets

type
  SafeSet*[T] = ref object
    elements: OrderedSet[T]
    iterationDepth: int
    pendingElements: OrderedTable[T, bool]

proc newSafeSet*[T](): SafeSet[T] =
  SafeSet[T]()

proc areElementsLocked*[T](this: SafeSet[T]): bool =
  this.iterationDepth > 0

template addNow[T](this: SafeSet[T], t: T) =
  this.elements.incl(t)

template removeNow[T](this: SafeSet[T], t: T) =
  ## Unsafe immediate removal of elements.
  this.elements.excl(t)

proc add*[T](this: SafeSet[T], t: T) =
  ## Adds an item to the set.
  if this.areElementsLocked():
    this.pendingElements[t] = true
  else:
    this.addNow(t)

proc remove*[T](this: SafeSet[T], t: T) =
  ## Removes an item from the set.
  if this.areElementsLocked():
    this.pendingElements[t] = false
  else:
    this.removeNow(t)

iterator items*[T](this: SafeSet[T]): T =
  ## Safely iterates over the items in the set.
  ## You may attempt to add and remove items during this iteration;
  ## however, additions/removals will not take effect until the iteration completes.
  try:
    # Lock the elements
    this.iterationDepth += 1
    # Yield all elements currently in the set.
    for e in this.elements.items:
      yield e
  finally:
    # Finally "unlock" the SafeSet.
    this.iterationDepth -= 1

    # Process and clear pending elements.
    if not this.areElementsLocked():
      for element, adding in this.pendingElements.pairs():
        if adding:
          this.addNow(element)
        else:
          this.removeNow(element)
      this.pendingElements.clear()

proc len*(this: SafeSet): int =
  ## The number of effective elements in the set.
  result = this.elements.len

  if this.areElementsLocked():
    for element, adding in this.pendingElements.pairs():
      let isInElements = this.elements.contains(element)
      if adding:
        if not isInElements:
          result += 1
      elif isInElements:
        result -= 1

