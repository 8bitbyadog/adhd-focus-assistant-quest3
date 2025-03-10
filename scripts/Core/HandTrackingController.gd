extends Node3D

signal hand_tracking_started
signal hand_tracking_stopped
signal gesture_detected(hand: String, gesture: String)

# Hand tracking constants
const PINCH_THRESHOLD := 0.5
const GRAB_THRESHOLD := 0.7

# Hand states
var left_hand_active := false
var right_hand_active := false
var left_pinch_strength := 0.0
var right_pinch_strength := 0.0

# XR interface reference
var xr_interface: XRInterface

func _ready() -> void:
    xr_interface = XRServer.find_interface("OpenXR")
    if xr_interface and xr_interface.is_initialized():
        _initialize_hand_tracking()

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

func _process(_delta: float) -> void:
    if not xr_interface or not xr_interface.is_initialized():
        return
        
    _update_hand_states()
    _check_gestures()

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
        if left_pinch_strength >= GRAB_THRESHOLD:
            emit_signal("gesture_detected", "left", "grab")
    
    # Check right hand gestures
    if right_hand_active:
        if right_pinch_strength >= PINCH_THRESHOLD:
            emit_signal("gesture_detected", "right", "pinch")
        if right_pinch_strength >= GRAB_THRESHOLD:
            emit_signal("gesture_detected", "right", "grab")

func get_hand_transform(hand: String) -> Transform3D:
    var hand_index = XRInterface.HAND_LEFT if hand == "left" else XRInterface.HAND_RIGHT
    if xr_interface and xr_interface.is_initialized():
        return xr_interface.get_hand_transform(hand_index)
    return Transform3D()

func is_hand_active(hand: String) -> bool:
    return left_hand_active if hand == "left" else right_hand_active

func get_pinch_strength(hand: String) -> float:
    return left_pinch_strength if hand == "left" else right_pinch_strength 