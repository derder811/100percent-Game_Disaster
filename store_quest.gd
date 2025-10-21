extends Node

# Store quest: sequential interactions in order
# 1) Ice Cream Fridge
# 2) Meat Fridge
# 3) Hotdog & Siopao Fridge
# 4) Slurpee Machine (last)

var objectives = {
	"interact_ice_cream_fridge": false,
	"interact_meat_fridge": false,
	"interact_hotdog_siopao": false,
	"interact_slurpee": false,
}

var current_objective_index := 0

@onready var objective_checkboxes: Array = []
@onready var objective_labels: Array = []
@onready var quest_box: Control
var original_position: Vector2
var is_quest_box_visible := false
var quest_started := false

func _ready():
	# Cache UI nodes
	var objectives_container = get_node_or_null("Quest UI/Quest Text Box/QuestContainer/Objectives")
	quest_box = get_node_or_null("Quest UI/Quest Text Box")
	
	if quest_box:
		# Position on right side of the screen
		var viewport_size = get_viewport().size
		var margin := 24.0
		original_position = Vector2(viewport_size.x - quest_box.size.x - margin, margin)
		quest_box.position = original_position
		# Do NOT show by default; will be started by cashier interaction
		quest_box.visible = false
	else:
		print("StoreQuest: WARNING - Quest box not found")
	
	if objectives_container:
		for child in objectives_container.get_children():
			if child is HBoxContainer:
				for subchild in child.get_children():
					if subchild is CheckBox:
						objective_checkboxes.append(subchild)
					elif subchild is Label:
						objective_labels.append(subchild)
	else:
		print("StoreQuest: WARNING - Objectives container not found")
	
	update_quest_ui()

func update_quest_ui():
	var objective_texts = [
		"Interact with the Ice Cream Fridge",
		"Interact with the Meat Fridge",
		"Interact with the Hotdog & Siopao Fridge",
		"Interact with the Slurpee Machine",
	]
	
	# Hide all
	for i in range(objective_checkboxes.size()):
		if i < objective_checkboxes.size() and objective_checkboxes[i]:
			objective_checkboxes[i].visible = false
		if i < objective_labels.size() and objective_labels[i]:
			objective_labels[i].visible = false
	
	# Show current
	if current_objective_index < objective_texts.size() and current_objective_index < objective_labels.size() and current_objective_index < objective_checkboxes.size():
		var current_label: Label = objective_labels[current_objective_index]
		var current_checkbox: CheckBox = objective_checkboxes[current_objective_index]
		if current_label:
			current_label.visible = true
			var keys = ["interact_ice_cream_fridge", "interact_meat_fridge", "interact_hotdog_siopao", "interact_slurpee"]
			var text = objective_texts[current_objective_index]
			var completed = objectives[keys[current_objective_index]]
			if completed:
				current_label.modulate = Color.GREEN
				current_label.text = "✓ " + text
			else:
				current_label.modulate = Color.WHITE
				current_label.text = text
		if current_checkbox:
			current_checkbox.visible = true
			var keys2 = ["interact_ice_cream_fridge", "interact_meat_fridge", "interact_hotdog_siopao", "interact_slurpee"]
			current_checkbox.button_pressed = objectives[keys2[current_objective_index]]
	
	# Progress label
	var progress_label: Label = get_node_or_null("Quest UI/Quest Text Box/QuestContainer/ProgressLabel")
	if progress_label:
		var done := 0
		for v in objectives.values():
			if v: done += 1
		progress_label.text = "Quest Progress: %d/4" % done

func complete_objective(objective_name: String):
	if not quest_started:
		print("StoreQuest: interaction ignored; quest not started")
		return
	var idx := _objective_index(objective_name)
	if idx == -1:
		print("StoreQuest: Unknown objective", objective_name)
		return
	# Enforce sequence strictly
	if idx != current_objective_index:
		print("StoreQuest: Not the current objective yet (", objective_name, ")")
		return
	if objectives[objective_name]:
		print("StoreQuest: Objective already completed", objective_name)
		return
	
	objectives[objective_name] = true
	update_quest_ui()
	animate_objective_completion(idx)
	
	await get_tree().create_timer(0.8).timeout
	if current_objective_index < 3:
		current_objective_index += 1
		update_quest_ui()
	else:
		animate_quest_completion()

