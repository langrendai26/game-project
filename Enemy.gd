extends Node2D

# 敌人属性
@export var enemy_name = "妖兽"
@export var level = 1
@export var max_health = 50
@export var current_health = 50
@export var attack = 8
@export var defense = 3
@export var reward_exp = 20

func take_damage(damage):
	current_health -= damage - defense
	if current_health <= 0:
		current_health = 0
		print(enemy_name + " 被击败！")
		return true
	else:
		print(enemy_name + " 受到 " + str(damage - defense) + " 点伤害！")
		return false

func attack_player(player):
	var damage = attack
	print(enemy_name + " 攻击玩家，造成 " + str(damage) + " 点伤害！")
	player.take_damage(damage)
