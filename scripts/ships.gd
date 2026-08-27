# Nave.gd
class_name Nave
extends RefCounted

var nombre: String
var tamano: int
var celdas_ocupadas: Array[Vector2i] = []
var impactos: int = 0

func _init(p_nombre: String, p_tamano: int):
	nombre = p_nombre
	tamano = p_tamano

func registrar_impacto() -> bool:
	impactos += 1
	return impactos >= tamano # Devuelve TRUE si se hundió
