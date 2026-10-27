extends Node3D

# Deve bater com o enum SearchStepType do PathfindingResult.cs
# Deve bater com o enum SearchStepType do PathfindingResult.cs
const STEP_FRONTIER_ADDED := 0
const STEP_EXPANDED := 1
const STEP_GEN_START := 2
const STEP_IND_START := 3
const STEP_IND_STEP := 4
const STEP_GEN_BEST_PATH := 5
const STEP_GEN_END := 6

@onready var free_camera = $Camera3D
@onready var top_camera = $TopCamera
@onready var camera_label = $HUD/InfoPanel/CameraLabel
@onready var algorithm_label = $HUD/InfoPanel/AlgorithmLabel
@onready var nivel_label = $HUD/InfoPanel/NivelLabel
@onready var status_label = $HUD/InfoPanel/StatusLabel
@onready var search_metrics_label = $HUD/InfoPanel/SearchMetricsLabel
@onready var movement_metrics_label = $HUD/InfoPanel/MovementMetricsLabel
@onready var food_count_label = $HUD/FoodCountLabel
@onready var grid_manager = $GridManager
@onready var end_marker = $EndMarker
@onready var agente = $Agente

var using_free_camera: bool = true
var end_marker_grid_pos: Vector2 = Vector2(-1, -1)
var visited_animation_delay: float = 0.01

var initial_agent_position: Vector3
var initial_goal_position: Vector3
var initial_goal_grid_pos: Vector2

var is_searching: bool = false
var is_moving: bool = false
var path_found: bool = false
var cancel_requested: bool = false
var restart_requested: bool = false
var foods_collected: int = 0
var show_frontier: bool = true

func _ready():
	free_camera.make_current()
	update_hud()
	place_end_marker()
	place_agent()

	initial_agent_position = agente.global_position
	initial_goal_position = end_marker.global_position
	initial_goal_grid_pos = end_marker_grid_pos

	agente.connect("SearchCompleted", _on_search_completed)
	agente.connect("MovementProgress", _on_movement_progress)
	agente.connect("MovementFinished", _on_movement_finished)
	agente.connect("FoodCollected", _on_food_collected)

	algorithm_label.text = "Algoritmo: %s" % agente.GetAlgorithmName()
	nivel_label.text = "Nível: %s" % grid_manager.nivel_atual
	status_label.text = "Pronto (F: buscar | G: seguir | B: trocar algoritmo | V: fronteira | T: reiniciar teste | N: mover comida | M: novo mapa | L: trocar nível | F11: tela cheia | Q: sair)"
	search_metrics_label.text = ""
	movement_metrics_label.text = ""
	food_count_label.text = "Comidas coletadas: 0"

func place_end_marker():
	var goal_cell = grid_manager.get_random_valid_cell()
	end_marker.global_position = goal_cell.world_pos + Vector3(0, 0.4, 0)
	end_marker_grid_pos = goal_cell.grid_pos

func place_agent():
	var agent_cell = grid_manager.get_random_valid_cell(end_marker_grid_pos, ["grass", "mud"])
	agente.global_position = agent_cell.world_pos + Vector3(0, 0.4, 0)

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_C:
				toggle_camera()
			KEY_F:
				start_search()
			KEY_G:
				try_follow_path()
			KEY_B:
				cycle_algorithm()
			KEY_V:
				toggle_frontier()
			KEY_T:
				reset_to_initial_state()
			KEY_N:
				relocate_food()
			KEY_M:
				trocar_mapa()
			KEY_L:
				trocar_mapa(grid_manager.proximo_nivel())
			KEY_F11:
				toggle_fullscreen()
			KEY_Q:
				get_tree().quit()

func toggle_frontier():
	show_frontier = !show_frontier
	status_label.text = "Fronteira: %s (vale a partir da próxima busca)" % ("visível" if show_frontier else "oculta")

func start_search():
	if is_searching:
		cancel_requested = true
		restart_requested = true
		status_label.text = "Cancelando busca anterior..."
		return
	_begin_search()

func _begin_search():
	is_searching = true
	path_found = false
	cancel_requested = false
	status_label.text = "Buscando caminho..."
	search_metrics_label.text = ""
	movement_metrics_label.text = ""
	grid_manager.reset_all_cell_colors()
	grid_manager.clear_path_border()
	agente.RunPathfinding()

func try_follow_path():
	if is_searching:
		status_label.text = "Aguarde a busca terminar antes de mover (G)"
		return
	if not path_found:
		status_label.text = "Nenhum caminho encontrado ainda. Aperte F primeiro."
		return
	is_moving = true
	agente.FollowPath()

func cycle_algorithm():
	agente.CycleAlgorithm()
	algorithm_label.text = "Algoritmo: %s" % agente.GetAlgorithmName()

