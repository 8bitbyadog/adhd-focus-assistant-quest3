extends Control

signal task_created

@onready var title_input = $MarginContainer/VBoxContainer/TitleInput
@onready var description_input = $MarginContainer/VBoxContainer/DescriptionInput
@onready var priority_option = $MarginContainer/VBoxContainer/PriorityOption
@onready var create_button = $MarginContainer/VBoxContainer/CreateButton
@onready var error_label = $MarginContainer/VBoxContainer/ErrorLabel

var task_manager: Node

func _ready() -> void:
    task_manager = get_node("/root/Main/TaskManager")
    create_button.pressed.connect(_on_create_pressed)
    error_label.hide()
    
    # Set up priority options
    priority_option.add_item("High")
    priority_option.add_item("Medium")
    priority_option.add_item("Low")
    priority_option.selected = 1  # Default to Medium

func _on_create_pressed() -> void:
    var title = title_input.text.strip_edges()
    if title.is_empty():
        _show_error("Title is required")
        return
    
    var description = description_input.text.strip_edges()
    var priority = priority_option.get_item_text(priority_option.selected).to_lower()
    
    # Create the task
    task_manager.create_task(title, description, priority)
    
    # Clear the form
    _clear_form()
    
    # Emit signal
    emit_signal("task_created")

func _show_error(message: String) -> void:
    error_label.text = message
    error_label.show()
    
    # Hide error after 3 seconds
    await get_tree().create_timer(3.0).timeout
    error_label.hide()

func _clear_form() -> void:
    title_input.text = ""
    description_input.text = ""
    priority_option.selected = 1
    error_label.hide() 