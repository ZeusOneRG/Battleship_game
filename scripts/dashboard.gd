class_name Dashboard 
extends GridContainer

const BOARD_SIZE: int = 10
const CELL_SIZE: int = 48 

# Enums replace hardcoded strings for cleaner state management
enum ShotResult { ALREADY_SHOT, MISS, HIT, SUNK, ERROR }

# Colors exposed to the Godot Inspector
@export var hit_color: Color = Color(0.423, 0.0, 0.0, 1.0)
@export var miss_color: Color = Color(0.0, 0.318, 0.466, 1.0)
@export var placement_color: Color = Color(0.0, 0.354, 0.0, 1.0)

# Strictly typed collections using the Ship class
var ships: Dictionary[Vector2i, Ship] = {}       
var shots: Dictionary[Vector2i, ShotResult] = {}      
var fleet: Array[Ship] = []        
var is_enemy: bool = false        

var button_matrix: Dictionary[Vector2i, TextureButton] = {}
var solid_texture: GradientTexture2D

func _init() -> void:
	var gradient = Gradient.new()
	gradient.offsets = [0.0, 1.0]
	gradient.colors = [Color.WHITE, Color.WHITE]
	
	solid_texture = GradientTexture2D.new()
	solid_texture.gradient = gradient
	solid_texture.width = CELL_SIZE
	solid_texture.height = CELL_SIZE

func clear_board() -> void:
	ships.clear()
	shots.clear()
	fleet.clear()
	button_matrix.clear()
	columns = BOARD_SIZE
	
	# Clean up all UI buttons to prevent memory leaks
	for child in get_children():
		child.queue_free()

func register_grid_button(coord: Vector2i, button: TextureButton) -> void:
	button_matrix[coord] = button

func place_ship(ship: Ship, cells: Array[Vector2i]) -> void:
	ship.occupied_cells = cells
		
	for coord in cells:
		ships[coord] = ship
		
		# Highlight placement only on the player's board
		if not is_enemy and button_matrix.has(coord):
			var button: TextureButton = button_matrix[coord]
			button.texture_normal = solid_texture
			button.texture_disabled = solid_texture
			button.texture_focused = solid_texture
			button.modulate = placement_color 
			button.self_modulate = Color.WHITE
			
	fleet.append(ship)

func register_shot(coord: Vector2i) -> ShotResult:
	if shots.has(coord):
		return ShotResult.ALREADY_SHOT
		
	if not button_matrix.has(coord):
		return ShotResult.ERROR
		
	var target_button: TextureButton = button_matrix[coord]
	target_button.texture_normal = solid_texture
	target_button.texture_disabled = solid_texture
	target_button.texture_focused = solid_texture
		
	if ships.has(coord):
		shots[coord] = ShotResult.HIT
		target_button.modulate = hit_color 
		target_button.self_modulate = Color.WHITE
		
		var ship: Ship = ships[coord]
		var sunk: bool = ship.take_damage()
		
		if sunk:
			shots[coord] = ShotResult.SUNK
			return ShotResult.SUNK
			
		return ShotResult.HIT
	else:
		shots[coord] = ShotResult.MISS
		target_button.modulate = miss_color
		target_button.self_modulate = Color.WHITE
		return ShotResult.MISS

func has_active_ships() -> bool:
	for ship in fleet:
		if not ship.is_sunk:
			return true
	return false
