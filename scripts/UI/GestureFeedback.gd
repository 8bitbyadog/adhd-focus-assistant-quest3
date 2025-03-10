extends Node3D

# Visual feedback for gesture progress
var feedback_mesh: MeshInstance3D
var feedback_material: StandardMaterial3D
var current_progress: float = 0.0
const PROGRESS_THRESHOLD: float = 0.8  # Progress needed to trigger action

func _ready() -> void:
    # Create visual feedback mesh (ring)
    var ring_mesh = TorusMesh.new()
    ring_mesh.inner_radius = 0.03
    ring_mesh.outer_radius = 0.05
    
    feedback_mesh = MeshInstance3D.new()
    feedback_mesh.mesh = ring_mesh
    add_child(feedback_mesh)
    
    # Create and set up material
    feedback_material = StandardMaterial3D.new()
    feedback_material.albedo_color = Color(0.2, 0.8, 1.0, 0.6)  # Light blue, semi-transparent
    feedback_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    feedback_material.emission_enabled = true
    feedback_material.emission = Color(0.2, 0.8, 1.0)
    feedback_material.emission_energy_multiplier = 0.5
    
    feedback_mesh.material_override = feedback_material
    
    # Initially hide the feedback
    hide()

func update_progress(progress: float) -> void:
    current_progress = progress
    
    # Update visual feedback
    if progress > 0:
        show()
        # Scale the ring based on progress
        var scale_factor = 1.0 + (progress * 0.5)  # Grows up to 1.5x size
        feedback_mesh.scale = Vector3.ONE * scale_factor
        
        # Update color based on progress
        var color_progress = Color(0.2, 0.8, 1.0)  # Start with light blue
        if progress >= PROGRESS_THRESHOLD:
            color_progress = Color(0.2, 1.0, 0.4)  # Change to green when near completion
        
        feedback_material.albedo_color = color_progress
        feedback_material.albedo_color.a = 0.6
        feedback_material.emission = color_progress
    else:
        hide()

func position_at_hand(hand_position: Vector3, hand_rotation: Basis) -> void:
    global_position = hand_position
    global_transform.basis = hand_rotation
    # Rotate to face upward
    rotate_object_local(Vector3.RIGHT, PI/2) 