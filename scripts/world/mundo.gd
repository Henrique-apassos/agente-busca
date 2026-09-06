extends Node3D

@onready var free_camera = $Camera3D
@onready var top_camera = $TopCamera
@onready var camera_label = $HUD/CameraLabel
@onready var grid_manager = $GridManager
@onready var end_marker = $EndMarker
@onready var agente = $Agente

var using_free_camera: bool = true
var end_marker_grid_pos: Vector2 = Vector2(-1, -1)

func _ready():
	free_camera.make_current()
	update_hud()
	place_end_marker()
	place_agent()

func place_end_marker():
	var goal_cell = grid_manager.get_random_valid_cell()
	end_marker.global_position = goal_cell.world_pos + Vector3(0, 0.4, 0)
	end_marker_grid_pos = goal_cell.grid_pos

func place_agent():
	# Só nasce em terreno seco: grama ou lama (nunca água, nem obstáculo)
	var agent_cell = grid_manager.get_random_valid_cell(end_marker_grid_pos, ["grass", "mud"])
	agente.global_position = agent_cell.world_pos + Vector3(0, 0.4, 0)

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C:
			toggle_camera()

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