func relocate_food():
	if is_searching or is_moving:
		status_label.text = "Aguarde terminar antes de mover a comida."
		return
	place_end_marker()
	path_found = false
	grid_manager.reset_all_cell_colors()
	grid_manager.clear_path_border()
	status_label.text = "Comida reposicionada! (F: buscar)"

func trocar_mapa(nivel: String = grid_manager.nivel_atual):
	if is_searching or is_moving:
		status_label.text = "Aguarde terminar antes de trocar o mapa."
		return

	grid_manager.gerar_novo_mapa(nivel)
	agente.ResetToPosition(agente.global_position)
	place_end_marker()
	place_agent()
	end_marker.visible = true

	initial_agent_position = agente.global_position
	initial_goal_position = end_marker.global_position
	initial_goal_grid_pos = end_marker_grid_pos

	path_found = false
	nivel_label.text = "Nível: %s" % grid_manager.nivel_atual
	status_label.text = "Novo mapa (%s) gerado! (F: buscar | M: outro mapa | L: trocar nível)" % grid_manager.nivel_atual
	search_metrics_label.text = ""
	movement_metrics_label.text = ""

func reset_to_initial_state():
	cancel_requested = true
	restart_requested = false

	agente.ResetToPosition(initial_agent_position)
	end_marker.global_position = initial_goal_position
	end_marker.visible = true
	end_marker_grid_pos = initial_goal_grid_pos

	grid_manager.reset_all_cell_colors()

	is_searching = false
	is_moving = false
	path_found = false
	foods_collected = 0
	food_count_label.text = "Comidas coletadas: 0"

	algorithm_label.text = "Algoritmo: %s" % agente.GetAlgorithmName()
	status_label.text = "Teste reiniciado — mesmo mapa/início/fim (F: buscar)"
	search_metrics_label.text = ""
	movement_metrics_label.text = ""

func _on_search_completed(algorithm_name: String, visited: Array, path: Array, found: bool, search_time_ms: float, _path_weight: float, step_types: Array, step_positions: Array):
	algorithm_label.text = "Algoritmo: %s" % algorithm_name
	var max_frontier: int = await animate_steps(step_types, step_positions)

	grid_manager.reset_all_cell_colors()
	grid_manager.clear_path_border()

	if cancel_requested:
		is_searching = false
		path_found = false
		if restart_requested:
			restart_requested = false
			_begin_search()
		return

	if found:
		grid_manager.show_path_border(path)
		status_label.text = "Caminho encontrado! (G para seguir)"
	else:
		status_label.text = "Nenhum caminho encontrado."

	search_metrics_label.text = "Tempo real do algoritmo: %.3f ms | Nós visitados: %d | Fronteira máx.: %d" % [search_time_ms, visited.size(), max_frontier]

	path_found = found
	is_searching = false

# Reproduz a lista de passos gravada pelo algoritmo, na ordem:
#   FrontierAdded -> pinta a célula como fronteira (se ainda não foi expandida)
#   Expanded      -> escurece a célula e tira da fronteira
# A pausa de animação acontece só nas expansões, então a velocidade
# continua a mesma de antes. Retorna o maior tamanho que a fronteira atingiu.
func animate_steps(step_types: Array, step_positions: Array) -> int:
	if step_types.has(STEP_GEN_START):
		return await animate_genetic_steps(step_types, step_positions)

	var start_ticks = Time.get_ticks_msec()
	var frontier := {}  # células empurradas e ainda não expandidas (deduplicadas)
	var expanded := {}
	var max_frontier := 0
	var total_expanded := 0
	for t in step_types:
		if t == STEP_EXPANDED:
			total_expanded += 1
	var expanded_count := 0

	for i in range(step_types.size()):
		if cancel_requested:
			break

		var cell = step_positions[i]

		if step_types[i] == STEP_FRONTIER_ADDED:
			if not expanded.has(cell):
				frontier[cell] = true
				if show_frontier:
					grid_manager.frontier_cell(cell.x, cell.y)
				max_frontier = max(max_frontier, frontier.size())
		else:
			expanded[cell] = true
			frontier.erase(cell)
			grid_manager.darken_cell(cell.x, cell.y)
			expanded_count += 1

			var elapsed_sec = (Time.get_ticks_msec() - start_ticks) / 1000.0
			search_metrics_label.text = "Visualizando exploração: %.2fs (%d/%d nós) | Fronteira: %d" % [elapsed_sec, expanded_count, total_expanded, frontier.size()]
			await get_tree().create_timer(visited_animation_delay).timeout

	return max_frontier

