extends Node2D

# UI节点引用
@onready var attack_button: Button = $UILayer/AttackButton
@onready var defend_button: Button = $UILayer/DefendButton
@onready var flee_button: Button = $UILayer/FleeButton
@onready var battle_log: Label = $UILayer/BattleLog

# 实体节点
@onready var player = $Player
@onready var enemy = $Enemy

# 战斗状态变量
var player_turn: bool = true
var is_defending: bool = false

# 血量系统配置
var player_max_hp: int = 100
var player_hp: int = 100
var enemy_max_hp: int = 80
var enemy_hp: int = 80

# 伤害区间（随机浮动）
var player_dmg_min: int = 20
var player_dmg_max: int = 30
var enemy_dmg_min: int = 15
var enemy_dmg_max: int = 25

func _ready():
	# 绑定按钮前先判断节点是否存在，避免空对象崩溃
	if attack_button != null:
		attack_button.pressed.connect(_on_attack)
	else:
		print("警告：找不到 AttackButton 按钮！")
	
	if defend_button != null:
		defend_button.pressed.connect(_on_defend)
	else:
		print("警告：找不到 DefendButton 按钮！")
	
	if flee_button != null:
		flee_button.pressed.connect(_on_flee)
	else:
		print("警告：找不到 FleeButton 按钮！")
	
	# 开局日志，显示双方初始血量
	add_log("战斗开始！")
	add_log(enemy.enemy_name + " 出现了！")
	add_log("你的血量：%d / %d" % [player_hp, player_max_hp])
	add_log(enemy.enemy_name + "血量：%d / %d" % [enemy_hp, enemy_max_hp])
	add_log("————————————————")

# 日志输出函数
func add_log(text: String) -> void:
	if battle_log != null:
		battle_log.text += text + "\n"

# 攻击按钮逻辑
func _on_attack() -> void:
	if !player_turn:
		add_log("现在不是你的回合！")
		return
	if enemy_hp <= 0:
		add_log("敌人已经被击败，无需再攻击！")
		return
	
	# 生成随机玩家伤害
	var player_attack_dmg = randi_range(player_dmg_min, player_dmg_max)
	add_log("你发起了攻击，造成 %d 点伤害！" % player_attack_dmg)
	enemy_hp -= player_attack_dmg
	
	# 判断敌人是否阵亡
	if enemy_hp <= 0:
		enemy_hp = 0
		add_log(enemy.enemy_name + "血量归零！你赢得了战斗！")
		add_log("————————————————")
		end_battle()
		return
	
	add_log(enemy.enemy_name + "剩余血量：%d / %d" % [enemy_hp, enemy_max_hp])
	add_log("————————————————")
	
	# 切换敌人回合
	player_turn = false
	await get_tree().create_timer(1.0).timeout
	_process_enemy_turn()

# 防御按钮逻辑
func _on_defend() -> void:
	if !player_turn:
		add_log("现在不是你的回合！")
		return
	if enemy_hp <= 0:
		add_log("战斗已经胜利，无需防御！")
		return
	
	is_defending = true
	add_log("你摆出防御姿态，本回合受到伤害减半！")
	add_log("————————————————")
	
	player_turn = false
	await get_tree().create_timer(1.0).timeout
	_process_enemy_turn()

# 逃跑按钮逻辑（带60%成功率）
func _on_flee() -> void:
	if !player_turn:
		add_log("现在不是你的回合！")
		return
	if enemy_hp <= 0:
		add_log("敌人已被击败，不用逃跑！")
		return
	
	add_log("你尝试逃跑...")
	var rand = randi_range(0, 100)
	if rand > 40:
		add_log("逃跑成功，脱离战斗！")
		add_log("————————————————")
		end_battle()
	else:
		add_log("逃跑失败！妖兽拦住了你！")
		add_log("————————————————")
		player_turn = false
		await get_tree().create_timer(1.0).timeout
		_process_enemy_turn()

# 敌人回合逻辑（防御减伤、随机伤害、玩家血量判定）
func _process_enemy_turn() -> void:
	add_log(enemy.enemy_name + " 发起攻击！")
	# 生成随机敌人伤害
	var enemy_attack_dmg = randi_range(enemy_dmg_min, enemy_dmg_max)
	var real_dmg = enemy_attack_dmg
	
	# 防御减半伤害
	if is_defending:
		real_dmg = enemy_attack_dmg / 2
		add_log("妖兽本次攻击伤害：%d，你的防御抵消一半，实际受到 %d 点伤害！" % [enemy_attack_dmg, real_dmg])
		is_defending = false
	else:
		add_log("妖兽本次攻击伤害：%d，你受到 %d 点伤害！" % [enemy_attack_dmg, real_dmg])
	
	player_hp -= real_dmg
	
	# 判断玩家是否阵亡
	if player_hp <= 0:
		player_hp = 0
		add_log("你的血量归零，战斗失败！")
		add_log("————————————————")
		end_battle()
		return
	
	add_log("你剩余血量：%d / %d" % [player_hp, player_max_hp])
	add_log("轮到你的行动！")
	add_log("————————————————")
	player_turn = true

# 结束战斗
func end_battle() -> void:
	# 战斗结束跳转回主菜单（取消注释即可启用）
	# get_tree().change_scene_to_file("res://MainMenu.tscn")
	pass
