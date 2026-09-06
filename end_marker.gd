extends MeshInstance3D

@export var float_amplitude: float = 0.2  # O quanto a esfera sobe e desce
@export var float_speed: float = 3.0      # Velocidade da levitação
@export var pulse_amplitude: float = 0.15 # O quanto ela "incha" (15% maior/menor)
@export var pulse_speed: float = 4.0      # Velocidade da batida do coração

var time_passed: float = 0.0
var base_y: float = 0.0
var base_scale: Vector3

func _ready():
	# Guarda o tamanho original para a pulsação não deformar a esfera
	base_scale = scale
	
	# Aguarda o GridManager posicionar a esfera na altura correta do terreno
	await get_tree().process_frame
	base_y = global_position.y

func _process(delta):
	time_passed += delta
	
	if base_y != 0.0:
		# 1. Efeito de Levitação (Sobe e Desce)
		global_position.y = base_y + (sin(time_passed * float_speed) * float_amplitude)
		
		# 2. Efeito de Pulsação (Cresce e Encolhe)
		# Usamos sin() para criar um multiplicador que vai de 0.85 até 1.15
		var current_pulse = 1.0 + (sin(time_passed * pulse_speed) * pulse_amplitude)
		scale = base_scale * current_pulse
