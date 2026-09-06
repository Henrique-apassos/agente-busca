extends Node3D

@export var grid_width: int = 50
@export var grid_depth: int = 50
@export var cell_spacing: float = 1.0
@export var elevation_scale: float = 0.25

@export var noise_scale: float = 0.25
@export_range(-1.0, 1.0) var water_level: float = -0.4
@export_range(-1.0, 1.0) var mud_level: float = 0.1

@export_range(-1.0, 1.0) var obstacle_threshold: float = 0.6
@export var obstacle_height: float = 1.0

var noise: FastNoiseLite
var obstacle_noise: FastNoiseLite
@onready var grid_visualizer = $GridVisualizer
var grid_logic = []

func _ready():
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = randi()

	obstacle_noise = FastNoiseLite.new()
	obstacle_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	obstacle_noise.seed = randi()

	generate_grid()

func generate_grid():
	var multi_mesh = grid_visualizer.multimesh
	multi_mesh.instance_count = grid_width * grid_depth

	for x in range(grid_width):
		grid_logic.append([])

		for z in range(grid_depth):
			var noise_val = noise.get_noise_2d(x * (1.0 / noise_scale), z * (1.0 / noise_scale))

			var terrain_type = ""
			var color = Color()
			var move_weight = 1.0
			var stepped_noise = snapped(noise_val, 0.1)
			var y_pos = stepped_noise * elevation_scale

			if noise_val < water_level:
				terrain_type = "water"
				y_pos = water_level * elevation_scale
				var depth = inverse_lerp(water_level, -1.0, noise_val)
				move_weight = lerp(3.0, 8.0, depth)
				color = Color("3b9ce2").lerp(Color("0f5b99"), depth)

			elif noise_val < mud_level:
				terrain_type = "mud"
				y_pos = noise_val * elevation_scale
				var wetness = inverse_lerp(mud_level, water_level, noise_val)
				move_weight = lerp(1.5, 4.0, wetness)
				color = Color("9b7661").lerp(Color("634533"), wetness)

			else:
				terrain_type = "grass"
				var height_curve = pow(noise_val, 3.0)
				y_pos = height_curve * elevation_scale
				move_weight = 1.0
				color = Color("53b34f")

			var obstacle_noise_val = obstacle_noise.get_noise_2d(x * (1.0 / noise_scale), z * (1.0 / noise_scale))
			var is_obstacle = obstacle_noise_val > obstacle_threshold
			if is_obstacle:
				terrain_type = "obstacle"
				move_weight = -1.0
				color = Color("808080")

			var cell_data = {
				"grid_pos": Vector2(x, z),
				"world_pos": Vector3(x * cell_spacing, y_pos, z * cell_spacing),
				"terrain": terrain_type,
				"weight": move_weight,
				"color": color, # <- guardamos a cor original pra poder restaurar depois
				"g_cost": 0,
				"h_cost": 0,
				"parent": null
			}
			grid_logic[x].append(cell_data)

			var index = x * grid_depth + z
			var cell_transform: Transform3D

			if is_obstacle:
				var scale_y = obstacle_height / 0.1
				var wall_basis = Basis().scaled(Vector3(1, scale_y, 1))
				var wall_y = y_pos + (obstacle_height / 2.0) - 0.05
				var wall_origin = Vector3(x * cell_spacing, wall_y, z * cell_spacing)
				cell_transform = Transform3D(wall_basis, wall_origin)
			else:
				cell_transform = Transform3D().translated(cell_data.world_pos)

			multi_mesh.set_instance_transform(index, cell_transform)
			multi_mesh.set_instance_color(index, color)

func get_random_valid_cell(exclude_grid_pos: Vector2 = Vector2(-1, -1), allowed_terrains: Array = []) -> Dictionary:
	var x: int
	var z: int
	var cell

	while true:
		x = randi() % grid_width
		z = randi() % grid_depth
		cell = grid_logic[x][z]

		if cell.terrain == "obstacle":
			continue
		if cell.grid_pos == exclude_grid_pos:
			continue
		if not allowed_terrains.is_empty() and not cell.terrain in allowed_terrains:
			continue

		break

	return cell

func get_grid_snapshot() -> Array:
	var flat = []
	for x in range(grid_width):
		for z in range(grid_depth):
			var cell = grid_logic[x][z]
			flat.append({
				"x": x,
				"z": z,
				"terrain": cell.terrain,
				"weight": cell.weight,
				"world_pos": cell.world_pos
			})
	return flat

# --- Funções de cor usadas na visualização da busca ---

func set_cell_color(x: int, z: int, color: Color):
	var index = x * grid_depth + z
	grid_visualizer.multimesh.set_instance_color(index, color)

func reset_cell_color(x: int, z: int):
	set_cell_color(x, z, grid_logic[x][z].color)

func darken_cell(x: int, z: int):
	set_cell_color(x, z, grid_logic[x][z].color.darkened(0.6))

func highlight_cell(x: int, z: int):
	set_cell_color(x, z, Color(1.0, 0.95, 0.3)) # destaque dourado

func reset_all_cell_colors():
	for x in range(grid_width):
		for z in range(grid_depth):
			reset_cell_color(x, z)
