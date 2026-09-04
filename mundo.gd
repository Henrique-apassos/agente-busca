extends Node3D

@onready var free_camera = $Camera3D
@onready var top_camera = $TopCamera
@onready var camera_label = $HUD/CameraLabel

var using_free_camera: bool = true

func _ready():
	# Garante que o jogo sempre inicie na câmera livre
	free_camera.make_current()
	update_hud()

func _input(event):
	# Detecta se apertou a tecla C (ignorando o ato de segurar a tecla)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C:
			toggle_camera()

func toggle_camera():
	using_free_camera = !using_free_camera
	
	if using_free_camera:
		free_camera.make_current()
		# Prende o mouse novamente para controlar o voo
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		top_camera.make_current()
		# Solta o mouse para você poder usar a tela (útil para clicar na UI depois)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
	update_hud()
	
func update_hud():
	if using_free_camera:
		camera_label.text = "Câmera: Modo Livre (Voo)"
	else:
		camera_label.text = "Câmera: Visão Superior (Top-Down)"
