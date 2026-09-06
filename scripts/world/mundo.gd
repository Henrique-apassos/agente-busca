extends Node3D

@onready var free_camera = $Camera3D
@onready var top_camera = $TopCamera
@onready var camera_label = $HUD/CameraLabel
@onready var algorithm_label = $HUD/AlgorithmLabel
@onready var status_label = $HUD/StatusLabel
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
	agente.connect("MovementFinished", _on_movement_finished)

	algorithm_label.text = "Algoritmo: %s" % agente.GetAlgorithmName()
	status_label.text = "Pronto (F: buscar | G: seguir | B: trocar algoritmo)"

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
	grid_manager.reset_all_cell_colors() # limpa destaque de uma busca anterior
	agente.RunPathfinding()

func cycle_algorithm():
	agente.CycleAlgorithm()
	algorithm_label.text = "Algoritmo: %s" % agente.GetAlgorithmName()

func _on_search_completed(algorithm_name: String, visited: Array, path: Array, found: bool):
	algorithm_label.text = "Algoritmo: %s" % algorithm_name
	await animate_visited(visited)

	grid_manager.reset_all_cell_colors()

	if found:
		for cell in path:
			grid_manager.highlight_cell(cell.x, cell.y)
		status_label.text = "Caminho encontrado! (G para seguir)"
	else:
		status_label.text = "Nenhum caminho encontrado."

func animate_visited(visited: Array) -> void:
	for cell in visited:
		grid_manager.darken_cell(cell.x, cell.y)
		await get_tree().create_timer(visited_animation_delay).timeout

func _on_movement_finished():
	status_label.text = "Agente chegou! (F para buscar de novo)"

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
