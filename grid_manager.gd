extends Node3D

@export var grid_width: int = 50
@export var grid_depth: int = 50
@export var cell_spacing: float = 1.0
@export var elevation_scale: float = 0.25 # Controla o quão alto o terreno pode chegar

# Controles de Geração (Aparecem no Inspetor)
@export var noise_scale: float = 0.25
@export_range(-1.0, 1.0) var water_level: float = -0.4 # Tudo abaixo disso vira água
@export_range(-1.0, 1.0) var mud_level: float = 0.1    # Tudo entre water_level e isso vira lama

var noise: FastNoiseLite
@onready var grid_visualizer = $GridVisualizer
var grid_logic = []

func _ready():
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = randi() 
	
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
			
			# LÓGICA DE BORDAS: Lemos do mais profundo para o mais raso
			if noise_val < water_level:
				# É ÁGUA (O núcleo mais profundo)
				terrain_type = "water"
				# Água fica plana (todas as células de água na mesma altura base)
				y_pos = water_level * elevation_scale
				# Calcula o quão profunda a água é (de 0 a 1)
				var depth = inverse_lerp(water_level, -1.0, noise_val)
				move_weight = lerp(3.0, 8.0, depth) 
				
				# Azul claro nas bordas, azul escuro no centro
				color = Color("3b9ce2").lerp(Color("0f5b99"), depth) 
				
			elif noise_val < mud_level:
				# É LAMA (A borda em volta da água, antes da grama)
				terrain_type = "mud"
				# Lama sobe gradualmente acompanhando o ruído
				y_pos = noise_val * elevation_scale
				
				# Calcula a umidade da lama (mais perto da água = mais úmido/pesado)
				# inverse_lerp aqui vai de mud_level (seco/0) até water_level (úmido/1)
				var wetness = inverse_lerp(mud_level, water_level, noise_val)
				move_weight = lerp(1.5, 4.0, wetness)
				
				# Marrom claro perto da grama, mais escuro/úmido perto da água
				color = Color("9b7661").lerp(Color("634533"), wetness) 
				
			else:
				# É GRAMA (O restante do mapa, parte mais alta/seca)
				terrain_type = "grass"
				# Grama sobe gradualmente acompanhando o ruído
				var height_curve = pow(noise_val, 3.0) 
				y_pos = height_curve * elevation_scale
				move_weight = 1.0
				# Um verde estilo pixel art
				color = Color("53b34f") 

			# SALVA NA MATRIZ LÓGICA
			var cell_data = {
				"grid_pos": Vector2(x, z),
				"world_pos": Vector3(x * cell_spacing, y_pos, z * cell_spacing),
				"terrain": terrain_type,
				"weight": move_weight, 
				"g_cost": 0,
				"h_cost": 0,
				"parent": null
			}
			grid_logic[x].append(cell_data)
			
			# APLICA AO VISUAL
			var index = x * grid_depth + z
			var cell_transform = Transform3D().translated(cell_data.world_pos)
			multi_mesh.set_instance_transform(index, cell_transform)
			multi_mesh.set_instance_color(index, color)
