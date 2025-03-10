extends Control

signal complete_pressed(task_id: String)

@onready var title_label = $MarginContainer/VBoxContainer/Title
@onready var description_label = $MarginContainer/VBoxContainer/Description
@onready var priority_label = $MarginContainer/VBoxContainer/Footer/Priority
@onready var complete_button = $MarginContainer/VBoxContainer/Footer/CompleteButton
@onready var background = $Background

var task_id: String
var task_system: Node

func _ready() -> void:
    task_system = get_node("/root/Main/TaskSystem")
    complete_button.pressed.connect(_on_complete_pressed)

func update_from_task_data(task_data: TaskSystem.Task) -> void:
    task_id = task_data.id
    title_label.text = task_data.title
    description_label.text = task_data.description
    priority_label.text = "Priority: " + task_data.priority.capitalize()
    
    # Update visual style based on priority
    var priority_color = task_system.PRIORITY_COLORS[task_data.priority]
    background.color = priority_color
    
    # Update completion state
    complete_button.disabled = task_data.completed
    if task_data.completed:
        complete_button.text = "Completed"
        modulate = Color(1, 1, 1, 0.5)
    else:
        complete_button.text = "Complete"
        modulate = Color(1, 1, 1, 1)

func _on_complete_pressed() -> void:
    emit_signal("complete_pressed", task_id)
    task_system.complete_task(task_id)

# Particle effect for task completion
func play_completion_effect() -> void:
    var particles = CPUParticles3D.new()
    particles.emitting = true
    particles.one_shot = true
    particles.explosiveness = 1.0
    particles.lifetime = 2.0
    particles.amount = 50
    particles.mesh = SphereMesh.new()
    particles.mesh.radius = 0.01
    particles.mesh.height = 0.01
    particles.direction = Vector3.UP
    particles.spread = 180.0
    particles.gravity = Vector3(0, -1, 0)
    particles.initial_velocity_min = 0.5
    particles.initial_velocity_max = 1.0
    
    # Add particles to the 3D parent
    get_parent().get_parent().add_child(particles)
    
    # Remove particles after animation
    await get_tree().create_timer(2.0).timeout
    particles.queue_free() 