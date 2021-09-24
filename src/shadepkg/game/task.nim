import node

export node

type Task* = ref object of Node
  checkCompletionCondition: proc(): bool
  onUpdate: proc(deltaTime: float)
  onCompletion: proc()

  completed*: bool
  elapsedTime*: float

proc initTask*(
  task: Task,
  onUpdate: proc(deltaTime: float),
  checkCompletionCondition: proc(): bool,
  onCompletion: proc()
) =
  task.onUpdate = onUpdate
  task.checkCompletionCondition = checkCompletionCondition
  task.onCompletion = onCompletion

proc newTask*(
  onUpdate: proc(deltaTime: float),
  checkCompletionCondition: proc(): bool,
  onCompletion: proc()
): Task =
  result = Task()
  initTask(result, onUpdate, checkCompletionCondition, onCompletion)

method update*(this: Task, deltaTime: float) =
  if this.completed:
    raise newException(Exception, "Task has already been completed - cannot update.")

  procCall Node(this).update(deltaTime)

  this.elapsedTime += deltaTime
  this.onUpdate(deltaTime)

  if this.checkCompletionCondition():
    this.completed = true
    this.onCompletion()

