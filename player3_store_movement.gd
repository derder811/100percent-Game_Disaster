extends CharacterBody2D

# Player 3 Movement Configuration for Store Scene
@export var max_speed: float = 200.0
@export var acceleration: float = 1600.0
@export var friction: float = 1300.0

# Animation
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var sprite: Sprite2D = $Sprite2D

# Self-talk system
var self_talk_system: Player3SelfTalkSystem
var last_position: Vector2
var movement_threshold: float = 100.0  # Distance threshold to trigger movement comments
var movement_count: int = 0  # Counter for movements
var movement_trigger_threshold: int = 20  # Trigger self-talk every 20 movements
# Timer-based movement comment trigger (every 10 seconds)
var movement_comment_timer: Timer

# Input Actions - Player 3 WASD movement
const MOVE_LEFT = "ui_left"         # A key / Left Arrow
const MOVE_RIGHT = "ui_right"       # D key / Right Arrow  
const MOVE_UP = "ui_up"             # W key / Up Arrow
const MOVE_DOWN = "ui_down"         # S key / Down Arrow

# Alternative WASD inputs (if custom input map is set)
const WASD_LEFT = "move_left_p3"    # A key for Player 3
const WASD_RIGHT = "move_right_p3"  # D key for Player 3
const WASD_UP = "move_up_p3"        # W key for Player 3
const WASD_DOWN = "move_down_p3"  # S key for Player 3
# Interaction UI reference
var interaction_ui: Node = null
func _ready():
	# Add player to Player2 group for interaction system
	add_to_group("Player2")
	print("Player 3 initialized in store scene and added to Player2 group")
	
	# Initialize self-talk system
	setup_self_talk_system()
	
	# Ensure mobile overlay (joystick + interact + prompt)
	ensure_mobile_overlay()
	
	# Store initial position
	last_position = global_position
	
	# Connect to physics process for smooth movement
	set_physics_process(true)
	
	# Set up a timer to trigger movement comments every 10 seconds
	var existing_timer = get_node_or_null("MovementCommentTimer")
	if existing_timer and (existing_timer is Timer):
		movement_comment_timer = existing_timer
	else:
		movement_comment_timer = Timer.new()
		movement_comment_timer.name = "MovementCommentTimer"
		movement_comment_timer.wait_time = 10.0
		movement_comment_timer.one_shot = false
		movement_comment_timer.autostart = true
		movement_comment_timer.timeout.connect(_on_movement_comment_timer_timeout)
		add_child(movement_comment_timer)

func ensure_mobile_overlay():
	var scene = get_tree().current_scene
	var root = get_tree().root
	print("Store: ensure_mobile_overlay on scene:", scene)
	if root:
		if not root.get_node_or_null("InteractionUI"):
			print("Store: Adding InteractionUI overlay to root")
			var ui_scene: PackedScene = load("res://InteractionUI.tscn")
			if ui_scene:
				var ui_instance = ui_scene.instantiate()
				ui_instance.name = "InteractionUI"
				root.add_child(ui_instance)
		if not root.get_node_or_null("MobileControls"):
			print("Store: Adding MobileControls overlay to root")
			var mc_scene: PackedScene = load("res://MobileControls.tscn")
			if mc_scene:
				var mc_instance = mc_scene.instantiate()
				mc_instance.name = "MobileControls"
				root.add_child(mc_instance)
	interaction_ui = root.get_node_or_null("InteractionUI")
	print("Store: InteractionUI present on root:", interaction_ui != null)

func _on_movement_comment_timer_timeout():
	# Trigger movement comment on a fixed interval
	if self_talk_system:
		self_talk_system.trigger_movement_comment()

func _physics_process(delta):
	handle_movement(delta)
	move_and_slide()
	
	# Timer now drives movement comments; disable distance-based triggering
	# check_movement_for_self_talk()

