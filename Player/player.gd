extends CharacterBody2D

enum {
	MOVE,
	ATTACK,
	ATTACK2,
	ATTACK3,
	BLOCK,
	SLIDE
}

const SPEED = 150.0
const JUMP_VELOCITY = -400.0

# --- ПЕРЕМЕННЫЕ ---
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var gold = 0:
	set(value):
    	gold = value
    	update_gold_ui() 
var state = MOVE
var run_speed = 1
var combo = false
var attack_cooldown = false
var is_invincible = false
# Параметры выносливости
var stamina = 100.0
var max_stamina = 100.0
var stamina_regen = 25.0 # Скорость восстановления

var health = 100:
	set(value):
		health = clamp(value, 0, 100)
		update_health_bar()

# --- ССЫЛКИ НА УЗЛЫ ---
@onready var anim = $AnimatedSprite2D
@onready var animPlayer = $AnimationPlayer
@onready var sword_area_col = $SwordArea/CollisionShape2D 

func _ready():
	animPlayer.animation_finished.connect(_on_animation_finished)
	update_health_bar()
	update_gold_ui()
	
	if sword_area_col:
		sword_area_col.disabled = true

func _physics_process(delta: float) -> void:
	# 1. Восстановление выносливости
	stamina = clamp(stamina + stamina_regen * delta, 0, max_stamina)
	update_stamina_bar() # Обновляем UI каждый кадр

	# 2. Гравитация (исправлено: убран дубль)
	if not is_on_floor():
		velocity.y += gravity * delta

	# 3. Логика падения
	if velocity.y > 0 and state == MOVE:
		animPlayer.play("Fall")
		
	# 4. Смерть
	if health <= 0:
		die()
		return

	# 5. Машина состояний
	match state:
		MOVE:
			move_state()
		ATTACK:
			attack_state()
		ATTACK2:
			attack2_state()
		ATTACK3:
			attack3_state()
		BLOCK:
			block_state()
		SLIDE:
			slide_state()
	
	move_and_slide()

# --- СОСТОЯНИЯ ---

func move_state():
	var direction := Input.get_axis("left", "right")
	
	if direction:
		velocity.x = direction * SPEED * run_speed
		if velocity.y == 0:
			animPlayer.play("Walk" if run_speed == 1 else "Run")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if velocity.y == 0:
			animPlayer.play("Idle")
			
	# Поворот
	if direction != 0:
		anim.flip_h = (direction == -1)
		$SwordArea.scale.x = direction
		
	# Бег
	run_speed = 2 if Input.is_action_pressed("run") else 1
		
	# Блок и Слайд
	if Input.is_action_pressed("block"):
		if velocity.x == 0:
			state = BLOCK
		else:
			state = SLIDE
			animPlayer.play("Slide")
			
	# Атака (Расход стамины: 20)
	if Input.is_action_just_pressed("attack") and not attack_cooldown:
		if stamina >= 20:
			stamina -= 20
			start_attack(ATTACK, "Attack")
		else:
			print("Мало выносливости!")

func start_attack(new_state, anim_name):
	state = new_state
	velocity.x = 0
	animPlayer.play(anim_name)
	if sword_area_col:
		sword_area_col.disabled = false

func attack_state():
	if Input.is_action_just_pressed("attack") and combo:
		if stamina >= 15: # Комбо стоит чуть меньше
			stamina -= 15
			start_attack(ATTACK2, "Attack2")

func attack2_state():  
	if Input.is_action_just_pressed("attack") and combo:
		if stamina >= 15:
			stamina -= 15
			start_attack(ATTACK3, "Attack3")

func attack3_state():
	pass

func block_state():
	velocity.x = 0
	animPlayer.play("Block")
	if Input.is_action_just_released("block"):
		state = MOVE

func slide_state():
	# Логика скольжения (можно добавить постепенное замедление)
	pass

# --- СИГНАЛЫ И UI ---

func _on_animation_finished(anim_name):
	if sword_area_col:
		sword_area_col.disabled = true

	if anim_name in ["Attack", "Attack2", "Attack3", "Slide", "Take Hit"]:
		state = MOVE

func take_damage(amount: int, enemy_pos: Vector2):
	# Если здоровье 0 или игрок сейчас неуязвим — выходим
	if health <= 0 or is_invincible: 
		return
	
	# Включаем неуязвимость
	is_invincible = true
	health -= amount
	
	# Отбрасывание
	var knockback_direction = (global_position - enemy_pos).normalized()
	velocity = knockback_direction * 400 
	# Принудительно вызываем движение для отброса, 
	# так как в MOVE состоянии velocity перетирается вводом
	move_and_slide() 
	
	# Визуальный эффект (мигание)
	var tween = create_tween()
	# Делаем персонажа красным и полупрозрачным
	tween.tween_property(anim, "modulate", Color(1, 0, 0, 0.5), 0.1)
	tween.tween_property(anim, "modulate", Color.WHITE, 0.1)
	
	animPlayer.play("Take Hit")

	# Ждем 0.5 секунды (длительность неуязвимости)
	await get_tree().create_timer(0.5).timeout
	
	# Выключаем неуязвимость
	is_invincible = false

func update_health_bar():
	var bar = get_tree().current_scene.find_child("HealthBar", true, false)
	if bar:
		bar.value = health

func update_gold_ui():
  # Ищем наш новый текст в интерфейсе
	var label = get_tree().current_scene.find_child("GoldText", true, false)
	if label:
    	label.text = gold

func update_stamina_bar():
	var bar = get_tree().current_scene.find_child("StaminaBar", true, false)
	if bar:
		bar.value = stamina

func die():
	set_physics_process(false)
	animPlayer.play("Death")
	await animPlayer.animation_finished
	get_tree().change_scene_to_file("res://menu.tscn")

# Коллбэки для AnimationPlayer (функции-события внутри анимаций)
func combo1():
	combo = true
	await animPlayer.animation_finished
	combo = false

func attack_freeze():
	attack_cooldown = true
	await get_tree().create_timer(0.5).timeout
	attack_cooldown = false

func _on_sword_area_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and body != self:
		body.take_damage(20)
