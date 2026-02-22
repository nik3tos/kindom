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

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# --- ПЕРЕМЕННЫЕ ---
var gold = 0  # Добавили золото
var state = MOVE
var run_speed = 1
var combo = false
var attack_cooldown = false
var health = 100:
	set(value):
		health = clamp(value, 0, 100)
		update_health_bar()

# --- ССЫЛКИ НА УЗЛЫ ---
@onready var anim = $AnimatedSprite2D
@onready var animPlayer = $AnimationPlayer
@onready var game_over_screen = get_tree().current_scene.find_child("GameOverScreen", true, false)
# Ссылка на зону меча. Если вы назвали узел по-другому, поправьте имя здесь!
@onready var sword_area_col = $SwordArea/CollisionShape2D 

func _ready():
	# Обязательно подключаем сигнал, иначе состояние не переключится назад!
	animPlayer.animation_finished.connect(_on_animation_finished)
	update_health_bar()
	
	# Сразу выключаем меч при старте
	if sword_area_col:
		sword_area_col.disabled = true

func _physics_process(delta: float) -> void:
	# Гравитация
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Логика падения
	if velocity.y > 0 and state == MOVE:
		animPlayer.play("Fall")
		
	# Смерть
	if health <= 0:
		health = 0
		set_physics_process(false)
		animPlayer.play("Death")
		await animPlayer.animation_finished
		queue_free()
		get_tree().change_scene_to_file("res://menu.tscn")
		return

	# Машина состояний
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

# --- ДВИЖЕНИЕ ---
func move_state():
	var direction := Input.get_axis("left", "right")
	
	if direction:
		velocity.x = direction * SPEED * run_speed
		if velocity.y == 0:
			if run_speed == 1:
				animPlayer.play("Walk")
			else:
				animPlayer.play("Run")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if velocity.y == 0:
			animPlayer.play("Idle")
			
	# Поворот персонажа и ЗОНЫ УДАРА
	if direction == -1:
		anim.flip_h = true
		$SwordArea.scale.x = -1 # Поворачиваем меч влево
	elif direction == 1:
		anim.flip_h = false
		$SwordArea.scale.x = 1  # Поворачиваем меч вправо
		
	if Input.is_action_pressed("run"):
		run_speed = 2
	else:
		run_speed = 1
		
	if Input.is_action_pressed("block"):
		if velocity.x == 0:
			state = BLOCK
		else:
			state = SLIDE
			animPlayer.play("Slide")
			
	# Атака
	if Input.is_action_just_pressed("attack") and attack_cooldown == false:
		start_attack(ATTACK, "Attack")

# --- АТАКА ---
func start_attack(new_state, anim_name):
	state = new_state
	velocity.x = 0
	animPlayer.play(anim_name)
	
	# ВКЛЮЧАЕМ МЕЧ
	if sword_area_col:
		sword_area_col.disabled = false

func attack_state():
	if Input.is_action_just_pressed("attack") and combo == true:
		start_attack(ATTACK2, "Attack2")

func attack2_state():  
	if Input.is_action_just_pressed("attack") and combo == true:
		start_attack(ATTACK3, "Attack3")
	
func attack3_state():
	pass

# --- ВЫХОД ИЗ АТАКИ (Самая важная часть) ---
func _on_animation_finished(anim_name):
	# ВЫКЛЮЧАЕМ МЕЧ
	if sword_area_col:
		sword_area_col.disabled = true

	# Возвращаем движение
	if anim_name == "Attack":
		state = MOVE
	elif anim_name == "Attack2":
		state = MOVE
	elif anim_name == "Attack3":
		state = MOVE
	elif anim_name == "Slide":
		state = MOVE

# --- ПРОЧЕЕ ---
func block_state():
	velocity.x = 0
	animPlayer.play("Block")
	if Input.is_action_just_released("block"):
		state = MOVE

func slide_state():
	pass

func combo1():
	combo = true
	await animPlayer.animation_finished
	combo = false

func attack_freeze():
	attack_cooldown = true
	await get_tree().create_timer(1).timeout
	attack_cooldown = false

func take_damage(amount: int, enemy_pos: Vector2):
	if health <= 0: return
	self.health -= amount
	var knockback_direction = (global_position - enemy_pos).normalized()
	velocity = knockback_direction * 400 
	move_and_slide()
	if anim:
		var tween = create_tween()
		tween.tween_property(anim, "modulate", Color.RED, 0.1)
		tween.tween_property(anim, "modulate", Color.WHITE, 0.1)
	animPlayer.play("Take Hit")

func update_health_bar():
	var bar = get_tree().current_scene.find_child("HealthBar", true, false)
	if bar:
		bar.value = health

func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()

# --- СИГНАЛ УДАРА МЕЧОМ ---
# Подключите сигнал body_entered от Area2D (SwordArea) к этому скрипту!
func _on_sword_area_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and body != self:
		body.take_damage(20) # Урон врагу
		print("Удар по: ", body.name)
