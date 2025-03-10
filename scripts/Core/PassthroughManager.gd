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
        if xr_interface.is_passthrough_supported():
            _initialize_passthrough()
        else:
            print("Passthrough not supported on this device")
    else:
        print("OpenXR not initialized")

func _initialize_passthrough() -> void:
    # Start passthrough
    var passthrough_result = xr_interface.start_passthrough()
    is_passthrough_enabled = passthrough_result == OK
    if is_passthrough_enabled:
        print("Passthrough started successfully")
    else:
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
        is_passthrough_enabled = xr_interface.start_passthrough() == OK
    
    emit_signal("passthrough_toggled", is_passthrough_enabled)

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("toggle_passthrough"):
        toggle_passthrough() 