extends CharacterBody2D

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var chase = false
var speed = 100
@onready var anim = $AnimatedSprite2D
var alive = true
@onready var animPlayer = $AnimationPlayer

# Состояния
var attacking = false
var player_in_range = false

func _ready():
	# Подключаем сигнал окончания анимации
	animPlayer.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var player = $"../../Player/Player"

	if alive:
		if attacking:
			# 1. Если атакуем - стоим на месте и ждем конца анимации
			velocity.x = 0

		elif player_in_range:
			# 2. Если не атакуем, но игрок рядом - НАЧИНАЕМ атаку
			start_attack()

		elif chase:
			# 3. Если игрок далеко, но мы его видим - бежим
			var direction = (player.position - self.position).normalized()
			velocity.x = direction.x * speed
			anim.play("Run")

			if direction.x < 0:
				anim.flip_h = true
			else:
				anim.flip_h = false
		else:
			# 4. Иначе стоим
			velocity.x = 0
			anim.play("Idel") # Используем Idel, так как у вас так названо в спрайтах

	move_and_slide()

# Функция запуска атаки
func start_attack():
	attacking = true
	animPlayer.play("Attack")
	velocity.x = 0

# Функция окончания анимации
func _on_animation_finished(anim_name):
	if anim_name == "Attack":
		# Атака закончилась. В следующем кадре physics_process решит:
		# снова бить (если player_in_range) или бежать (если chase)
		attacking = false

# --- СИГНАЛЫ ---

func _on_detector_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		chase = true

func _on_detector_body_exited(body: Node2D):
	if body.name == "Player":
		chase = false

func _on_attack_range_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = true

# ВАЖНО: Эту функцию нужно подключить через редактор (см. Шаг 2)
func _on_attack_range_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = false

# Смерть и урон
func _on_death_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.velocity.y -= 300
		death()

func _on_death_2_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		if alive:
			body.health -= 40
		death()

func death():
	alive = false
	anim.play("Death")
	await anim.animation_finished
	queue_free()
