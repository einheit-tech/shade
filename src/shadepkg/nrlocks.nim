import locks

type NRLock* = object
  ## Non-reentrant lock.
  lock: Lock
  hasBeenAcquired: bool

proc initNRLock*(this: var NRLock) {.inline.} =
  ## Initializes the given lock.
  initLock(this.lock)

proc deinitNRLock*(this: var NRLock) {.inline.} =
  ## Frees the resources associated with the lock.
  deinitLock(this.lock)

proc tryAcquire*(this: var NRLock): bool {.inline.} =
  ## Tries to acquire the given lock. Returns `true` on success.
  if not tryAcquire(this.lock):
    return false
  elif this.hasBeenAcquired:
    this.lock.release()
    return false

  return true

proc acquire*(this: var NRLock) {.inline.} =
  ## Acquires the given lock.
  acquire(this.lock)

proc release*(this: var NRLock) {.inline.} =
  ## Releases the given lock.
  release(this.lock)

template withNRLock*(this: var NRLock, code: untyped) =
  withLock(this.lock):
    this.hasBeenAcquired = true
    try:
      code
    finally:
      this.hasBeenAcquired = false

proc `$`*(this: NRLock): string =
  return $this.lock

