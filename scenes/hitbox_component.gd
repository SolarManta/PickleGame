extends Area2D

@export var health_component : Node2D

func damage (attack: Attack):
	if health_component:
		health_component.damage(attack)
