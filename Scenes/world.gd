extends Node2D

@export var chunk_size := 16
# Cell size * chunk size
@export var chunk_size_px := 256.0
@export var render_distance := 1
@export var noise_height_text : NoiseTexture2D
@export var max_chunk_memory := 15
var noise: Noise

var actual_chunk : Vector2i = Vector2i(-999, 999)
var loaded_chunk : Array[Vector2i] = []

@onready var water: TileMapLayer = $Water
@onready var grass: TileMapLayer = $Grass
@onready var hills: TileMapLayer = $Hills

func _ready() -> void:
	noise = noise_height_text.noise
	actual_chunk = get_chunk($Player.global_position)
	update_chunk(actual_chunk)
	
func _physics_process(_delta: float) -> void:
	chunk_process(get_chunk($Player.global_position))

func chunk_process(new_chunk: Vector2i) -> void:
	if actual_chunk != new_chunk:
		update_chunk(new_chunk)
		
func update_chunk(new_chunk: Vector2i):
	var neigh = get_neighbors(new_chunk, render_distance)
	for chunk in neigh:
		load_chunk(chunk, new_chunk)
	actual_chunk = new_chunk
	
		
func get_chunk(pos: Vector2) -> Vector2i:
	var x = pos.x / chunk_size_px
	var y = pos.y / chunk_size_px
	return Vector2(floor(x) if x < 0 else int(x), floor(y) if y < 0 else int(y))
	
func load_chunk(chunk: Vector2i, pos: Vector2i) -> void:
	if loaded_chunk.has(chunk):
		return
	if loaded_chunk.size() == max_chunk_memory:
		pop_furthest_point(loaded_chunk, pos)
	loaded_chunk.append(chunk)
	var hills_cells : Array[Vector2i] = []
	var grass_cells : Array[Vector2i] = []
	var water_cells : Array[Vector2i] = []
	for x in range(chunk_size * chunk.x, chunk_size * chunk.x + chunk_size):
		for y in range(chunk_size * chunk.y, chunk_size * chunk.y + chunk_size):
			var noise_val: float = noise.get_noise_2d(x, y)
			water_cells.append(Vector2i(x, y))
			if noise_val > 0.4:
				hills_cells.append(Vector2i(x, y))
			if noise_val > 0.2:
				grass_cells.append(Vector2i(x, y))
	apply_cells(hills_cells, grass_cells, water_cells)

func apply_cells(hills_cells: Array[Vector2i], grass_cells: Array[Vector2i], water_cells: Array[Vector2i]) -> void:
	for cell in water_cells:
		water.set_cell(cell, 0, Vector2i(0, 0))
	hills.set_cells_terrain_connect(hills_cells, 0, 0)
	grass.set_cells_terrain_connect(grass_cells, 0, 0)
	
func unload_chunk(chunk: Vector2) -> void:
		for x in range(chunk_size * chunk.x, chunk_size * chunk.x + chunk_size):
			for y in range(chunk_size * chunk.y, chunk_size * chunk.y + chunk_size):
				remove_cell(Vector2(x, y))
	
func get_neighbors(center: Vector2, distance: int) -> Array:
	var neighbors = []
	for x in range(-distance, distance + 1):
		for y in range(-distance, distance + 1):
			neighbors.append(center + Vector2(x, y))
	return neighbors

func remove_cell(pos: Vector2):
	water.erase_cell(pos)
	hills.erase_cell(pos)
	grass.erase_cell(pos)
	
func pop_furthest_point(points: Array, origin: Vector2i) -> Vector2i:
	var furthest_index := 0
	var max_distance := origin.distance_to(points[0])
	
	for i in range(1, points.size()):
		var dist = origin.distance_to(points[i])
		if dist > max_distance:
			max_distance = dist
			furthest_index = i
	
	unload_chunk(points[furthest_index])
	return points.pop_at(furthest_index)
