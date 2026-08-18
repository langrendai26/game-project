extends Node2D

@onready var player = $Player
@onready var meditate_button = $UILayer/MeditateButton
@onready var battle_button = $UILayer/BattleButton
@onready var equipment_button = $UILayer/EquipmentButton
@onready var inventory_button = $UILayer/InventoryButton
@onready var quest_button = $UILayer/QuestButton
@onready var shop_button = $UILayer/ShopButton
@onready var save_button = $UILayer/SaveButton
@onready var status_label = $UILayer/Label2

var quest_system: Node
var shop_system: Node
var save_system: Node

var current_panel: Node = null  # 跟踪当前打开的面板

func _ready():
	# 初始化系统
	init_systems()
	
	# 连接按钮信号
	meditate_button.connect("pressed", _on_meditate)
	battle_button.connect("pressed", _on_battle)
	equipment_button.connect("pressed", _on_equipment)
	inventory_button.connect("pressed", _on_inventory)
	quest_button.connect("pressed", _on_quest)
	shop_button.connect("pressed", _on_shop)
	save_button.connect("pressed", _on_save)
	
	update_status()


func close_current_panel():
	# 关闭当前打开的面板
	if current_panel != null:
		current_panel.queue_free()
		current_panel = null


func init_systems():
	# 任务系统
	quest_system = load("res://scripts/Quest.gd").new()
	add_child(quest_system)
	quest_system.add_to_group("quest")
	
	# 商店系统
	shop_system = load("res://scripts/Shop.gd").new()
	add_child(shop_system)
	shop_system.add_to_group("shop")
	
	# 存档系统
	save_system = load("res://scripts/SaveSystem.gd").new()
	add_child(save_system)
	
	# 玩家加入组
	player.add_to_group("player")


func _on_meditate():
	player.meditate()
	update_status()

func _on_battle():
	get_tree().change_scene_to_file("res://scripts/BattleScene.tscn")

func _on_equipment():
	close_current_panel()
	current_panel = load("res://scripts/EquipmentScene.tscn").instantiate()
	add_child(current_panel)

func _on_inventory():
	close_current_panel()
	current_panel = load("res://scripts/InventoryScene.tscn").instantiate()
	add_child(current_panel)

func _on_quest():
	close_current_panel()
	current_panel = load("res://scripts/QuestScene.tscn").instantiate()
	add_child(current_panel)

func _on_shop():
	close_current_panel()
	current_panel = load("res://scripts/ShopScene.tscn").instantiate()
	add_child(current_panel)

func _on_save():
	if save_system.save_game(0):
		status_label.text = "存档成功!"
	else:
		status_label.text = "存档失败!"

func _on_load():
	if save_system.load_game(0):
		status_label.text = "读档成功!"
		update_status()
	else:
		status_label.text = "读档失败!"

func update_status():
	status_label.text = "等级: " + str(player.level) + " | 境界: " + player.realm + "\n" + \
		"生命: " + str(player.current_health) + "/" + str(player.max_health) + "\n" + \
		"攻击: " + str(player.get_total_attack()) + " | 防御: " + str(player.get_total_defense()) + "\n" + \
		"灵力: " + str(player.spirit_power) + "/100  |  金币: " + str(shop_system.get_player_gold())
