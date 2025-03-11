extends Node3D

var task_system: Node
var ui_manager: Node
var task_filter: Node
var task_card_scene: PackedScene
var task_creation_scene: PackedScene
var task_filter_scene: PackedScene
var active_tasks: Dictionary = {}
var creation_panel: Node3D = null
var filter_panel: Node3D = null

@onready var task_storage = $"../TaskStorage"
@onready var task_sorter = $"../TaskSorter"

var tasks: Dictionary = {}
var filtered_tasks: Array = []

func _ready() -> void:
	task_system = get_node("/root/Main/TaskSystem")
	ui_manager = get_node("/root/Main/UIManager")
	task_filter = get_node("/root/Main/TaskFilter")
	
	# Load scenes
	task_card_scene = preload("res://scenes/Tasks/TaskCard.tscn")
	task_creation_scene = preload("res://scenes/UI/TaskCreationPanel.tscn")
	task_filter_scene = preload("res://scenes/UI/TaskFilterPanel.tscn")
	
	# Connect to signals
	task_system.connect("task_added", _on_task_added)
	task_system.connect("task_updated", _on_task_updated)
	task_system.connect("task_removed", _on_task_removed)
	task_system.connect("task_completed", _on_task_completed)
	task_filter.connect("filters_changed", _on_filters_changed)
	task_sorter.connect("sort_changed", _on_sort_changed)

	tasks = task_storage.get_tasks()
	_apply_filters_and_sort()

func show_creation_panel() -> void:
	if creation_panel != null:
		return
		
	# Create the panel through UI manager
	var creation_ui = task_creation_scene.instantiate()
	creation_panel = ui_manager.create_panel("TaskCreationPanel", creation_ui)
	
	# Position the panel in a comfortable viewing position
	var camera = get_viewport().get_camera_3d()
	if camera:
		var offset = Vector3(0, 0, -0.75)  # 75cm in front
		var position = camera.global_position + camera.global_transform.basis * offset
		creation_panel.global_position = position
		creation_panel.look_at(camera.global_position)
		creation_panel.rotate_object_local(Vector3.UP, PI)
	
	# Connect to the creation signal
	creation_ui.connect("task_created", _on_creation_panel_task_created)

func show_filter_panel() -> void:
	if filter_panel != null:
		return
		
	# Create the panel through UI manager
	var filter_ui = task_filter_scene.instantiate()
	filter_panel = ui_manager.create_panel("TaskFilterPanel", filter_ui)
	
	# Position the panel to the left of the user
	var camera = get_viewport().get_camera_3d()
	if camera:
		var offset = Vector3(-0.5, 0, -0.5)  # 50cm left, 50cm forward
		var position = camera.global_position + camera.global_transform.basis * offset
		filter_panel.global_position = position
		filter_panel.look_at(camera.global_position)
		filter_panel.rotate_object_local(Vector3.UP, PI)

func hide_creation_panel() -> void:
	if creation_panel:
		ui_manager.remove_panel("TaskCreationPanel")
		creation_panel = null

func hide_filter_panel() -> void:
	if filter_panel:
		ui_manager.remove_panel("TaskFilterPanel")
		filter_panel = null

func _on_creation_panel_task_created() -> void:
	# Hide the panel after creating a task
	hide_creation_panel()

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
		
		# Apply current filters
		_update_card_visibility(task_id)

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
		_update_card_visibility(task_id)

func _on_task_removed(task_id: String) -> void:
	if task_id in active_tasks:
		active_tasks[task_id].queue_free()
		active_tasks.erase(task_id)

func _on_task_completed(task_id: String) -> void:
	if task_id in active_tasks:
		var task_card = active_tasks[task_id]
		var card_ui = task_card.get_node("SubViewport/CardContent")
		card_ui.play_completion_effect()
		_update_card_visibility(task_id)

func _on_filters_changed() -> void:
	_apply_filters_and_sort()

func _on_sort_changed() -> void:
	_apply_filters_and_sort()

func _apply_filters_and_sort():
	# First apply filters
	filtered_tasks = task_filter.apply_filters(tasks)
	# Then sort the filtered tasks
	filtered_tasks = task_sorter.sort_tasks(filtered_tasks)
	# Update task system with filtered and sorted tasks
	task_system.update_task_displays(filtered_tasks)

func _update_card_visibility(task_id: String) -> void:
	var task = task_system.get_task(task_id)
	if task and task_id in active_tasks:
		var task_array = [task]
		var should_show = task_filter.apply_filters(task_array).size() > 0
		active_tasks[task_id].visible = should_show

# Helper function to create a test task
func create_test_task() -> void:
	create_task(
		"Test Task",
		"This is a test task to verify the task card system.",
		"medium"
	) 