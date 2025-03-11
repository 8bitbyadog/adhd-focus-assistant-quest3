extends Node

var xr_interface: XRInterface
var manual_mode := false
var is_xr_initialized := false
var initialization_attempts := 0
var session_start_attempts := 0
const MAX_ATTEMPTS := 3
const MAX_SESSION_ATTEMPTS := 3

@onready var init_timer := Timer.new()
@onready var session_timer := Timer.new()
@onready var recovery_timer := Timer.new()

func _ready():
	# Add input for manual toggle
	if not InputMap.has_action("toggle_vr"):
		InputMap.add_action("toggle_vr")
		var event = InputEventKey.new()
		event.keycode = KEY_V
		InputMap.action_add_event("toggle_vr", event)
	
	# Set up recovery timer
	add_child(recovery_timer)
	recovery_timer.one_shot = true
	recovery_timer.timeout.connect(_on_recovery_timer_timeout)
	
	# Wait for system to fully initialize
	await get_tree().create_timer(3.0).timeout
	
	# Start XR initialization
	initialize_xr()

func initialize_xr():
	print("Starting XR initialization...")
	
	# Reset state
	is_xr_initialized = false
	session_start_attempts = 0
	
	# Find our interface
	xr_interface = XRServer.find_interface("OpenXR")
	if not xr_interface:
		print("ERROR: OpenXR interface not found")
		return
	
	# Configure interface signals
	if not xr_interface.session_begun.is_connected(_on_session_begun):
		xr_interface.session_begun.connect(_on_session_begun)
	if not xr_interface.session_stopping.is_connected(_on_session_stopping):
		xr_interface.session_stopping.connect(_on_session_stopping)
	if not xr_interface.session_focussed.is_connected(_on_session_focussed):
		xr_interface.session_focussed.connect(_on_session_focussed)
	if not xr_interface.pose_recentered.is_connected(_on_pose_recentered):
		xr_interface.pose_recentered.connect(_on_pose_recentered)
	
	# Set reference space type - try LOCAL for better compatibility
	xr_interface.set_reference_space_type(XRInterface.XR_REFERENCE_SPACE_TYPE_LOCAL)
	
	# Configure viewport for XR - ensure it's off before we start
	get_viewport().use_xr = false
	
	# Initialize the interface
	if xr_interface.is_initialized():
		print("OpenXR interface already initialized")
		await get_tree().create_timer(1.0).timeout
		_start_session()
	else:
		print("Initializing OpenXR interface...")
		if not xr_interface.initialize():
			print("ERROR: Failed to initialize OpenXR interface")
			retry_initialization()
			return
		
		# Wait for initialization to settle
		await get_tree().create_timer(3.0).timeout
		_start_session()

func retry_initialization():
	initialization_attempts += 1
	if initialization_attempts < MAX_ATTEMPTS:
		print("Retrying XR initialization (attempt " + str(initialization_attempts) + ")")
		await get_tree().create_timer(2.0).timeout
		initialize_xr()
	else:
		print("Failed to initialize XR after multiple attempts")
		# Fall back to non-VR mode
		get_viewport().use_xr = false
		is_xr_initialized = false
		# Start recovery timer to try again later
		recovery_timer.start(10.0)

func _on_recovery_timer_timeout():
	print("Recovery timer triggered, attempting to reinitialize XR...")
	initialization_attempts = 0
	session_start_attempts = 0
	initialize_xr()

func _process(_delta):
	# Check if we need to recover from a black screen
	if is_xr_initialized and xr_interface and not xr_interface.is_session_started():
		print("Detected session stopped unexpectedly, attempting to recover...")
		_stop_session()
		await get_tree().create_timer(2.0).timeout
		_start_session()

func _input(event):
	if event.is_action_pressed("toggle_vr"):
		toggle_xr()

func toggle_xr():
	if is_xr_initialized:
		_stop_session()
		await get_tree().create_timer(2.0).timeout
		initialize_xr()
	else:
		_start_session()

func _start_session():
	if not xr_interface or not xr_interface.is_initialized():
		print("Cannot start session - interface not initialized")
		return
	
	print("Starting XR session...")
	session_start_attempts += 1
	
	# Ensure viewport is configured correctly before starting session
	get_viewport().msaa_3d = Viewport.MSAA_4X
	
	# First make sure viewport is not in XR mode
	get_viewport().use_xr = false
	await get_tree().create_timer(1.0).timeout
	
	# Begin session
	if xr_interface.begin_session():
		print("XR session started successfully")
		await get_tree().create_timer(1.0).timeout
		get_viewport().use_xr = true
		is_xr_initialized = true
		print_status()
	else:
		print("Failed to start XR session (attempt " + str(session_start_attempts) + ")")
		
		if session_start_attempts < MAX_SESSION_ATTEMPTS:
			# Try reinitializing
			if xr_interface.initialize():
				print("Reinitialized XR interface, trying to start session again")
				await get_tree().create_timer(2.0).timeout
				
				if xr_interface.begin_session():
					print("XR session started successfully after reinitialization")
					await get_tree().create_timer(1.0).timeout
					get_viewport().use_xr = true
					is_xr_initialized = true
					print_status()
				else:
					print("Failed to start XR session after reinitialization")
					retry_initialization()
		else:
			print("Failed to start XR session after multiple attempts")
			recovery_timer.start(10.0)

func _stop_session():
	if not xr_interface:
		return
		
	if is_xr_initialized:
		print("Stopping XR session...")
		# First disable viewport XR mode
		get_viewport().use_xr = false
		
		# Wait a moment before ending session
		await get_tree().create_timer(2.0).timeout
		
		# End session
		if xr_interface.is_session_started():
			xr_interface.end_session()
		
		is_xr_initialized = false
		print("XR session stopped")

func _on_session_begun():
	print("XR Session begun")
	is_xr_initialized = true
	print_status()
	
func _on_session_stopping():
	print("XR Session stopping")
	get_viewport().use_xr = false
	is_xr_initialized = false
	
func _on_session_focussed():
	print("XR Session focused")
	
func _on_pose_recentered():
	print("XR Pose recentered")

func print_status():
	if xr_interface:
		print("XR Status:")
		print("- Interface initialized: ", xr_interface.is_initialized())
		print("- Primary interface: ", XRServer.get_primary_interface() != null)
		print("- Viewport XR: ", get_viewport().use_xr)
		print("- Session ready: ", xr_interface.is_session_started())
		print("- Reference space: ", xr_interface.get_reference_space_type())
		print("- Manual mode: ", manual_mode)
		print("- Is XR initialized: ", is_xr_initialized)
		
		# Print supported features
		print("Supported features:")
		print("- Hand tracking: ", xr_interface.is_hand_tracking_supported())
		print("- Passthrough: ", xr_interface.is_passthrough_supported())
		
		# Print blend modes
		var modes = xr_interface.get_supported_environment_blend_modes()
		print("Supported blend modes: ", modes) 