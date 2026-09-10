extends Node3D

@onready var free_camera = $Camera3D
@onready var top_camera = $TopCamera
@onready var camera_label = $HUD/InfoPanel/CameraLabel
@onready var algorithm_label = $HUD/InfoPanel/AlgorithmLabel
@onready var status_label = $HUD/InfoPanel/StatusLabel
@onready var search_metrics_label = $HUD/InfoPanel/SearchMetricsLabel
@onready var movement_metrics_label = $HUD/InfoPanel/MovementMetricsLabel
@onready var grid_manager = $GridManager
@onready var end_marker = $EndMarker
@onready var agente = $Agente

var using_free_camera: bool = true
var end_marker_grid_pos: Vector2 = Vector2(-1, -1)
var visited_animation_delay: float = 0.01 # ajuste pra deixar a busca mais rápida/lenta de assistir

func _ready():
	free_camera.make_current()
	update_hud()
	place_end_marker()
	place_agent()

	agente.connect("SearchCompleted", _on_search_completed)
	agente.connect("MovementProgress", _on_movement_progress)
	agente.connect("MovementFinished", _on_movement_finished)

	algorithm_label.text = "Algoritmo: %s" % agente.GetAlgorithmName()
	status_label.text = "Pronto (F: buscar | G: seguir | B: trocar algoritmo)"
	search_metrics_label.text = ""
	movement_metrics_label.text = ""

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
				agente.FollowPath()
			KEY_B:
				cycle_algorithm()

func start_search():
	status_label.text = "Buscando caminho..."
	search_metrics_label.text = ""
	movement_metrics_label.text = ""
	grid_manager.reset_all_cell_colors() # limpa destaque de uma busca anterior
	agente.RunPathfinding()

func cycle_algorithm():
	agente.CycleAlgorithm()
	algorithm_label.text = "Algoritmo: %s" % agente.GetAlgorithmName()

func _on_search_completed(algorithm_name: String, visited: Array, path: Array, found: bool, search_time_ms: float, path_weight: float):
	algorithm_label.text = "Algoritmo: %s" % algorithm_name
	await animate_visited(visited)

	grid_manager.reset_all_cell_colors()

	if found:
		for cell in path:
			grid_manager.highlight_cell(cell.x, cell.y)
		status_label.text = "Caminho encontrado! (G para seguir)"
	else:
		status_label.text = "Nenhum caminho encontrado."

	search_metrics_label.text = "Tempo real do algoritmo: %.3f ms | Nós visitados: %d" % [search_time_ms, visited.size()]

func animate_visited(visited: Array) -> void:
	var start_ticks = Time.get_ticks_msec()
	var count = 0
	for cell in visited:
		count += 1
		grid_manager.darken_cell(cell.x, cell.y)
		var elapsed_sec = (Time.get_ticks_msec() - start_ticks) / 1000.0
		search_metrics_label.text = "Buscando... %.2fs | nós visitados: %d/%d" % [elapsed_sec, count, visited.size()]
		await get_tree().create_timer(visited_animation_delay).timeout

func _on_movement_progress(elapsed_ms: float, weight_so_far: float):
	movement_metrics_label.text = "Movendo... tempo: %.2fs | peso percorrido: %.2f" % [elapsed_ms / 1000.0, weight_so_far]

func _on_movement_finished(elapsed_ms: float, weight_so_far: float):
	status_label.text = "Agente chegou! Reposicionando objetivo..."
	movement_metrics_label.text = "Tempo de movimentação: %.2fs | Peso percorrido: %.2f" % [elapsed_ms / 1000.0, weight_so_far]

	# Faz a esfera do objetivo desaparecer visualmente
	end_marker.visible = false

	# Limpa o chão iluminado da busca anterior
	grid_manager.reset_all_cell_colors()

	# Pequena pausa pra dar a sensação clara de teletransporte
	await get_tree().create_timer(0.5).timeout

	# Sorteia um novo local aleatório no grid e move o marcador pra lá
	place_end_marker()

	# Faz a esfera reaparecer no novo local
	end_marker.visible = true

	status_label.text = "Novo alvo! (F: buscar | B: trocar algoritmo)"

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
