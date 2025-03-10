extends Node3D

signal grabbed(by_hand: String)
signal released(by_hand: String)
signal selected
signal deselected

@export var task_id: String
@export var grab_distance: float = 0.1
@export var follow_speed: float = 10.0
@export var rotation_speed: float = 5.0

var hand_tracking: Node
var task_system: Node
var ui_manager: Node
var haptic_manager: Node
var is_grabbed: bool = false
var grabbing_hand: String = ""
var initial_grab_offset: Vector3
var initial_grab_rotation: Quaternion

func _ready() -> void:
    hand_tracking = get_node("/root/Main/HandTrackingController")
    task_system = get_node("/root/Main/TaskSystem")
    ui_manager = get_node("/root/Main/UIManager")
    haptic_manager = get_node("/root/Main/HapticManager")
    
    # Connect to hand tracking signals
    hand_tracking.connect("gesture_detected", _on_gesture_detected)

func _process(delta: float) -> void:
    if is_grabbed:
        _update_grabbed_position(delta)

func _on_gesture_detected(hand: String, gesture: String) -> void:
    var hand_transform = hand_tracking.get_hand_transform(hand)
    var distance = global_position.distance_to(hand_transform.origin)
    
    if gesture == "grab" and distance < grab_distance and not is_grabbed:
        _grab(hand, hand_transform)
    elif gesture == "pinch" and is_grabbed and hand == grabbing_hand:
        _release()

func _grab(hand: String, hand_transform: Transform3D) -> void:
    is_grabbed = true
    grabbing_hand = hand
    
    # Calculate offset from hand to card
    initial_grab_offset = global_transform.origin - hand_transform.origin
    initial_grab_rotation = Quaternion(global_transform.basis)
    
    # Trigger haptic feedback
    haptic_manager.trigger_haptic(hand, "grab")
    
    emit_signal("grabbed", hand)
    ui_manager.set_active_panel(name)

func _release() -> void:
    if is_grabbed:
        is_grabbed = false
        var released_hand = grabbing_hand
        
        # Trigger haptic feedback
        haptic_manager.trigger_haptic(released_hand, "release")
        
        grabbing_hand = ""
        
        # Update task position in system
        task_system.update_task_position(
            task_id,
            global_position,
            Quaternion(global_transform.basis)
        )
        
        emit_signal("released", released_hand)
        ui_manager.clear_active_panel()

func _update_grabbed_position(delta: float) -> void:
    var hand_transform = hand_tracking.get_hand_transform(grabbing_hand)
    
    # Update position
    var target_position = hand_transform.origin + initial_grab_offset
    global_position = global_position.lerp(target_position, delta * follow_speed)
    
    # Update rotation
    var target_rotation = Quaternion(hand_transform.basis) * initial_grab_rotation
    global_transform.basis = Basis(
        global_transform.basis.get_rotation_quaternion().slerp(target_rotation, delta * rotation_speed)
    )

func set_task_data(task_data: TaskSystem.Task) -> void:
    task_id = task_data.id
    if task_data.spatial_position != Vector3.ZERO:
        global_position = task_data.spatial_position
    if task_data.spatial_rotation != Quaternion.IDENTITY:
        global_transform.basis = Basis(task_data.spatial_rotation)

func _on_task_updated() -> void:
    var task_data = task_system.get_task(task_id)
    if task_data:
        # Update visual representation based on task data
        # This will be implemented when we create the visual task card scene
        pass 