extends Node3D

# Signal for passthrough state changes
signal passthrough_toggled(enabled: bool)

# References to XR nodes
var xr_interface: XRInterface
var is_passthrough_enabled: bool = false
var initialization_attempts: int = 0
const MAX_INITIALIZATION_ATTEMPTS: int = 10

func _ready() -> void:
    # Initialize XR interface
    xr_interface = XRServer.find_interface("OpenXR")
    if xr_interface:
        print("OpenXR interface found")
        
        # Initialize XR
        if not xr_interface.is_initialized():
            print("Initializing OpenXR...")
            var init_result = xr_interface.initialize()
            if init_result:
                print("OpenXR initialized successfully")
            else:
                print("Failed to initialize OpenXR")
                return
        
        # Start XR mode
        get_viewport().use_xr = true
        
        # Start passthrough
        if xr_interface.is_passthrough_supported():
            print("Starting passthrough...")
            var result = xr_interface.start_passthrough()
            if result:
                print("Passthrough started successfully")
            else:
                print("Failed to start passthrough")
        else:
            print("Passthrough not supported on this device")
    else:
        print("OpenXR interface not found")

func _try_initialize_xr() -> void:
    if initialization_attempts >= MAX_INITIALIZATION_ATTEMPTS:
        print("Failed to initialize OpenXR after maximum attempts")
        return

    print("Initializing OpenXR (attempt ", initialization_attempts + 1, ")")
    
    # Initialize XR
    if not xr_interface.is_initialized():
        var init_result = xr_interface.initialize()
        if not init_result:
            initialization_attempts += 1
            print("Failed to initialize OpenXR, will retry...")
            # Schedule another attempt in the next frame
            call_deferred("_try_initialize_xr")
            return
    
    print("OpenXR initialized successfully")
    
    # Start XR mode
    if not get_viewport().use_xr:
        print("Starting XR mode...")
        get_viewport().use_xr = true
    
    # Initialize passthrough
    _initialize_passthrough()

func _initialize_passthrough() -> void:
    print("Checking passthrough support...")
    if not xr_interface.is_passthrough_supported():
        print("Passthrough not supported on this device")
        return
    
    print("Starting passthrough...")
    var result = xr_interface.start_passthrough()
    if result:
        is_passthrough_enabled = true
        print("Passthrough started successfully")
    else:
        is_passthrough_enabled = false
        print("Failed to start passthrough")
    
    # Emit initial state
    emit_signal("passthrough_toggled", is_passthrough_enabled)

func toggle_passthrough() -> void:
    if not xr_interface or not xr_interface.is_initialized():
        print("Cannot toggle passthrough - XR not initialized")
        return
        
    if is_passthrough_enabled:
        print("Stopping passthrough...")
        xr_interface.stop_passthrough()
        is_passthrough_enabled = false
    else:
        print("Starting passthrough...")
        var result = xr_interface.start_passthrough()
        is_passthrough_enabled = result
        if is_passthrough_enabled:
            print("Passthrough started successfully")
        else:
            print("Failed to start passthrough")
    
    emit_signal("passthrough_toggled", is_passthrough_enabled)

func _process(_delta: float) -> void:
    # Check XR status every frame during startup
    if not is_passthrough_enabled and initialization_attempts < MAX_INITIALIZATION_ATTEMPTS:
        if xr_interface and not xr_interface.is_initialized():
            _try_initialize_xr()
        elif xr_interface and xr_interface.is_initialized() and not get_viewport().use_xr:
            print("XR mode not active, enabling...")
            get_viewport().use_xr = true
            _initialize_passthrough()

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("toggle_passthrough"):
        toggle_passthrough() 