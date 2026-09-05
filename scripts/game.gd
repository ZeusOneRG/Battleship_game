extends Node2D

# Strict state management
enum GameState { PLACEMENT, COMBAT, GAME_OVER }

@onready var player_dashboard: Dashboard = $MarginContainer/HBoxContainer/Dashboard
@onready var enemy_dashboard: Dashboard = $MarginContainer/HBoxContainer/Dashboard2
@onready var status_label: Label = $Background/Status

var current_state: GameState = GameState.PLACEMENT
var ship_sizes: Array[int] = [5, 4, 3, 2]
var ship_names: Array[String] = ["Carrier", "Battleship", "Cruiser", "Submarine"]
var current_ship_idx: int = 0
var is_horizontal: bool = true

func _ready() -> void:
	# 1. Setup sides
	player_dashboard.is_enemy = false
	enemy_dashboard.is_enemy = true
	
	# 2. Lock UI dimensions
	player_dashboard.custom_minimum_size = Vector2(480, 480)
	enemy_dashboard.custom_minimum_size = Vector2(480, 480)
	
	# 3. Text styling
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 34)
	status_label.add_theme_color_override("font_color", Color.YELLOW)
	
	reset_game()

func setup_grid_buttons(grid: Dashboard, click_callback: Callable) -> void:
	grid.clear_board()
	
	var gradient = Gradient.new()
	gradient.offsets = [0.0, 1.0]
	gradient.colors = [Color(0.0, 0.2, 0.6, 0.3), Color(0.0, 0.2, 0.6, 0.3)]
	
	var base_texture = GradientTexture2D.new()
	base_texture.gradient = gradient
	base_texture.width = 48
	base_texture.height = 48
	
	for i in range(100):
		var btn = TextureButton.new()
		btn.custom_minimum_size = Vector2(48, 48)
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_SCALE
		
		btn.texture_normal = base_texture
		btn.texture_disabled = base_texture
		btn.texture_focused = base_texture
		
		btn.modulate = Color.WHITE
		btn.self_modulate = Color.WHITE
		
		# Map 1D loop index to 2D coordinates
		var coord = Vector2i(i % 10, i / 10)
		btn.pressed.connect(func(): click_callback.call(coord))
		
		grid.add_child(btn)
		grid.register_grid_button(coord, btn)

func reset_game() -> void:
	current_ship_idx = 0
	current_state = GameState.PLACEMENT
	status_label.text = "Place your " + ship_names[current_ship_idx] + ". [R] Rotate."
	
	setup_grid_buttons(player_dashboard, _on_player_grid_clicked)
	setup_grid_buttons(enemy_dashboard, _on_enemy_grid_clicked)

func _input(event: InputEvent) -> void:
	# It is highly recommended to configure "rotate_ship" in Project -> Input Map
	if event.is_action_pressed("ui_focus_next") or (event is InputEventKey and event.pressed and event.keycode == KEY_R):
		is_horizontal = not is_horizontal

func _on_player_grid_clicked(coord: Vector2i) -> void:
	if current_state != GameState.PLACEMENT: 
		return
		
	var size: int = ship_sizes[current_ship_idx]
	var cells: Array[Vector2i] = []
	
	for i in range(size):
		var c: Vector2i = Vector2i(coord.x + i, coord.y) if is_horizontal else Vector2i(coord.x, coord.y + i)
		
		# Reject invalid placement (out of bounds or overlapping)
		if c.x >= 10 or c.y >= 10 or player_dashboard.ships.has(c): 
			return
		cells.append(c)
	
	var ship = Ship.new(ship_names[current_ship_idx], size)
	player_dashboard.place_ship(ship, cells)
	
	current_ship_idx += 1
	
	if current_ship_idx < ship_sizes.size():
		status_label.text = "Place your " + ship_names[current_ship_idx] + ". [R] Rotate."
	else:
		current_state = GameState.COMBAT
		status_label.text = "To battle! Attack the right grid."
		generate_enemy_fleet()

func generate_enemy_fleet() -> void:
	for i in range(ship_sizes.size()):
		var ship = Ship.new(ship_names[i], ship_sizes[i])
		var valid_cells: Array[Vector2i] = []
		
		# Keep recalculating until a valid spot is found
		while valid_cells.size() < ship_sizes[i]:
			valid_cells.clear()
			var is_horiz: bool = (randi() % 2 == 0)
			var origin: Vector2i = Vector2i(randi() % 10, randi() % 10)
			
			for j in range(ship_sizes[i]):
				var c: Vector2i = Vector2i(origin.x + j, origin.y) if is_horiz else Vector2i(origin.x, origin.y + j)
				if c.x >= 10 or c.y >= 10 or enemy_dashboard.ships.has(c): 
					break
				valid_cells.append(c)
				
		enemy_dashboard.place_ship(ship, valid_cells)

func _on_enemy_grid_clicked(coord: Vector2i) -> void:
	if current_state != GameState.COMBAT or enemy_dashboard.shots.has(coord): 
		return
		
	var result: Dashboard.ShotResult = enemy_dashboard.register_shot(coord)
	
	# Provide feedback via UI
	match result:
		Dashboard.ShotResult.MISS:
			status_label.text = "Ally shot: Miss"
		Dashboard.ShotResult.HIT:
			status_label.text = "Ally shot: Hit!"
		Dashboard.ShotResult.SUNK:
			status_label.text = "Ally shot: Sunk target!"
			
	if not enemy_dashboard.has_active_ships():
		status_label.text = "TOTAL VICTORY!"
		current_state = GameState.GAME_OVER
		return
		
	process_enemy_turn()

func process_enemy_turn() -> void:
	var is_done: bool = false
	var attempts: int = 0
	
	while not is_done and attempts < 200:
		attempts += 1
		var c: Vector2i = Vector2i(randi() % 10, randi() % 10)
		
		if not player_dashboard.shots.has(c):
			var result: Dashboard.ShotResult = player_dashboard.register_shot(c)
			
			match result:
				Dashboard.ShotResult.MISS:
					status_label.text = "Enemy shot " + str(c) + ": Miss"
				Dashboard.ShotResult.HIT:
					status_label.text = "Enemy shot " + str(c) + ": Hit!"
				Dashboard.ShotResult.SUNK:
					status_label.text = "Enemy shot " + str(c) + ": Ship sunk!"
			
			is_done = true
			
	if not player_dashboard.has_active_ships():
		status_label.text = "Defeat. Game over."
		current_state = GameState.GAME_OVER
