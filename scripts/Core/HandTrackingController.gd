extends Node3D

signal hand_tracking_started
signal hand_tracking_stopped
signal gesture_detected(hand: String, gesture: String)

# Hand tracking constants
const PINCH_THRESHOLD := 0.8
const GRAB_THRESHOLD := 0.7
const MENU_GESTURE_TIME := 1.0  # Hold pinch for 1 second to open menu
const FILTER_GESTURE_TIME := 0.8  # Hold pinch for 0.8 seconds to open filter

# Hand states
var left_hand_active := false
var right_hand_active := false
var left_pinch_strength := 0.0
var right_pinch_strength := 0.0

# Menu gesture tracking
var menu_gesture_timer := 0.0
var filter_gesture_timer := 0.0
var is_menu_gesture_active := false
var is_filter_gesture_active := false
var task_manager: Node
var haptic_manager: Node
var gesture_feedback_scene: PackedScene
var left_feedback: Node3D
var right_feedback: Node3D

# XR interface reference
var xr_interface: XRInterface

func _ready() -> void:
    xr_interface = XRServer.find_interface("OpenXR")
    if xr_interface and xr_interface.is_initialized():
        _initialize_hand_tracking()
    
    # Get references
    task_manager = get_node("/root/Main/TaskManager")
    haptic_manager = get_node("/root/Main/HapticManager")
    
    # Load gesture feedback scene
    gesture_feedback_scene = preload("res://scenes/UI/GestureFeedback.tscn")
    
    # Create feedback instances for both hands
    left_feedback = gesture_feedback_scene.instantiate()
    right_feedback = gesture_feedback_scene.instantiate()
    add_child(left_feedback)
    add_child(right_feedback)
    
    # Initially hide feedback
    left_feedback.hide()
    right_feedback.hide()

func _initialize_hand_tracking() -> void:
    if xr_interface.is_hand_tracking_supported():
        var result = xr_interface.start_hand_tracking()
        if result == OK:
            print("Hand tracking started successfully")
            emit_signal("hand_tracking_started")
        else:
            print("Failed to start hand tracking")
    else:
        print("Hand tracking not supported on this device")

func _process(delta: float) -> void:
    if not xr_interface or not xr_interface.is_initialized():
        return
        
    _update_hand_states()
    _check_gestures()
    _check_menu_gesture(delta)
    _check_filter_gesture(delta)

func _update_hand_states() -> void:
    # Update left hand
    left_hand_active = xr_interface.is_hand_tracked(XRInterface.HAND_LEFT)
    if left_hand_active:
        left_pinch_strength = xr_interface.get_hand_pinch_strength(XRInterface.HAND_LEFT)
    
    # Update right hand
    right_hand_active = xr_interface.is_hand_tracked(XRInterface.HAND_RIGHT)
    if right_hand_active:
        right_pinch_strength = xr_interface.get_hand_pinch_strength(XRInterface.HAND_RIGHT)

func _check_gestures() -> void:
    # Check left hand gestures
    if left_hand_active:
        if left_pinch_strength >= PINCH_THRESHOLD:
            emit_signal("gesture_detected", "left", "pinch")
            haptic_manager.trigger_haptic("left", "light_tap")
        if left_pinch_strength >= GRAB_THRESHOLD:
            emit_signal("gesture_detected", "left", "grab")
    
    # Check right hand gestures
    if right_hand_active:
        if right_pinch_strength >= PINCH_THRESHOLD:
            emit_signal("gesture_detected", "right", "pinch")
            haptic_manager.trigger_haptic("right", "light_tap")
        if right_pinch_strength >= GRAB_THRESHOLD:
            emit_signal("gesture_detected", "right", "grab")

func _check_menu_gesture(delta: float) -> void:
    # Check for menu gesture (pinch and hold with both hands)
    if left_hand_active and right_hand_active:
        if left_pinch_strength >= PINCH_THRESHOLD and right_pinch_strength >= PINCH_THRESHOLD:
            if not is_menu_gesture_active:
                menu_gesture_timer += delta
                if menu_gesture_timer >= MENU_GESTURE_TIME:
                    _trigger_menu_gesture()
        else:
            menu_gesture_timer = 0.0
            is_menu_gesture_active = false
    else:
        menu_gesture_timer = 0.0
        is_menu_gesture_active = false

func _check_filter_gesture(delta: float) -> void:
    # Check for filter gesture (left hand pinch and hold)
    if left_hand_active and not right_hand_active:
        if left_pinch_strength >= PINCH_THRESHOLD:
            if not is_filter_gesture_active:
                filter_gesture_timer += delta
                if filter_gesture_timer >= FILTER_GESTURE_TIME:
                    _trigger_filter_gesture()
        else:
            filter_gesture_timer = 0.0
            is_filter_gesture_active = false
    else:
        filter_gesture_timer = 0.0
        is_filter_gesture_active = false

func _trigger_menu_gesture() -> void:
    if not is_menu_gesture_active:
        is_menu_gesture_active = true
        task_manager.show_creation_panel()
        emit_signal("gesture_detected", "both", "menu")
        
        # Trigger haptic feedback on both hands
        haptic_manager.trigger_haptic("left", "menu")
        haptic_manager.trigger_haptic("right", "menu")

func _trigger_filter_gesture() -> void:
    if not is_filter_gesture_active:
        is_filter_gesture_active = true
        task_manager.show_filter_panel()
        emit_signal("gesture_detected", "left", "filter")
        
        # Trigger haptic feedback
        haptic_manager.trigger_haptic("left", "menu")

func get_hand_transform(hand: String) -> Transform3D:
    var hand_index = XRInterface.HAND_LEFT if hand == "left" else XRInterface.HAND_RIGHT
    if xr_interface and xr_interface.is_initialized():
        return xr_interface.get_hand_transform(hand_index)
    return Transform3D()

func is_hand_active(hand: String) -> bool:
    return left_hand_active if hand == "left" else right_hand_active

func get_pinch_strength(hand: String) -> float:
    return left_pinch_strength if hand == "left" else right_pinch_strength

func _process(_delta: float) -> void:
    var left_controller = get_node("/root/Main/XROrigin3D/LeftController")
    var right_controller = get_node("/root/Main/XROrigin3D/RightController")
    
    if left_controller and left_controller.get_is_active():
        left_pinch_strength = left_controller.get_float("pinch_strength")
        _update_hand_feedback(left_controller, left_feedback, left_pinch_strength)
        
        if left_pinch_strength >= PINCH_THRESHOLD:
            task_manager.show_filter_panel()
    else:
        left_pinch_strength = 0.0
        left_feedback.hide()
    
    if right_controller and right_controller.get_is_active():
        right_pinch_strength = right_controller.get_float("pinch_strength")
        _update_hand_feedback(right_controller, right_feedback, right_pinch_strength)
        
        if right_pinch_strength >= PINCH_THRESHOLD:
            task_manager.show_creation_panel()
    else:
        right_pinch_strength = 0.0
        right_feedback.hide()

func _update_hand_feedback(controller: XRController3D, feedback: Node3D, pinch_strength: float) -> void:
    if pinch_strength > 0:
        # Get hand position and rotation
        var hand_position = controller.global_position
        var hand_rotation = controller.global_transform.basis
        
        # Update feedback
        feedback.position_at_hand(hand_position, hand_rotation)
        feedback.update_progress(pinch_strength) 