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

	var player = $"../../Player/Player" # Тут используется прямой путь

	if alive:
		if attacking:
			# 1. Если атакуем - стоим на месте и ждем конца анимации
			velocity.x = 0

		elif player_in_range:
			# 2. Если не атакуем, но игрок рядом - НАЧИНАЕМ атаку
			start_attack()

		elif chase:
			# 3. Если игрок далеко, но мы его видим - бежим
			if player: # Проверка на всякий случай
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
			anim.play("Idel")

	move_and_slide()

# Функция запуска атаки
func start_attack():
	attacking = true
	animPlayer.play("Attack")
	velocity.x = 0

# Функция окончания анимации
func _on_animation_finished(anim_name):
	if anim_name == "Attack":
		attacking = false
		# Если в момент окончания анимации игрок все еще в зоне — наносим урон
		if player_in_range:
			damage_player()

# --- ИСПРАВЛЕННАЯ ЧАСТЬ ---
# Мы создали функцию, которой не хватало, и исправили отступы (используем Tab)
func damage_player():
	var player_node = get_tree().get_first_node_in_group("player_group")

	if player_node and player_node.has_method("take_damage"):
		print("Скелет нашел игрока через группу!")
		player_node.take_damage(10, global_position)
	else:
		print("ОШИБКА: Игрок не найден или не добавлен в группу 'player_group'")
# --------------------------

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
			# Проверка есть ли у игрока здоровье, чтобы не крашнулось
			if "health" in body:
				body.health -= 40
		death()

func death():
	alive = false
	anim.play("Death")
	await anim.animation_finished
	queue_free()
