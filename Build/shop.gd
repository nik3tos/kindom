extends Area2D

var player_inside: bool = false
var gold: int = 0

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _process(delta: float) -> void:
	pass

func _input(event):
	if event.is_action_pressed("interact") and player_inside:
		if gold >= 50:
			gold -= 50
			# Вылечить игрока или дать бонус
			print("Покупка выполнена!")

func _on_area_entered(area):
	if area.name == "Player":
		player_inside = true

func _on_area_exited(area):
	if area.name == "Player":
		player_inside = false
