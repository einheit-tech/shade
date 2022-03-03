import locks

type NRLock* = object
  ## Non-reentrant lock.
  lock: Lock
  hasBeenAcquired: bool

proc initNRLock*(this: var NRLock) {.inline.} =
  ## Initializes the given lock.
  initLock(this.lock)
  this.hasBeenAcquired = false

proc deinitNRLock*(this: var NRLock) {.inline.} =
  ## Frees the resources associated with the lock.
  deinitLock(this.lock)
  this.hasBeenAcquired = false

proc tryAcquire*(this: var NRLock): bool {.inline.} =
  ## Tries to acquire the given lock. Returns `true` on success.
  if not tryAcquire(this.lock):
    return false
  elif this.hasBeenAcquired:
    this.lock.release()
    return false
  
  this.hasBeenAcquired = true
  return true

template withNRLock*(this: var NRLock, body: untyped) =
  if tryAcquire(this):
    try:
      body
    finally:
      this.hasBeenAcquired = false
      this.lock.release()

proc `$`*(this: NRLock): string =
  return $this.lock

