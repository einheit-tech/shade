import task
export task

type Tween* = ref object of Task
  duration*: float
  interpolate: proc(this: Tween, deltaTime: float)

proc initTween*(
  tween: Tween,
  duration: float,
  interpolate: proc(this: Tween, deltaTime: float),
  onCompletion: proc(this: Tween)
) =
  initTask(
    tween,
    # TODO: Is there a better way to do this?
    proc(this: Task, deltaTime: float) = interpolate(tween, deltaTime),
    proc(this: Task): bool = tween.elapsedTime >= tween.duration,
    proc(this: Task) = onCompletion(tween)
  )
  tween.duration = duration

proc newTween*(
  duration: float,
  interpolate: proc(this: Tween, deltaTime: float),
  onCompletion: proc(this: Tween)
): Tween =
  result = Tween()
  initTween(result, duration, interpolate, onCompletion)

when isMainModule:
  var i = 0
  let tween: Tween = newTween(
    2.5,
    (proc(this: Tween, deltaTime: float) = echo $i; i.inc),
    proc(this: Tween) = echo "done!"
  )

  while not tween.completed:
    tween.update(0.5)

