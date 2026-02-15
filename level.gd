extends Node2D

@onready var darkness = $DirectionalLight2D
@onready var point_lights = [$PointLight2D, $PointLight2D2] 
@onready var day_text = $CanvasLayer/DayText
@onready var animPlayer = $CanvasLayer/AnimationPlayer
@onready var health_bar = $CanvasLayer/HealthBar
@onready var player_node = $Player/Player

enum {
	MORNING,
	DAY,
	EVENING,
	NIGHT
}

var state := MORNING
var day_count: int

func _ready():
	darkness.enabled = true
	day_count = 1
	set_day_text()
	# При старте сразу ставим утро
	change_state(MORNING)
	
	# Тот самый фрагмент, где могла закрасться ошибка:
	if player_node and health_bar:
		health_bar.value = player_node.health

# Вспомогательная функция для фонарей (без изменений)
func animate_lamps(tween: Tween, target_energy: float, duration: float):
	for lamp in point_lights:
		if is_instance_valid(lamp):
			tween.tween_property(lamp, "energy", target_energy, duration)

func change_state(new_state):
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	
	match new_state:
		MORNING:
			print("УТРО: Темнота уходит (0.2), фонари гаснут")
			# Было темно, становится светло. Значение стремится к 0.
			tween.tween_property(darkness, "energy", 0.2, 20)
			animate_lamps(tween, 0.0, 20) # Выключаем фонари

		DAY:
			print("ДЕНЬ: Светло (0.0), фонари выключены")
			# Полностью убираем темноту
			tween.tween_property(darkness, "energy", 0.0, 20)
			animate_lamps(tween, 0.0, 20)

		EVENING:
			print("ВЕЧЕР: Темнеет (0.6), включаем фонари")
			# Начинаем добавлять темноту
			tween.tween_property(darkness, "energy", 0.6, 20)
			animate_lamps(tween, 1.5, 20) # Включаем фонари

		NIGHT:
			print("НОЧЬ: Полная тьма (0.95)")
			# Максимальная темнота
			tween.tween_property(darkness, "energy", 0.95, 20) 
			animate_lamps(tween, 1.5, 20) # Фонари продолжают светить

func _on_day_night_timeout():
	if state < 3:
		state += 1
	else:
		state = MORNING
		day_count += 1
		set_day_text()
		set_text_fade()
	
	change_state(state)

func set_text_fade ():
	animPlayer.play("day_text_fade_in")
	await get_tree().create_timer(3).timeout
	animPlayer.play("day_text_fade_out")
	
func set_day_text ():
	day_text.text = "DAY" + str(day_count)
