extends Area2D

signal player_hidden(table_name: String)
signal player_unhidden(table_name: String)

@onready var interaction_area: InteractionArea = $InteractionArea
var is_player_hidden: bool = false
var _player_in_area: Node = null

func _ready():
	# Allow EarthquakeQuest to find all tables easily
	add_to_group("table_hide")
	if interaction_area:
		interaction_area.action_name = "hide under table"
		interaction_area.interact = Callable(self, "_on_interact")
		# Track which body actually entered this area (so we hide the correct player)
		interaction_area.body_entered.connect(_on_area_body_entered)
		interaction_area.body_exited.connect(_on_area_body_exited)
		print("TableHide: InteractionArea configured for hiding")
	else:
		print("TableHide: ERROR - InteractionArea not found on table")

func _on_area_body_entered(body: Node) -> void:
	if body and body.is_in_group("Player2"):
		_player_in_area = body
		# Update prompt based on quake state
		if interaction_area:
			interaction_area.action_name = "hide under table" if _is_quake_active() else "wait for earthquake"
		print("TableHide: Player candidate set to ", body.name)

func _on_area_body_exited(body: Node) -> void:
	if _player_in_area == body:
		_player_in_area = null
		print("TableHide: Player candidate cleared (exited area)")
		# Reset prompt when player leaves
		if interaction_area and not is_player_hidden:
			interaction_area.action_name = "hide under table"

func _on_interact():
	var player: Node = null
	# Prefer the actual body inside the area
	if _player_in_area and is_instance_valid(_player_in_area):
		player = _player_in_area
	else:
		# Fallback to first Player2 in scene tree
		player = get_tree().get_first_node_in_group("Player2")
	
	if not player:
		print("TableHide: ERROR - Player2 not found in scene")
		return
	
	# Gate hiding to when EarthquakeQuest is active; always allow coming out
	if not is_player_hidden:
		if not _is_quake_active():
			print("TableHide: Quake not active; cannot hide yet.")
			if interaction_area:
				interaction_area.action_name = "wait for earthquake"
			# Optional: show self-talk hint
			if player.has_method("trigger_custom_self_talk"):
				player.trigger_custom_self_talk("I should only hide during an earthquake.")
			return
		_hide_player(player)
	else:
		_unhide_player(player)

func _hide_player(player: Node):
	# Move player near/under the table for clarity
	player.global_position = global_position + Vector2(0, 0)
	
	# Hide visuals and stop movement
	if player.has_method("hide_for_cover"):
		player.hide_for_cover()
	else:
		player.visible = false
		if player.has_method("set_physics_process"):
			player.set_physics_process(false)
	
	# Update interaction prompt and state
	is_player_hidden = true
	if interaction_area:
		interaction_area.action_name = "come out"
	print("TableHide: Player is now hidden under the table")
	
	# Notify quests
	emit_signal("player_hidden", name)
	
	# Optional self-talk
	var self_talk_nodes = get_tree().get_nodes_in_group("self_talk_system")
	if self_talk_nodes.size() > 0:
		var self_talk_system = self_talk_nodes[0]
		if self_talk_system.has_method("trigger_custom_self_talk"):
			self_talk_system.trigger_custom_self_talk("I'm covered under the table.")

func _unhide_player(player: Node):
	# Show visuals and resume movement
	if player.has_method("show_after_cover"):
		player.show_after_cover()
	else:
		player.visible = true
		if player.has_method("set_physics_process"):
			player.set_physics_process(true)
	
	# Update interaction prompt and state
	is_player_hidden = false
	if interaction_area:
		# Restore prompt based on quake state
		interaction_area.action_name = "hide under table" if _is_quake_active() else "wait for earthquake"
	print("TableHide: Player has come out from under the table")
	
	# Notify quests
	emit_signal("player_unhidden", name)
	
	# Optional self-talk
	var self_talk_nodes = get_tree().get_nodes_in_group("self_talk_system")
	if self_talk_nodes.size() > 0:
		var self_talk_system = self_talk_nodes[0]
		if self_talk_system.has_method("trigger_custom_self_talk"):
			self_talk_system.trigger_custom_self_talk("It’s safe, I’ll come out now.")

func _is_quake_active() -> bool:
	var eq = get_tree().current_scene.find_child("EarthquakeQuest", true, false)
	if eq == null:
		return false
	# Prefer public accessor when available
	if eq.has_method("is_active"):
		return eq.is_active()
	# Fallback to internal flag via reflection
	var v = eq.get("_quest_active")
	if typeof(v) == TYPE_BOOL:
		return v
	return false
