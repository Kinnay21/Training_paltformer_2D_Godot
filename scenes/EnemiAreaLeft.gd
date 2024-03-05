extends Area2D

@onready var character_body_2d_ennemi_1 = $".."

var is_area_right: bool = false

func _on_body_entered(body):
	if (body.name == "CharacterBody2D"):
#		print(1)
		character_body_2d_ennemi_1.running_mode(true, is_area_right)




func _on_body_exited(body):
	if (body.name == "CharacterBody2D"):
#		print(0)
		character_body_2d_ennemi_1.running_mode(false,is_area_right)

