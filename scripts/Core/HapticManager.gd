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
        controller.trigger_haptic_pulse(
            params["frequency"],
            params["amplitude"],
            params["duration"],
            0.0,  # Start delay
            0.0   # Duration scale
        ) 