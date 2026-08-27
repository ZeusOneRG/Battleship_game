extends Node2D

const TEXTURA_MAR = preload("res://assets/water.png")

@onready var tablero_jugador: Dashboard = $MarginContainer/HBoxContainer/Dashboard
@onready var tablero_enemigo: Dashboard = $MarginContainer/HBoxContainer/Dashboard2
@onready var texto_estado: Label = $Background/Status

var estado = "COLOCACION"
var slots = [5, 4, 3, 2]
var nombres = ["Portaaviones", "Acorazado", "Buque", "Submarino"]
var idx = 0
var horizontal = true

func _ready() -> void:
	# 1. Configurar lógica de bandos
	tablero_jugador.es_enemigo = false
	tablero_enemigo.es_enemigo = true
	
	# 2. El tamaño lo maneja el MarginContainer y el HBoxContainer de forma óptima. 
	# Forzamos solo el tamaño mínimo para evitar deformaciones.
	tablero_jugador.custom_minimum_size = Vector2(480, 480)
	tablero_enemigo.custom_minimum_size = Vector2(480, 480)
	
		# 6. Ajustar la fuente del texto de estado por código
	texto_estado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto_estado.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Le damos un tamaño de letra grande (ej: 24 píxeles) para que se lea perfecto
	texto_estado.add_theme_font_size_override("font_size", 34)
	
	# Opcional: Le ponemos un color llamativo (Amarillo o Blanco) para que resalte del fondo oscuro
	texto_estado.add_theme_color_override("font_color", Color.YELLOW)

	
	reiniciar()

func armar_botones(grid: Dashboard, funcion: Callable) -> void:
	grid.limpiar_tablero()
	
	# Creamos un gradiente que genera un cuadrado azul con bordes definidos
	var gradiente = Gradient.new()
	gradiente.offsets = [0.0, 1.0]
	gradiente.colors = [Color(0.0, 0.2, 0.6, 0.3), Color(0.0, 0.2, 0.6, 0.3)]
	
	var textura_base = GradientTexture2D.new()
	textura_base.gradient = gradiente
	textura_base.width = 48
	textura_base.height = 48
	
	for i in range(100):
		var b = TextureButton.new()
		b.custom_minimum_size = Vector2(48, 48)
		b.ignore_texture_size = true
		b.stretch_mode = TextureButton.STRETCH_SCALE
		
		# Asignamos la textura base limpia
		b.texture_normal = textura_base
		# Forzamos a que conserve su color normal brillante
		b.texture_disabled = textura_base
		b.texture_focused = textura_base
		
		# Modulación inicial neutra (Azul radar limpio)
		b.modulate = Color(1.0, 1.0, 1.0, 1.0)
		b.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
		
		var coord = Vector2i(i % 10, i / 10)
		b.pressed.connect(func(): funcion.call(coord))
		
		grid.add_child(b)
		grid.registrar_boton_matriz(coord, b)



func reiniciar() -> void:
	idx = 0
	estado = "COLOCACION"
	texto_estado.text = "Coloca tu " + nombres[idx] + ". [R] Rotar."
	
	# Armamos las grillas de botones limpiando todo lo anterior
	armar_botones(tablero_jugador, _on_click_jugador)
	armar_botones(tablero_enemigo, _on_click_enemigo)

func _input(event):
	if event.is_action_pressed("ui_focus_next") or (event is InputEventKey and event.pressed and event.keycode == KEY_R):
		horizontal = not horizontal

func _on_click_jugador(coord: Vector2i) -> void:
	if estado != "COLOCACION": return
	var tam = slots[idx]
	var celdas: Array[Vector2i] = []
	for i in range(tam):
		var c = Vector2i(coord.x + i, coord.y) if horizontal else Vector2i(coord.x, coord.y + i)
		if c.x >= 10 or c.y >= 10 or tablero_jugador.barcos.has(c): return
		celdas.append(c)
	
	var nave = Nave.new(nombres[idx], tam)
	tablero_jugador.colocar_nave_local(nave, celdas)
	idx += 1
	if idx < slots.size():
		texto_estado.text = "Coloca tu " + nombres[idx] + ". [R] Rotar."
	else:
		estado = "COMBATE"
		texto_estado.text = "¡A las armas! Ataca en la grilla derecha."
		generar_ia()

func generar_ia() -> void:
	for i in range(slots.size()):
		var nave = Nave.new(nombres[i], slots[i])
		var lista: Array[Vector2i] = []
		while lista.size() < slots[i]:
			lista.clear()
			var h = (randi() % 2 == 0)
			var o = Vector2i(randi() % 10, randi() % 10)
			for j in range(slots[i]):
				var c = Vector2i(o.x + j, o.y) if h else Vector2i(o.x, o.y + j)
				if c.x >= 10 or c.y >= 10 or tablero_enemigo.barcos.has(c): break
				lista.append(c)
		tablero_enemigo.colocar_nave_local(nave, lista)

func _on_click_enemigo(coord: Vector2i) -> void:
	if estado != "COMBATE" or tablero_enemigo.disparos.has(coord): return
	var res = tablero_enemigo.registrar_tiro(coord)
	texto_estado.text = "Tiro aliado: " + res
	if not tablero_enemigo.quedan_naves_vivas():
		texto_estado.text = "¡VICTORIA TOTAL!"
		estado = "FIN"
		return
	turno_ia()

func turno_ia() -> void:
	var listo = false
	var intentos = 0
	while not listo and intentos < 200:
		intentos += 1
		var c = Vector2i(randi() % 10, randi() % 10)
		if not tablero_jugador.disparos.has(c):
			var res = tablero_jugador.registrar_tiro(c)
			texto_estado.text = "La IA disparó en " + str(c) + ": " + res
			listo = true
	if not tablero_jugador.quedan_naves_vivas():
		texto_estado.text = "Derrota. Fin de la partida."
		estado = "FIN"
