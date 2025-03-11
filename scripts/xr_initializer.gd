extends Node

var initialization_attempts = 0
const MAX_INITIALIZATION_ATTEMPTS = 10
var initialized = false

func _ready():
	print("Starting XR initialization sequence...")
	# Don't force XR mode immediately
	call_deferred("initialize_xr")

func initialize_xr():
	var xr = XRServer.find_interface("OpenXR")
	if not xr:
		push_error("OpenXR interface not found!")
		return
		
	print("Found OpenXR interface, attempting to initialize...")
	
	# Initialize OpenXR
	if not xr.is_initialized():
		if not xr.initialize():
			push_error("Failed to initialize OpenXR!")
			return
	
	await get_tree().create_timer(0.5).timeout  # Give the system time to initialize
	
	# Set as primary interface
	if not XRServer.get_primary_interface():
		XRServer.set_primary_interface(xr)
	
	# Enable XR mode
	get_viewport().use_xr = true
	
	initialized = true
	print("XR initialization sequence completed")
	print_status()

func print_status():
	var xr = XRServer.get_primary_interface()
	if xr:
		print("XR Status:")
		print("- Interface initialized: ", xr.is_initialized())
		print("- Primary interface set: ", XRServer.get_primary_interface() != null)
		print("- Viewport using XR: ", get_viewport().use_xr)

func _process(_delta):
	if not initialized:
		initialization_attempts += 1
		if initialization_attempts <= MAX_INITIALIZATION_ATTEMPTS:
			initialize_xr()
		elif initialization_attempts == MAX_INITIALIZATION_ATTEMPTS + 1:
			push_error("Failed to initialize XR after maximum attempts") 