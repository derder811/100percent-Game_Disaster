extends Node2D

# Reference to the quest manager
var quest_manager = null

# Animation variables
var flood_tile_layer: TileMapLayer
var is_flood_visible = false
var flood_animation_tween: Tween

func _ready():
	print("Flood: _ready() called - initializing flood system")
	
	# Hide the flood initially
	visible = false
	modulate.a = 0.0
	
	# Get reference to the flood tile layer
	flood_tile_layer = get_node_or_null("FLOODTILE")
	if flood_tile_layer:
		print("Flood: Found flood tile layer")
		flood_tile_layer.modulate.a = 0.0
	else:
		print("Flood: ERROR - Could not find FLOODTILE layer")
	
	# Connect to quest manager when it becomes available
	call_deferred("connect_to_quest_manager")

func connect_to_quest_manager():
	"""Connect to the quest manager to listen for timer expiration"""
	print("Flood: Attempting to connect to quest manager")
	
	# Try to get quest manager from singleton
	if Engine.has_singleton("QuestManager"):
		quest_manager = Engine.get_singleton("QuestManager")
		print("Flood: Connected to QuestManager singleton")
	else:
		# Try to find quest manager in the scene tree
		var scene = get_tree().current_scene
		if scene:
			quest_manager = scene.find_child("Quest", true, false)
			if not quest_manager:
				# Try alternative names
				quest_manager = scene.find_child("QuestManager", true, false)
		
		if quest_manager:
			print("Flood: Found quest manager in scene tree: ", quest_manager.name)
		else:
			print("Flood: WARNING - Could not find quest manager, will retry later")
			# Retry connection after a short delay
			await get_tree().create_timer(1.0).timeout
			connect_to_quest_manager()
			return
	
	# Connect to quest manager's timer expiration if it has the method
	if quest_manager and quest_manager.has_method("connect_flood_system"):
		quest_manager.connect_flood_system(self)
		print("Flood: Connected to quest manager's flood system")
	elif quest_manager:
		# If quest manager doesn't have the connect method, we'll monitor it directly
		print("Flood: Quest manager found, will monitor timer status")
		start_monitoring_quest_timer()
	else:
		print("Flood: ERROR - Quest manager not available")

func start_monitoring_quest_timer():
	"""Monitor the quest manager's timer status"""
	if quest_manager:
		# Check timer status every second
		var timer = Timer.new()
		timer.wait_time = 0.5
		timer.timeout.connect(_check_quest_timer_status)
		add_child(timer)
		timer.start()
		print("Flood: Started monitoring quest timer")

func _check_quest_timer_status():
	"""Check if the quest timer has expired"""
	if quest_manager and quest_manager.has_method("is_timer_expired"):
		if quest_manager.is_timer_expired():
			trigger_flood_animation()
	elif quest_manager and "time_remaining" in quest_manager and "is_timer_active" in quest_manager:
		# Direct property access
		if quest_manager.is_timer_active and quest_manager.time_remaining <= 0:
			trigger_flood_animation()

func on_quest_timer_expired():
	"""Called by quest manager when timer expires"""
	print("Flood: Quest timer expired - triggering flood animation")
	trigger_flood_animation()

func trigger_flood_animation():
	"""Trigger the flood animation when the third quest timer ends"""
	if is_flood_visible:
		return  # Already showing flood
	
	print("Flood: Starting flood animation")
	is_flood_visible = true
	
	# Make the flood node visible
	visible = true
	
	# Create flood animation tween
	if flood_animation_tween:
		flood_animation_tween.kill()
	
	flood_animation_tween = create_tween()
	flood_animation_tween.set_parallel(true)
	
	# Animate the entire flood scene fading in
	flood_animation_tween.tween_property(self, "modulate:a", 1.0, 2.0).set_ease(Tween.EASE_IN_OUT)
	
	# Animate the flood tiles with a wave-like effect
	if flood_tile_layer:
		animate_flood_wave()
	
	# Add screen shake effect for dramatic impact
	animate_screen_shake()
	
	print("Flood: Flood animation started successfully")

func animate_flood_wave():
	"""Create a wave-like animation for the flood tiles"""
	if not flood_tile_layer:
		return
	
	# Start with tiles invisible
	flood_tile_layer.modulate.a = 0.0
	
	# Animate flood tiles appearing in waves
	var wave_tween = create_tween()
	
	# First wave - bottom tiles appear
	wave_tween.tween_property(flood_tile_layer, "modulate:a", 0.3, 0.5).set_delay(0.5)
	wave_tween.tween_property(flood_tile_layer, "modulate:a", 0.6, 0.5).set_delay(1.0)
	wave_tween.tween_property(flood_tile_layer, "modulate:a", 0.9, 0.5).set_delay(1.5)
	wave_tween.tween_property(flood_tile_layer, "modulate:a", 1.0, 0.5).set_delay(2.0)
	
	# Add a subtle pulsing effect to simulate water movement
	wave_tween.tween_callback(start_water_pulse_effect).set_delay(3.0)

func start_water_pulse_effect():
	"""Add a subtle pulsing effect to simulate water movement"""
	if not flood_tile_layer:
		return
	
	var pulse_tween = create_tween()
	pulse_tween.set_loops()  # Infinite loop
	
	# Subtle alpha pulsing between 0.9 and 1.0
	pulse_tween.tween_property(flood_tile_layer, "modulate:a", 0.9, 1.5)
	pulse_tween.tween_property(flood_tile_layer, "modulate:a", 1.0, 1.5)

func animate_screen_shake():
	"""Add screen shake effect for dramatic impact"""
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return
	
	var original_position = camera.global_position
	var shake_tween = create_tween()
	
	# Intense shake for 2 seconds
	var shake_duration = 2.0
	var shake_intensity = 10.0
	var shake_steps = 20
	
	for i in range(shake_steps):
		var shake_offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		shake_tween.tween_property(camera, "global_position", original_position + shake_offset, shake_duration / shake_steps)
	
	# Return to original position
	shake_tween.tween_property(camera, "global_position", original_position, 0.2)

func hide_flood():
	"""Hide the flood (for testing or reset purposes)"""
	visible = false
	modulate.a = 0.0
	is_flood_visible = false
	
	if flood_tile_layer:
		flood_tile_layer.modulate.a = 0.0
	
	if flood_animation_tween:
		flood_animation_tween.kill()
	
	print("Flood: Flood hidden")

func show_flood_immediately():
	"""Show flood immediately (for testing purposes)"""
	visible = true
	modulate.a = 1.0
	is_flood_visible = true
	
	if flood_tile_layer:
		flood_tile_layer.modulate.a = 1.0
	
	print("Flood: Flood shown immediately")
