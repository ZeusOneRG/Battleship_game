class_name Ship
extends RefCounted

var ship_name: String
var size: int
var occupied_cells: Array[Vector2i] = []
var hits: int = 0
var is_sunk: bool = false

func _init(p_name: String, p_size: int) -> void:
	ship_name = p_name
	size = p_size

# Returns true if the ship sinks with this specific hit
func take_damage() -> bool:
	if is_sunk: 
		return true
		
	hits += 1
	if hits >= size:
		is_sunk = true
		
	return is_sunk
