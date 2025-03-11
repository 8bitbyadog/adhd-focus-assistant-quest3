extends Node

const SAVE_FILE_PATH := "user://tasks.json"

signal tasks_loaded
signal save_completed

var cached_tasks: Dictionary = {}

func get_tasks() -> Dictionary:
    return cached_tasks

func save_tasks(tasks: Dictionary) -> void:
    cached_tasks = tasks
    var task_data := {}
    
    # Convert task objects to serializable dictionaries
    for task_id in tasks:
        var task = tasks[task_id]
        task_data[task_id] = task.to_dict()
    
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
        cached_tasks = tasks
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
                var task = Task.from_dict(data)
                tasks[task_id] = task
    else:
        push_error("Failed to load tasks from file")
    
    cached_tasks = tasks
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
    
    # Load tasks on startup
    load_tasks()

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