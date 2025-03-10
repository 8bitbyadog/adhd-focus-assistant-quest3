extends Node

const SAVE_FILE_PATH := "user://tasks.json"

signal tasks_loaded
signal save_completed

func save_tasks(tasks: Dictionary) -> void:
    var task_data := {}
    
    # Convert task objects to serializable dictionaries
    for task_id in tasks:
        var task = tasks[task_id]
        task_data[task_id] = {
            "id": task.id,
            "title": task.title,
            "description": task.description,
            "priority": task.priority,
            "completed": task.completed,
            "spatial_position": {
                "x": task.spatial_position.x,
                "y": task.spatial_position.y,
                "z": task.spatial_position.z
            },
            "spatial_rotation": {
                "x": task.spatial_rotation.x,
                "y": task.spatial_rotation.y,
                "z": task.spatial_rotation.z,
                "w": task.spatial_rotation.w
            },
            "creation_time": task.creation_time,
            "completion_time": task.completion_time
        }
    
    # Create JSON string
    var json_string = JSON.stringify(task_data)
    
    # Save to file
    var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
    if file:
        file.store_string(json_string)
        emit_signal("save_completed")
    else:
        push_error("Failed to save tasks to file")

func load_tasks() -> Dictionary:
    var tasks := {}
    
    # Check if save file exists
    if not FileAccess.file_exists(SAVE_FILE_PATH):
        emit_signal("tasks_loaded")
        return tasks
    
    # Load and parse JSON
    var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
    if file:
        var json_string = file.get_as_text()
        var json = JSON.new()
        var parse_result = json.parse(json_string)
        
        if parse_result == OK:
            var task_data = json.get_data()
            
            # Convert dictionaries back to task objects
            for task_id in task_data:
                var data = task_data[task_id]
                var task = TaskSystem.Task.new(
                    data.id,
                    data.title,
                    data.description,
                    data.priority
                )
                
                # Restore additional properties
                task.completed = data.completed
                task.spatial_position = Vector3(
                    data.spatial_position.x,
                    data.spatial_position.y,
                    data.spatial_position.z
                )
                task.spatial_rotation = Quaternion(
                    data.spatial_rotation.x,
                    data.spatial_rotation.y,
                    data.spatial_rotation.z,
                    data.spatial_rotation.w
                )
                task.creation_time = data.creation_time
                task.completion_time = data.completion_time
                
                tasks[task_id] = task
    else:
        push_error("Failed to load tasks from file")
    
    emit_signal("tasks_loaded")
    return tasks

# Auto-save timer
var save_timer: Timer

func _ready() -> void:
    # Set up auto-save timer
    save_timer = Timer.new()
    save_timer.wait_time = 60  # Auto-save every minute
    save_timer.timeout.connect(_on_auto_save_timer_timeout)
    add_child(save_timer)
    save_timer.start()

func _on_auto_save_timer_timeout() -> void:
    # Get reference to TaskSystem and save current tasks
    var task_system = get_node("/root/Main/TaskSystem")
    if task_system:
        save_tasks(task_system.tasks)

# Save on app exit
func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        var task_system = get_node("/root/Main/TaskSystem")
        if task_system:
            save_tasks(task_system.tasks)
        get_tree().quit() 