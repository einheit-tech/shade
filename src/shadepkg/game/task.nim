import node

export node

type Task* = ref object of Node
  checkCompletionCondition: proc(this: Task): bool
  onCompletion: proc(this: Task)

  completed*: bool
  elapsedTime*: float

proc initTask*(
  task: Task,
  onUpdate: proc(this: Task, deltaTime: float),
  checkCompletionCondition: proc(this: Task): bool,
  onCompletion: proc(this: Task)
) =
  initNode(Node(task), UPDATE)
  task.onUpdate = proc(this: Node, deltaTime: float) = onUpdate(task, deltaTime)
  task.checkCompletionCondition = checkCompletionCondition
  task.onCompletion = onCompletion

proc newTask*(
  onUpdate: proc(this: Task, deltaTime: float),
  checkCompletionCondition: proc(this: Task): bool,
  onCompletion: proc(this: Task)
): Task =
  result = Task()
  initTask(result, onUpdate, checkCompletionCondition, onCompletion)

# TODO: Need a decent way to autoremove a task?
method update*(this: Task, deltaTime: float) =
  if this.completed:
    raise newException(Exception, "Task has already been completed - cannot update.")

  this.elapsedTime += deltaTime
  procCall Node(this).update(deltaTime)

  if this.checkCompletionCondition(this):
    this.completed = true
    this.onCompletion(this)

