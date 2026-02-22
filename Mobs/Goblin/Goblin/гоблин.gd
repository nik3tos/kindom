extends CharacterBody2D

# --- НАСТРОЙКИ ---
var speed = 115          # Скорость бега
var health = 60          # Здоровье гоблина
var damage = 20          # Урон гоблина
var attack_cooldown = false
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# --- СОСТОЯНИЯ ---
var chase = false        # Видит ли игрока?
var player_in_range = false # Достаточно ли близко для удара?
var alive = true

@onready var anim = $AnimatedSprite2D

func _physics_process(delta):
	# Гравитация
	if not is_on_floor():
		velocity.y += gravity * delta

	# Если мертв — ничего не делаем
	if not alive:
		return

	var player = get_tree().get_first_node_in_group("player")

	if player:
		# Логика поведения
		if player_in_range and not attack_cooldown:
			# 1. Игрок близко -> АТАКУЕМ
			velocity.x = 0
			attack_player()
		
		elif chase and not anim.animation == "Attack":
			# 2. Игрок далеко, но мы его видим -> БЕЖИМ
			var direction = (player.global_position - self.global_position).normalized()
			
			# Поворот спрайта (вместе с зоной атаки!)
			if direction.x > 0:
				anim.flip_h = false # Вправо
				$AttackRange.scale.x = 1 # Зона атаки справа
			else:
				anim.flip_h = true # Влево
				$AttackRange.scale.x = -1 # Зона атаки слева
			
			velocity.x = direction.x * speed
			anim.play("Run")
			
		elif not chase and not anim.animation == "Attack":
			# 3. Потеряли игрока -> СТОИМ
			velocity.x = 0
			anim.play("Idle")
	
	move_and_slide()

# --- АТАКА ---
func attack_player():
	if not alive: return
	
	attack_cooldown = true
	anim.play("Attack")
	
	# Ждем момент удара (подберите время под вашу анимацию, например 0.5 сек)
	await get_tree().create_timer(0.4).timeout
	
	# Проверяем, все ли еще игрок в зоне поражения
	if player_in_range and alive:
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("take_damage"): # Если у игрока есть функция урона (в player.gd её нужно добавить!)
			player.take_damage(damage, global_position) # Наносим урон
			print("Гоблин ударил игрока!")
	
	# Ждем конца анимации
	await anim.animation_finished
	attack_cooldown = false
	# После атаки возвращаемся в Idle, чтобы цикл повторился
	if alive:
		anim.play("Idle")

# --- ПОЛУЧЕНИЕ УРОНА (ЧТОБЫ ЕГО МОЖНО БЫЛО УБИТЬ) ---
func take_damage(amount):
	if not alive: return
	
	health -= amount
	print("Гоблин получил урон! Осталось: ", health)
	
	# Эффект отбрасывания (опционально)
	velocity.y = -100
	
	if health <= 0:
		die()
	else:
		anim.play("Take Hit")
		# Небольшая пауза, чтобы проигралась анимация боли
		await anim.animation_finished
		if alive: anim.play("Idle")

func die():
	alive = false
	velocity.x = 0
	anim.play("Death")
	# Отключаем физику
	$CollisionShape2D.set_deferred("disabled", true)
	$AttackRange/CollisionShape2D.set_deferred("disabled", true)
	$Detector/CollisionShape2D.set_deferred("disabled", true)
	
	await anim.animation_finished
	queue_free()

# --- СИГНАЛЫ (НЕ ЗАБУДЬТЕ ПОДКЛЮЧИТЬ!) ---

# Зона обнаружения (Detector)
func _on_detector_body_entered(body):
	if body.is_in_group("player"):
		chase = true

func _on_detector_body_exited(body):
	if body.is_in_group("player"):
		chase = false

# Зона атаки (AttackRange) - НОВЫЕ СИГНАЛЫ
func _on_attack_range_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true

func _on_attack_range_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