func handle_movement(delta):
	# Get input vector
	var input_vector = Vector2.ZERO
	
	# Check for WASD movement input (using ui_ actions as fallback)
	if Input.is_action_pressed(MOVE_LEFT) or Input.is_action_pressed("ui_left"):
		input_vector.x -= 1
	if Input.is_action_pressed(MOVE_RIGHT) or Input.is_action_pressed("ui_right"):
		input_vector.x += 1
	if Input.is_action_pressed(MOVE_UP) or Input.is_action_pressed("ui_up"):
		input_vector.y -= 1
	if Input.is_action_pressed(MOVE_DOWN) or Input.is_action_pressed("ui_down"):
		input_vector.y += 1
	
	# Also check for custom WASD inputs if they exist
	if Input.is_action_pressed("move_left") or (InputMap.has_action(WASD_LEFT) and Input.is_action_pressed(WASD_LEFT)):
		input_vector.x -= 1
	if Input.is_action_pressed("move_right") or (InputMap.has_action(WASD_RIGHT) and Input.is_action_pressed(WASD_RIGHT)):
		input_vector.x += 1
	if Input.is_action_pressed("move_up") or (InputMap.has_action(WASD_UP) and Input.is_action_pressed(WASD_UP)):
		input_vector.y -= 1
	if Input.is_action_pressed("move_down") or (InputMap.has_action(WASD_DOWN) and Input.is_action_pressed(WASD_DOWN)):
		input_vector.y += 1
	
	# Normalize for consistent diagonal movement
	input_vector = input_vector.normalized()
	
	# Update animation direction based on movement
	if animation_tree and input_vector != Vector2.ZERO:
		# Try different parameter paths that might exist
		if animation_tree.has_method("set"):
			# Try common animation tree parameter names
			var param_paths = [
				"parameters/Walk/blend_position",
				"parameters/walk/blend_position", 
				"parameters/movement/blend_position",
				"parameters/idle_walk/blend_position"
			]
			
			for path in param_paths:
				if animation_tree.get(path) != null:
					animation_tree.set(path, input_vector)
					break
	
	# Apply movement with smooth acceleration/deceleration
	if input_vector != Vector2.ZERO:
		# Accelerate towards target velocity
		velocity = velocity.move_toward(input_vector * max_speed, acceleration * delta)
	else:
		# Apply friction when no input
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

# Debug function to print current position
func _input(event):
	if event.is_action_pressed("ui_accept"):  # Space or Enter key
		print("Player 3 position: ", global_position)

func setup_self_talk_system():
	"""Initialize the self-talk system for Player 3"""
	# Create and add the self-talk system as a child
	self_talk_system = preload("res://player3_self_talk_system.gd").new()
	add_child(self_talk_system)
	print("Player 3 self-talk system initialized")

func check_movement_for_self_talk():
	"""Check if player has moved significantly to trigger movement comments"""
	if self_talk_system and last_position.distance_to(global_position) > movement_threshold:
		movement_count += 1
		last_position = global_position
		
		# Only trigger self-talk every 20 movements
		if movement_count >= movement_trigger_threshold:
			self_talk_system.trigger_movement_comment()
			movement_count = 0  # Reset counter after triggering

func trigger_item_self_talk(item_type: String):
	"""Trigger self-talk when interacting with items"""
	print("DEBUG: trigger_item_self_talk called with item_type: ", item_type)
	print("DEBUG: self_talk_system exists: ", self_talk_system != null)
	if self_talk_system:
		print("DEBUG: Calling trigger_after_item_interact_talk on self_talk_system")
		self_talk_system.trigger_after_item_interact_talk(item_type)
	else:
		print("DEBUG: self_talk_system is null!")

func trigger_custom_self_talk(message: String):
	"""Trigger custom self-talk message"""
	if self_talk_system:
		self_talk_system.trigger_custom_self_talk(message)

# --- Cover API for table hide ---
func hide_for_cover():
	# Hide the entire player and its sprite; stop processing
	visible = false
	modulate = Color(1, 1, 1, 0)  # Force alpha to 0 as a safety net
	if sprite:
		sprite.visible = false
		sprite.modulate = Color(1, 1, 1, 0)
	set_physics_process(false)
	set_process(false)
	# Hide any on-screen self-talk UI to avoid lingering bubbles
	if self_talk_system:
		if self_talk_system.has_method("_hide_textbox"):
			self_talk_system._hide_textbox()
		if self_talk_system.has_method("_hide_bubble"):
			self_talk_system._hide_bubble()

func show_after_cover():
	# Restore visuals and processing
	visible = true
	modulate = Color(1, 1, 1, 1)
	if sprite:
		sprite.visible = true
		sprite.modulate = Color(1, 1, 1, 1)
	set_physics_process(true)
	set_process(true)
