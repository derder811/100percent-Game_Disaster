extends Area2D

@onready var interaction_area = $InteractionArea
@onready var interaction_label = $InteractionLabel

func _ready():
	print("Store Entrance: Setting up interaction area")
	
	# Set up interaction area to work with InteractionManager
	if interaction_area:
		interaction_area.interact = Callable(self, "_on_interact")
		interaction_area.action_name = "Go Inside"
		print("Store Entrance: InteractionArea action_name set to: ", interaction_area.action_name)
		print("Store Entrance: InteractionArea collision_mask: ", interaction_area.collision_mask)
		print("Store Entrance: Ready for E key interaction!")
		
		# Connect signals for showing/hiding the interaction text
		interaction_area.body_entered.connect(_on_player_entered)
		interaction_area.body_exited.connect(_on_player_exited)
		
		# Make sure the interaction area connects to the InteractionManager
		# The interaction_area.gd script should handle this automatically
		print("Store Entrance: InteractionArea should auto-register with InteractionManager")
	else:
		print("Warning: InteractionArea not found in Store Entrance")
	
	# Make sure the label starts hidden
	if interaction_label:
		interaction_label.visible = false

func _on_player_entered(body):
	print("DEBUG: Player entered store entrance area: ", body.name)
	if body.is_in_group("Player2"):
		print("DEBUG: Showing interaction label")
		if interaction_label:
			interaction_label.visible = true

func _on_player_exited(body):
	print("DEBUG: Player exited store entrance area: ", body.name)
	if body.is_in_group("Player2"):
		print("DEBUG: Hiding interaction label")
		if interaction_label:
			interaction_label.visible = false

func _on_interact():
	print("DEBUG: Store entrance _on_interact called!")
	print("Store Entrance: Transitioning to store scene...")
	
	# Check if we have access to the scene tree
	var tree = get_tree()
	if not tree:
		print("ERROR: Scene tree is null! Cannot change scene.")
		return
	
	# Add a small delay to ensure the interaction completes properly
	await tree.create_timer(0.1).timeout
	
	# Double-check tree is still valid after await
	tree = get_tree()
	if not tree:
		print("ERROR: Scene tree became null after timer! Cannot change scene.")
		return
	
	print("DEBUG: Attempting to change scene to inside_the_store.tscn")
	var result = tree.change_scene_to_file("res://inside_the_store.tscn")
	if result != OK:
		print("ERROR: Failed to change scene to inside_the_store.tscn. Error code: ", result)
	else:
		print("DEBUG: Scene change initiated successfully")
