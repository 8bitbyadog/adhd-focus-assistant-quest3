extends Node

signal task_added(task_id: String)
signal task_updated(task_id: String)
signal task_removed(task_id: String)
signal task_completed(task_id: String)

# Task priority colors from design spec
const PRIORITY_COLORS := {
    "high": Color("ff2d55cc"),  # Red with 80% opacity
    "medium": Color("007affb3"), # Blue with 70% opacity
    "low": Color("5856d699")     # Purple with 60% opacity
}

# Task storage
var tasks: Dictionary = {}
var task_storage: Node

# Task data structure
class Task:
    var id: String
    var title: String
    var description: String
    var priority: String
    var completed: bool
    var spatial_position: Vector3
    var spatial_rotation: Quaternion
    var creation_time: int
    var completion_time: int
    
    func _init(p_id: String, p_title: String, p_description: String = "", p_priority: String = "medium") -> void:
        id = p_id
        title = p_title
        description = p_description
        priority = p_priority
        completed = false
        spatial_position = Vector3.ZERO
        spatial_rotation = Quaternion.IDENTITY
        creation_time = Time.get_unix_time_from_system()
        completion_time = 0

func _ready() -> void:
    task_storage = get_node("/root/Main/TaskStorage")
    _load_saved_tasks()

func _load_saved_tasks() -> void:
    tasks = task_storage.load_tasks()
    # Notify about loaded tasks
    for task_id in tasks:
        emit_signal("task_added", task_id)

func create_task(title: String, description: String = "", priority: String = "medium") -> String:
    var task_id = str(randi())
    var task = Task.new(task_id, title, description, priority)
    tasks[task_id] = task
    emit_signal("task_added", task_id)
    
    # Save after creating new task
    task_storage.save_tasks(tasks)
    return task_id

func update_task(task_id: String, updates: Dictionary) -> void:
    if task_id in tasks:
        var task = tasks[task_id]
        for key in updates:
            if key in task:
                task.set(key, updates[key])
        emit_signal("task_updated", task_id)
        
        # Save after updating task
        task_storage.save_tasks(tasks)

func complete_task(task_id: String) -> void:
    if task_id in tasks:
        var task = tasks[task_id]
        task.completed = true
        task.completion_time = Time.get_unix_time_from_system()
        emit_signal("task_completed", task_id)
        emit_signal("task_updated", task_id)
        
        # Save after completing task
        task_storage.save_tasks(tasks)

func remove_task(task_id: String) -> void:
    if task_id in tasks:
        tasks.erase(task_id)
        emit_signal("task_removed", task_id)
        
        # Save after removing task
        task_storage.save_tasks(tasks)

func get_task(task_id: String) -> Task:
    return tasks.get(task_id)

func get_all_tasks() -> Array:
    return tasks.values()

func update_task_position(task_id: String, position: Vector3, rotation: Quaternion) -> void:
    if task_id in tasks:
        var task = tasks[task_id]
        task.spatial_position = position
        task.spatial_rotation = rotation
        emit_signal("task_updated", task_id)
        
        # Save after updating position
        task_storage.save_tasks(tasks) 