func _objective_index(name: String) -> int:
	match name:
		"interact_ice_cream_fridge":
			return 0
		"interact_meat_fridge":
			return 1
		"interact_hotdog_siopao":
			return 2
		"interact_slurpee":
			return 3
		_:
			return -1

func animate_objective_completion(objective_index: int):
	if objective_index >= 0 and objective_index < objective_checkboxes.size() and objective_index < objective_labels.size():
		var checkbox: CheckBox = objective_checkboxes[objective_index]
		var label: Label = objective_labels[objective_index]
		if checkbox and label:
			var tween = create_tween()
			tween.set_parallel(true)
			checkbox.scale = Vector2(0.85, 0.85)
			tween.tween_property(checkbox, "scale", Vector2(1.15, 1.15), 0.2)
			tween.tween_property(checkbox, "scale", Vector2(1.0, 1.0), 0.2).set_delay(0.2)
			label.modulate = Color.WHITE
			tween.tween_property(label, "modulate", Color.GREEN, 0.35)
			# Extra quest box bounce + highlight
			if quest_box:
				var q_tween = create_tween()
				q_tween.set_parallel(true)
				q_tween.tween_property(quest_box, "scale", Vector2(1.06, 1.06), 0.15)
				q_tween.tween_property(quest_box, "scale", Vector2(1.0, 1.0), 0.15).set_delay(0.15)
				var original_modulate: Color = quest_box.modulate
				q_tween.tween_property(quest_box, "modulate", Color(1.2, 1.2, 1.0, 1.0), 0.15)
				q_tween.tween_property(quest_box, "modulate", original_modulate, 0.15).set_delay(0.15)
			animate_quest_box_shake()

func animate_quest_box_shake():
	if quest_box:
		var orig = quest_box.position
		var tween = create_tween()
		tween.tween_property(quest_box, "position", orig + Vector2(3, 0), 0.05)
		tween.tween_property(quest_box, "position", orig + Vector2(-3, 0), 0.05)
		tween.tween_property(quest_box, "position", orig + Vector2(2, 0), 0.05)
		tween.tween_property(quest_box, "position", orig + Vector2(-2, 0), 0.05)
		tween.tween_property(quest_box, "position", orig, 0.05)

func animate_quest_completion():
	if quest_box:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(quest_box, "scale", Vector2(1.1, 1.1), 0.25)
		tween.tween_property(quest_box, "scale", Vector2(1.0, 1.0), 0.25).set_delay(0.25)
		tween.tween_property(quest_box, "modulate", Color(1.5, 1.3, 0.8, 1.0), 0.5)
		tween.tween_property(quest_box, "modulate", Color.WHITE, 0.5).set_delay(0.5)

func show_quest_box_with_animation():
	if quest_box and not is_quest_box_visible:
		is_quest_box_visible = true
		quest_box.visible = true
		quest_box.scale = Vector2(0.3, 0.3)
		quest_box.modulate.a = 0.0
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(quest_box, "scale", Vector2(1.1, 1.1), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(quest_box, "scale", Vector2(1.0, 1.0), 0.2).set_delay(0.3)
		tween.tween_property(quest_box, "modulate:a", 1.0, 0.4)
		var start_pos = original_position + Vector2(120, 0)
		quest_box.position = start_pos
		tween.tween_property(quest_box, "position", original_position, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	elif not quest_box:
		print("StoreQuest: ERROR - quest_box is null")

# Entry points called by item scripts
func on_ice_cream_fridge_interaction():
	complete_objective("interact_ice_cream_fridge")

func on_meat_fridge_interaction():
	complete_objective("interact_meat_fridge")

func on_hotdog_siopao_interaction():
	complete_objective("interact_hotdog_siopao")

func on_slurpee_interaction():
	complete_objective("interact_slurpee")

# New: allow external systems to hide/show the StoreQuest UI
func hide_quest_ui():
	is_quest_box_visible = false
	if quest_box:
		quest_box.visible = false

func show_quest_ui():
	if quest_box:
		quest_box.visible = true
	# Re-run the slide-in animation if it was hidden
	show_quest_box_with_animation()

# New: explicit start, only called by cashier interaction
func start_quest():
	if quest_started:
		return
	quest_started = true
	print("StoreQuest: started by cashier interaction")
	update_quest_ui()
	show_quest_ui()
