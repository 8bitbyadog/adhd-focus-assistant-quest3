extends Node

# Haptic feedback patterns
const PATTERNS = {
    "light_tap": {
        "duration": 0.1,
        "frequency": 60.0,
        "amplitude": 0.3
    },
    "menu": {
        "duration": 0.2,
        "frequency": 45.0,
        "amplitude": 0.5
    },
    "error": {
        "duration": 0.3,
        "frequency": 30.0,
        "amplitude": 0.7
    }
}

func trigger_haptic(hand: String, pattern: String) -> void:
    var controller: XRController3D
    if hand == "left":
        controller = get_node("/root/Main/XROrigin3D/LeftController")
    else:
        controller = get_node("/root/Main/XROrigin3D/RightController")
    
    if not controller or not controller.get_is_active():
        return
    
    if pattern in PATTERNS:
        var params = PATTERNS[pattern]
        _trigger_single_haptic(controller, params)

func _trigger_single_haptic(controller: XRController3D, data: Dictionary) -> void:
    controller.trigger_haptic_pulse(
        data["amplitude"],  # Amplitude (0.0 to 1.0)
        data["duration"]    # Duration in seconds
    )

func _trigger_pulse_haptic(controller: XRController3D, data: Dictionary) -> void:
    var pulse_count = data.get("pulses", 1)
    var total_duration = data["duration"] * pulse_count
    var pulse_duration = data["duration"] / pulse_count
    
    for i in range(pulse_count):
        controller.trigger_haptic_pulse(
            data["amplitude"],
            pulse_duration
        )
        if i < pulse_count - 1:
            await get_tree().create_timer(pulse_duration).timeout

func _get_controller(hand: String) -> XRController3D:
    var controller_path = "../XROrigin3D/" + ("LeftController" if hand == "left" else "RightController")
    return get_node_or_null(controller_path) 