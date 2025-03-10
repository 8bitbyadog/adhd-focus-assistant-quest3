extends Node3D

var task_system: Node
var ui_manager: Node
var task_card_scene: PackedScene
var active_tasks: Dictionary = {}

func _ready() -> void:
    task_system = get_node("/root/Main/TaskSystem")
    ui_manager = get_node("/root/Main/UIManager")
    
    # Load the task card scene
    task_card_scene = preload("res://scenes/Tasks/TaskCard.tscn")
    
    # Connect to task system signals
    task_system.connect("task_added", _on_task_added)
    task_system.connect("task_updated", _on_task_updated)
    task_system.connect("task_removed", _on_task_removed)
    task_system.connect("task_completed", _on_task_completed)

func create_task(title: String, description: String = "", priority: String = "medium") -> void:
    var task_id = task_system.create_task(title, description, priority)
    _create_task_card(task_id)

func _create_task_card(task_id: String) -> void:
    var task_data = task_system.get_task(task_id)
    if task_data:
        # Instance the task card scene
        var task_card = task_card_scene.instantiate()
        add_child(task_card)
        
        # Set up the card
        task_card.name = "TaskCard_" + task_id
        task_card.task_id = task_id
        
        # Get the UI control node
        var card_ui = task_card.get_node("SubViewport/CardContent")
        card_ui.update_from_task_data(task_data)
        
        # Store reference
        active_tasks[task_id] = task_card
        
        # Position the card in view
        _position_new_task_card(task_card)

func _position_new_task_card(task_card: Node3D) -> void:
    var camera = get_viewport().get_camera_3d()
    if camera:
        # Position slightly to the right and in front of the camera
        var offset = Vector3(0.3, 0, -0.75)  # 30cm right, 75cm forward
        var position = camera.global_position + camera.global_transform.basis * offset
        task_card.global_position = position
        
        # Make card face the camera
        task_card.look_at(camera.global_position)
        task_card.rotate_object_local(Vector3.UP, PI)

func _on_task_added(task_id: String) -> void:
    if not task_id in active_tasks:
        _create_task_card(task_id)

func _on_task_updated(task_id: String) -> void:
    if task_id in active_tasks:
        var task_data = task_system.get_task(task_id)
        var task_card = active_tasks[task_id]
        var card_ui = task_card.get_node("SubViewport/CardContent")
        card_ui.update_from_task_data(task_data)

func _on_task_removed(task_id: String) -> void:
    if task_id in active_tasks:
        active_tasks[task_id].queue_free()
        active_tasks.erase(task_id)

func _on_task_completed(task_id: String) -> void:
    if task_id in active_tasks:
        var task_card = active_tasks[task_id]
        var card_ui = task_card.get_node("SubViewport/CardContent")
        card_ui.play_completion_effect()

# Helper function to create a test task
func create_test_task() -> void:
    create_task(
        "Test Task",
        "This is a test task to verify the task card system.",
        "medium"
    ) 