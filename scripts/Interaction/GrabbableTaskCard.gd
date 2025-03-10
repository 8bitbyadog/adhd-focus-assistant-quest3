extends Node3D

signal grabbed(task_id: String)
signal released(task_id: String)
signal completed(task_id: String)

var task_id: String
var is_grabbed: bool = false
var grab_offset: Vector3
var initial_position: Vector3
var initial_rotation: Quaternion
var task_system: Node
var haptic_manager: Node

func _ready() -> void:
    task_system = get_node("/root/Main/TaskSystem")
    haptic_manager = get_node("/root/Main/HapticManager")
    initial_position = global_position
    initial_rotation = global_transform.basis.get_rotation_quaternion()

func _process(_delta: float) -> void:
    if is_grabbed:
        _update_grabbed_position()

func grab(hand: String, hand_transform: Transform3D) -> void:
    if not is_grabbed:
        is_grabbed = true
        grab_offset = global_position - hand_transform.origin
        emit_signal("grabbed", task_id)
        haptic_manager.trigger_haptic(hand, "light_tap")

func release() -> void:
    if is_grabbed:
        is_grabbed = false
        emit_signal("released", task_id)
        _save_position()

func complete() -> void:
    var task = task_system.get_task(task_id)
    if task and not task.completed:
        task_system.complete_task(task_id)
        emit_signal("completed", task_id)

func reset_position() -> void:
    global_position = initial_position
    global_transform.basis = Basis(initial_rotation)
    _save_position()

func _update_grabbed_position() -> void:
    if is_grabbed:
        var hand_transform = _get_grabbing_hand_transform()
        if hand_transform:
            global_position = hand_transform.origin + grab_offset

func _save_position() -> void:
    task_system.update_task_position(
        task_id,
        global_position,
        global_transform.basis.get_rotation_quaternion()
    )

func _get_grabbing_hand_transform() -> Transform3D:
    var hand_tracking = get_node("/root/Main/HandTrackingController")
    if hand_tracking:
        if hand_tracking.get_pinch_strength("left") >= hand_tracking.GRAB_THRESHOLD:
            return hand_tracking.get_hand_transform("left")
        elif hand_tracking.get_pinch_strength("right") >= hand_tracking.GRAB_THRESHOLD:
            return hand_tracking.get_hand_transform("right")
    return Transform3D()

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