extends Node3D

@onready var free_camera = $Camera3D
@onready var top_camera = $TopCamera
@onready var camera_label = $HUD/InfoPanel/CameraLabel
@onready var algorithm_label = $HUD/InfoPanel/AlgorithmLabel
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
var path_found: bool = false
var cancel_requested: bool = false
var restart_requested: bool = false
var foods_collected: int = 0

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
	status_label.text = "Pronto (F: buscar | G: seguir | B: trocar algoritmo | T: reiniciar teste)"
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
			KEY_T:
				reset_to_initial_state()

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
	agente.FollowPath()

func cycle_algorithm():
	agente.CycleAlgorithm()
	algorithm_label.text = "Algoritmo: %s" % agente.GetAlgorithmName()

func reset_to_initial_state():
	cancel_requested = true
	restart_requested = false

	agente.ResetToPosition(initial_agent_position)
	end_marker.global_position = initial_goal_position
	end_marker.visible = true
	end_marker_grid_pos = initial_goal_grid_pos

	grid_manager.reset_all_cell_colors()

	is_searching = false
	path_found = false
	foods_collected = 0
	food_count_label.text = "Comidas coletadas: 0"

	algorithm_label.text = "Algoritmo: %s" % agente.GetAlgorithmName()
	status_label.text = "Teste reiniciado — mesmo mapa/início/fim (F: buscar)"
	search_metrics_label.text = ""
	movement_metrics_label.text = ""

func _on_search_completed(algorithm_name: String, visited: Array, path: Array, found: bool, search_time_ms: float, _path_weight: float):
	algorithm_label.text = "Algoritmo: %s" % algorithm_name
	await animate_visited(visited)

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

	search_metrics_label.text = "Tempo real do algoritmo: %.3f ms | Nós visitados: %d" % [search_time_ms, visited.size()]

	path_found = found
	is_searching = false

func animate_visited(visited: Array) -> void:
	var start_ticks = Time.get_ticks_msec()
	var count = 0
	for cell in visited:
		if cancel_requested:
			break
		count += 1
		grid_manager.darken_cell(cell.x, cell.y)
		var elapsed_sec = (Time.get_ticks_msec() - start_ticks) / 1000.0
		search_metrics_label.text = "Visualizando exploração: %.2fs (%d/%d nós)" % [elapsed_sec, count, visited.size()]
		await get_tree().create_timer(visited_animation_delay).timeout

func _on_movement_progress(elapsed_ms: float, weight_so_far: float):
	movement_metrics_label.text = "Movendo... tempo: %.2fs | peso percorrido: %.2f" % [elapsed_ms / 1000.0, weight_so_far]

func _on_movement_finished(elapsed_ms: float, weight_so_far: float):
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
