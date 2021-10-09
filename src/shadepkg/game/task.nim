import node

export node

type Task* = ref object of Node
  onUpdate: proc(deltaTime: float)
  checkCompletionCondition: proc(this: Task): bool
  onCompletion: proc(this: Task)

  completed*: bool
  elapsedTime*: float

proc initTask*(
  task: Task,
  onUpdate: proc(deltaTime: float),
  checkCompletionCondition: proc(this: Task): bool,
  onCompletion: proc(this: Task)
) =
  initNode(Node(task), {loUpdate})
  task.onUpdate = onUpdate
  task.checkCompletionCondition = checkCompletionCondition
  task.onCompletion = onCompletion

proc newTask*(
  onUpdate: proc(deltaTime: float),
  checkCompletionCondition: proc(this: Task): bool,
  onCompletion: proc(this: Task)
): Task =
  result = Task()
  initTask(result, onUpdate, checkCompletionCondition, onCompletion)

# TODO: Need a decent way to autoremove a task?
method update*(this: Task, deltaTime: float) =
  if this.completed:
    raise newException(Exception, "Task has already been completed - cannot update.")

  procCall Node(this).update(deltaTime)

  this.elapsedTime += deltaTime
  this.onUpdate(deltaTime)

  if this.checkCompletionCondition(this):
    this.completed = true
    this.onCompletion(this)

