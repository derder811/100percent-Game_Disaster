extends Node

# Global game state manager
# This autoload script tracks important game states

# Track if the go bag has been picked up
var go_bag_picked_up: bool = false

# Function to mark the go bag as picked up
func set_go_bag_picked_up():
	go_bag_picked_up = true
	print("GameState: Go bag has been picked up!")

# Function to check if go bag is available
func is_go_bag_available() -> bool:
	return go_bag_picked_up

# Function to reset game state (for testing or new game)
func reset_game_state():
	go_bag_picked_up = false
	print("GameState: Game state reset")