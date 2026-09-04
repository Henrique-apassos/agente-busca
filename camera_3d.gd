extends Camera3D

@export var base_speed: float = 20.0 # Velocidade aumentada!
@export var sprint_multiplier: float = 3.0
@export var mouse_sensitivity: float = 0.002
var initial_transform: Transform3D

func _ready():
	initial_transform = global_transform
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	# Solta o mouse ao apertar ESC, e prende de novo se clicar com o botão esquerdo
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Rotação da câmera
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		
		var pitch = rotation.x - event.relative.y * mouse_sensitivity
		rotation.x = clamp(pitch, deg_to_rad(-90), deg_to_rad(90))

func _process(delta):
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return

	# Resetar câmera
	if Input.is_physical_key_pressed(KEY_R):
		global_transform = initial_transform

	# 1. Movimento 2D (Plano XZ) com WASD
	var input_2d = Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W): input_2d.y -= 1
	if Input.is_physical_key_pressed(KEY_S): input_2d.y += 1
	if Input.is_physical_key_pressed(KEY_A): input_2d.x -= 1
	if Input.is_physical_key_pressed(KEY_D): input_2d.x += 1
	
	input_2d = input_2d.normalized()

	# Rotação do vetor no plano horizontal
	var yaw = global_transform.basis.get_euler().y
	var move_dir = Vector3(input_2d.x, 0, input_2d.y).rotated(Vector3.UP, yaw)

	# 2. Movimento Vertical Global (Y)
	if Input.is_physical_key_pressed(KEY_SPACE): 
		move_dir.y += 1
	if Input.is_physical_key_pressed(KEY_CTRL): 
		move_dir.y -= 1

	# 3. Gerenciamento de Velocidade (Sprint com Shift)
	var current_speed = base_speed
	if Input.is_physical_key_pressed(KEY_SHIFT):
		current_speed *= sprint_multiplier

	# 4. Aplica a posição no mundo
	global_position += move_dir * current_speed * delta
