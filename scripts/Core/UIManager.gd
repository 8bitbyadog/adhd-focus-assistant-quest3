extends Node3D

# UI Constants
const MIN_SCALE := Vector3(0.3, 0.3, 0.3)
const MAX_SCALE := Vector3(1.0, 1.0, 1.0)
const MIN_DISTANCE := 0.3  # 30cm
const MAX_DISTANCE := 1.0  # 1m
const FOLLOW_SPEED := 5.0
const ROTATION_SPEED := 3.0

# UI Panel references
var panels: Dictionary = {}
var active_panel: Node3D = null
var camera: XRCamera3D = null

# Signals
signal panel_created(panel_name: String)
signal panel_selected(panel_name: String)
signal panel_deselected(panel_name: String)

func _ready() -> void:
    # Find XR Camera
    await get_tree().create_timer(0.5).timeout  # Wait for scene setup
    camera = get_viewport().get_camera_3d()
    if not camera:
        print("ERROR: XRCamera3D not found")

func create_panel(panel_name: String, content: Control) -> Node3D:
    # Create panel container
    var panel = Node3D.new()
    panel.name = panel_name
    
    # Create viewport for UI content
    var viewport = SubViewport.new()
    viewport.transparent_bg = true
    viewport.size = Vector2(512, 512)
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    
    # Add content to viewport
    viewport.add_child(content)
    
    # Create mesh for panel
    var mesh_instance = MeshInstance3D.new()
    var quad_mesh = QuadMesh.new()
    quad_mesh.size = Vector2(0.5, 0.5)  # 50cm x 50cm
    mesh_instance.mesh = quad_mesh
    
    # Create material
    var material = StandardMaterial3D.new()
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.albedo_color = Color(1, 1, 1, 0.8)
    material.flags_transparent = true
    material.flags_unshaded = true
    material.flags_no_depth_test = true
    
    # Set viewport texture
    material.albedo_texture = viewport.get_texture()
    mesh_instance.material_override = material
    
    # Add components to panel
    panel.add_child(viewport)
    panel.add_child(mesh_instance)
    
    # Add to scene and store reference
    add_child(panel)
    panels[panel_name] = panel
    
    # Position panel in front of camera
    _position_panel_in_view(panel)
    
    emit_signal("panel_created", panel_name)
    return panel

func _position_panel_in_view(panel: Node3D) -> void:
    if not camera:
        return
    
    var camera_forward = -camera.global_transform.basis.z
    var position = camera.global_position + camera_forward * 0.75  # 75cm in front
    panel.global_position = position
    
    # Make panel face camera
    panel.look_at(camera.global_position)
    panel.rotate_object_local(Vector3.UP, PI)

func _process(delta: float) -> void:
    if not camera:
        return
    
    for panel in panels.values():
        _update_panel_scale(panel)
        if panel == active_panel:
            _update_active_panel_position(panel, delta)

func _update_panel_scale(panel: Node3D) -> void:
    var distance = panel.global_position.distance_to(camera.global_position)
    var scale_factor = clamp(
        inverse_lerp(MAX_DISTANCE, MIN_DISTANCE, distance),
        0.0,
        1.0
    )
    panel.scale = MIN_SCALE.lerp(MAX_SCALE, scale_factor)

func _update_active_panel_position(panel: Node3D, delta: float) -> void:
    var target_pos = camera.global_position + (-camera.global_transform.basis.z * 0.75)
    panel.global_position = panel.global_position.lerp(target_pos, delta * FOLLOW_SPEED)
    
    var target_rot = Quaternion(camera.global_transform.basis)
    target_rot = target_rot * Quaternion(Vector3.UP, PI)
    panel.quaternion = panel.quaternion.slerp(target_rot, delta * ROTATION_SPEED)

func set_active_panel(panel_name: String) -> void:
    if panel_name in panels:
        if active_panel:
            emit_signal("panel_deselected", active_panel.name)
        active_panel = panels[panel_name]
        emit_signal("panel_selected", panel_name)

func clear_active_panel() -> void:
    if active_panel:
        emit_signal("panel_deselected", active_panel.name)
        active_panel = null

func remove_panel(panel_name: String) -> void:
    if panel_name in panels:
        if panels[panel_name] == active_panel:
            clear_active_panel()
        panels[panel_name].queue_free()
        panels.erase(panel_name) 