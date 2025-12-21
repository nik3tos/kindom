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

func _physics_process(delta: float) -> void:
	match state:
		MOVE:
			move_state()
		ATTACK:
			pass
		ATTACK2:
			pass
		ATTACK3:
			pass
		BLOCK:
			block_state()
		SLIDE:
			slide_state()
	
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	if velocity.y > 0:
		animPlayer.play("Fall")
		
	if health <= 0:
		health = 0
		animPlayer.play("Death")
		await animPlayer.animation_finished
		queue_free()
		get_tree().change_scene_to_file("res://menu.tscn")

	move_and_slide()

func move_state ():
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
		
func block_state ():
	velocity.x = 0
	animPlayer.play("Block")
	if Input.is_action_just_released("block"):
		state = MOVE

func slide_state():
	animPlayer.play("Slide")
	await animPlayer.animation_finished
	state = MOVE