func animate_genetic_steps(step_types: Array, step_positions: Array) -> int:
	# 1. Reconstrói os dados de cada geração gravados pelo C#
	var generations := []
	var current_gen := {}
	var current_ind_path := []
	var current_ind_status := 0

	for i in range(step_types.size()):
		var t: int = step_types[i]
		var pos: Vector2i = step_positions[i]

		match t:
			STEP_GEN_START:
				current_gen = {
					"gen": pos.x,
					"reached": pos.y,
					"individuals": [],
					"statuses": [],
					"best_path": [],
					"best_cost": 0.0,
					"pop_size": 0
				}
			STEP_IND_START:
				if not current_ind_path.is_empty():
					current_gen["individuals"].append(current_ind_path)
					current_gen["statuses"].append(current_ind_status)
				current_ind_path = []
				current_ind_status = pos.y
			STEP_IND_STEP:
				current_ind_path.append(pos)
			STEP_GEN_BEST_PATH:
				if not current_ind_path.is_empty():
					current_gen["individuals"].append(current_ind_path)
					current_gen["statuses"].append(current_ind_status)
					current_ind_path = []
				current_gen["best_path"].append(pos)
			STEP_GEN_END:
				if not current_ind_path.is_empty():
					current_gen["individuals"].append(current_ind_path)
					current_gen["statuses"].append(current_ind_status)
					current_ind_path = []
				current_gen["best_cost"] = pos.x / 10.0
				current_gen["pop_size"] = pos.y
				generations.append(current_gen)

	var total_gens := generations.size()
	var max_frontier := 0

	# 2. Anima geração por geração
	for g in generations:
		if cancel_requested:
			break

		grid_manager.reset_all_cell_colors()
		var individuals: Array = g["individuals"]
		var statuses: Array = g["statuses"]
		var pop_size: int = max(1, g["pop_size"])
		var visit_counts := {}

		var max_steps := 0
		for ind_path in individuals:
			if ind_path.size() > max_steps:
				max_steps = ind_path.size()

		# Avança os passos dos indivíduos da população simultaneamente (~10 frames por geração)
		var stride: int = max(1, int(ceil(float(max_steps) / 10.0)))

		for step_idx in range(max_steps):
			if cancel_requested:
				break

			var agent_positions := []
			var agent_statuses := []

			for ind_idx in range(individuals.size()):
				var ind_path: Array = individuals[ind_idx]
				if ind_path.is_empty():
					continue
				var clamped_idx: int = min(step_idx, ind_path.size() - 1)
				var cell: Vector2i = ind_path[clamped_idx]

				if step_idx < ind_path.size():
					visit_counts[cell] = visit_counts.get(cell, 0) + 1
					if show_frontier:
						grid_manager.heat_cell(cell.x, cell.y, visit_counts[cell], pop_size)

				agent_positions.append(cell)
				agent_statuses.append(statuses[ind_idx])

			if step_idx % stride == 0 or step_idx == max_steps - 1:
				if show_frontier:
					grid_manager.show_population_agents(agent_positions, agent_statuses)
				search_metrics_label.text = "Geração %d/%d | População: %d (%d chegaram) | Melhor custo: %.1f" % [
					g["gen"], total_gens, pop_size, g["reached"], g["best_cost"]
				]
				await get_tree().create_timer(0.015).timeout

		max_frontier = max(max_frontier, visit_counts.size())

		# Destaca o melhor caminho da geração com a moldura dourada
		if not g["best_path"].is_empty():
			grid_manager.show_path_border(g["best_path"])

		await get_tree().create_timer(0.07).timeout

	grid_manager.clear_population_agents()
	return max_frontier

func _on_movement_progress(elapsed_ms: float, weight_so_far: float):
	movement_metrics_label.text = "Movendo... tempo: %.2fs | peso percorrido: %.2f" % [elapsed_ms / 1000.0, weight_so_far]

func _on_movement_finished(elapsed_ms: float, weight_so_far: float):
	is_moving = false
	movement_metrics_label.text = "Tempo de movimentação: %.2fs | Peso percorrido: %.2f" % [elapsed_ms / 1000.0, weight_so_far]
	status_label.text = "Movimentação concluída (F: nova busca | T: reiniciar teste)"

func _on_food_collected():
	foods_collected += 1
	food_count_label.text = "Comida coletada: %d" % foods_collected
	status_label.text = "Comida coletada! Nova comida surgindo..."

	agente.ClearPath()
	path_found = false
	grid_manager.clear_path_border()

	end_marker.visible = false
	var food_area = end_marker.get_node("FoodArea")
	food_area.set_deferred("monitorable", false)

	grid_manager.reset_all_cell_colors()
	await get_tree().create_timer(0.5).timeout

	place_end_marker()
	end_marker.visible = true
	food_area.set_deferred("monitorable", true)

	status_label.text = "Nova comida! (F: buscar | B: trocar algoritmo)"

func toggle_fullscreen():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func toggle_camera():
	using_free_camera = !using_free_camera

	if using_free_camera:
		free_camera.make_current()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		top_camera.make_current()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	update_hud()

func update_hud():
	if using_free_camera:
		camera_label.text = "Câmera: Modo Livre (Voo)"
	else:
		camera_label.text = "Câmera: Visão Superior (Top-Down)"
