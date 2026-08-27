class_name Dashboard 
extends GridContainer

const TAMANO_TABLERO = 10
const TAMANO_CELDA = 48 

var barcos: Dictionary = {}        # Vector2i -> Nave
var disparos: Dictionary = {}      # Vector2i -> String
var lista_naves: Array = []        
var es_enemigo: bool = false       

var matriz_botones: Dictionary = {}
var textura_solida: GradientTexture2D

func _init() -> void:
	var gradiente = Gradient.new()
	gradiente.offsets = [0.0, 1.0]
	gradiente.colors = [Color.WHITE, Color.WHITE]
	
	textura_solida = GradientTexture2D.new()
	textura_solida.gradient = gradiente
	textura_solida.width = TAMANO_CELDA
	textura_solida.height = TAMANO_CELDA

func limpiar_tablero() -> void:
	barcos.clear()
	disparos.clear()
	lista_naves.clear()
	matriz_botones.clear()
	columns = TAMANO_TABLERO
	for hijo in get_children():
		hijo.queue_free()

func registrar_boton_matriz(coord: Vector2i, boton: TextureButton) -> void:
	matriz_botones[coord] = boton

func colocar_nave_local(nave: Object, celdas: Array[Vector2i]) -> void:
	if "celdas_ocupadas" in nave:
		nave.celdas_ocupadas = celdas
		
	for coord in celdas:
		barcos[coord] = nave
		if not es_enemigo and matriz_botones.has(coord):
			var boton = matriz_botones[coord] as TextureButton
			boton.texture_normal = textura_solida
			boton.texture_disabled = textura_solida
			boton.texture_focused = textura_solida
			boton.modulate = Color(0.0, 0.354, 0.0, 1.0) 
			boton.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
			
	lista_naves.append(nave)

func registrar_tiro(coordenada: Vector2i) -> String:
	if disparos.has(coordenada):
		return "YA_DISPARADO"
		
	if not matriz_botones.has(coordenada):
		return "ERROR"
		
	var boton_objetivo = matriz_botones[coordenada] as TextureButton
	boton_objetivo.texture_normal = textura_solida
	boton_objetivo.texture_disabled = textura_solida
	boton_objetivo.texture_focused = textura_solida
		
	if barcos.has(coordenada):
		disparos[coordenada] = "TOCADO"
		boton_objetivo.modulate = Color(0.423, 0.0, 0.0, 1.0) 
		boton_objetivo.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
		
		var nave = barcos[coordenada]
		var hundido = false
		if nave.has_method("registrar_impacto"):
			hundido = nave.registrar_impacto()
		elif "impactos" in nave:
			nave.impactos += 1
			if "tamano" in nave and nave.impactos >= nave.tamano:
				hundido = true
			elif "tamaño" in nave and nave.impactos >= nave.tamaño:
				hundido = true
		
		var nombre_nave = nave.nombre if "nombre" in nave else "Barco"
		if hundido:
			return "¡HUNDIDO (" + nombre_nave + ")!"
		return "¡TOCADO!"
	else:
		disparos[coordenada] = "AGUA"
		boton_objetivo.modulate = Color(0.0, 0.318, 0.466, 1.0)
		boton_objetivo.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
		return "AGUA"

func quedan_naves_vivas() -> bool:
	for nave in lista_naves:
		var impactos = nave.impactos if "impactos" in nave else 0
		var tamano = nave.tamano if "tamano" in nave else (nave.tamaño if "tamaño" in nave else 1)
		if impactos < tamano:
			return true
	return false
