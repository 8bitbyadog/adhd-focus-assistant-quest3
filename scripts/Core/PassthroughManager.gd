extends Node3D

# Signal for passthrough state changes
signal passthrough_toggled(enabled: bool)

# References to XR nodes
var xr_interface: XRInterface
var is_passthrough_enabled: bool = false

func _ready() -> void:
    # Initialize XR interface
    xr_interface = XRServer.find_interface("OpenXR")
    if xr_interface and xr_interface.is_initialized():
        print("OpenXR initialized successfully")
        
        # Initialize passthrough
        _initialize_passthrough()
    else:
        print("OpenXR not initialized")

func _initialize_passthrough() -> void:
    if not xr_interface.is_passthrough_supported():
        print("Passthrough not supported on this device")
        return
    
    var result = xr_interface.start_passthrough()
    if result == OK:
        is_passthrough_enabled = true
        print("Passthrough started successfully")
    else:
        is_passthrough_enabled = false
        print("Failed to start passthrough")
    
    # Emit initial state
    emit_signal("passthrough_toggled", is_passthrough_enabled)

func toggle_passthrough() -> void:
    if not xr_interface or not xr_interface.is_initialized():
        return
        
    if is_passthrough_enabled:
        xr_interface.stop_passthrough()
        is_passthrough_enabled = false
    else:
        var result = xr_interface.start_passthrough()
        is_passthrough_enabled = (result == OK)
    
    emit_signal("passthrough_toggled", is_passthrough_enabled)

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("toggle_passthrough"):
        toggle_passthrough() 