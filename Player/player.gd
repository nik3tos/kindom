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

@onready var anim = $AnimatedSprite2D
@onready var animPlayer = $AnimationPlayer
var health = 100
var gold = 0
var state = MOVE
var run_speed = 1
var combo = false
var attack_cooldown = false

func _ready():
	# Подключаем сигнал окончания анимации
	animPlayer.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	# Гравитация
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Логика падения (только если мы движемся, чтобы не сбивать анимацию атаки)
	if velocity.y > 0 and state == MOVE:
		animPlayer.play("Fall")
		
	# Смерть
	if health <= 0:
		health = 0
		set_physics_process(false) # Останавливаем физику при смерти
		animPlayer.play("Death")
		await animPlayer.animation_finished
		queue_free()
		get_tree().change_scene_to_file("res://menu.tscn")
		return

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
			
	if direction == -1:
		anim.flip_h = true
	elif direction == 1:
		anim.flip_h = false
		
	if Input.is_action_pressed("run"):
		run_speed = 2
	else:
		run_speed = 1
		
	if Input.is_action_pressed("block"):
		if velocity.x == 0:
			state = BLOCK
		else:
			state = SLIDE
			animPlayer.play("Slide") # Запускаем анимацию один раз при входе
			
	# ВОТ ЗДЕСЬ БЫЛА ОШИБКА
	if Input.is_action_just_pressed("attack") and attack_cooldown == false:
		start_attack(ATTACK, "Attack")
		

# Вспомогательная функция для старта атаки
func start_attack(new_state, anim_name):
	state = new_state
	velocity.x = 0
	animPlayer.play(anim_name)

func block_state():
	velocity.x = 0
	animPlayer.play("Block")
	if Input.is_action_just_released("block"):
		state = MOVE

func slide_state():
	# Логика обрабатывается через сигнал animation_finished
	pass

func attack_state():
	# Тут мы просто ждем ввода для комбо. Анимация уже играет.
	if Input.is_action_just_pressed("attack") and combo == true:
		start_attack(ATTACK2, "Attack2")
	attack_freeze()

func attack2_state():  
	if Input.is_action_just_pressed("attack") and combo == true:
		start_attack(ATTACK3, "Attack3")
	
func attack3_state():
	pass # Ждем окончания анимации

# Эта функция вызывается сама, когда любая анимация доигрывает до конца
func _on_animation_finished(anim_name):
	if anim_name == "Attack":
		state = MOVE
	elif anim_name == "Attack2":
		state = MOVE
	elif anim_name == "Attack3":
		state = MOVE
	elif anim_name == "Slide":
		state = MOVE

# Эту функцию нужно вызывать через AnimationPlayer (Add Track -> Call Method Track)
# в тех кадрах анимации, где разрешено комбо
func combo1():
	combo = true
	await animPlayer.animation_finished
	combo = false
	# Комбо открывается на короткое время, можно использовать таймер
	# или выключить его в конце анимации
func attack_freeze ():
	attack_cooldown = true
	await get_tree().create_timer(1).timeout
	attack_cooldown = false
