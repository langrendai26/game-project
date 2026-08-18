extends Node

# 存档系统 - 使用 Godot Resource 保存
# 自动存档和手动存档支持

var save_path = "res://saves/"
var auto_save_interval = 300  # 5分钟自动存档一次

var current_save_slot = 0
var last_auto_save_time = 0
var is_save_in_progress = false

# 存档数据结构
class SaveData extends Resource:
	@export var player_data: Dictionary = {}
	@export var inventory_data: Dictionary = {}
	@export var quest_data: Dictionary = {}
	@export var shop_data: Dictionary = {}
	@export var skills_data: Dictionary = {}
	@export var alchemy_data: Dictionary = {}
	@export var map_data: Dictionary = {}
	@export var timestamp: String = ""
	@export var play_time: int = 0
	
	func _init():
		timestamp = Time.get_datetime_string_from_system()


func _ready():
	# 确保存档目录存在
	DirAccess.make_dir_recursive_absolute(save_path.get_base_dir())
	
	# 开始自动存档计时
	last_auto_save_time = Time.get_unix_time_from_system()


func _process(_delta):
	# 检查自动存档
	var current_time = Time.get_unix_time_from_system()
	if current_time - last_auto_save_time >= auto_save_interval:
		auto_save()
		last_auto_save_time = current_time


# 获取存档文件路径
func get_save_path(slot: int) -> String:
	return save_path + "save_" + str(slot) + ".tres"


# 检查存档是否存在
func save_exists(slot: int) -> bool:
	var path = get_save_path(slot)
	return FileAccess.file_exists(path)


# 获取存档信息（不加载完整数据）
func get_save_info(slot: int) -> Dictionary:
	if not save_exists(slot):
		return {}
	
	var resource = load(get_save_path(slot))
	if resource == null:
		return {}
	
	return {
		"timestamp": resource.timestamp,
		"play_time": resource.play_time,
		"player_level": resource.player_data.get("level", 1),
		"player_name": resource.player_data.get("name", "修士")
	}


# 保存游戏
func save_game(slot: int = 0) -> bool:
	if is_save_in_progress:
		print("存档正在进行中...")
		return false
	
	is_save_in_progress = true
	
	var save_data = SaveData.new()
	
	# 收集所有系统数据
	var player = get_tree().get_first_node_in_group("player")
	if player:
		save_data.player_data = player.get_save_data()
	
	var inventory = get_tree().get_first_node_in_group("inventory")
	if inventory:
		save_data.inventory_data = inventory.get_save_data()
	
	var quest = get_tree().get_first_node_in_group("quest")
	if quest:
		save_data.quest_data = quest.get_save_data()
	
	var shop = get_tree().get_first_node_in_group("shop")
	if shop:
		save_data.shop_data = shop.get_save_data()
	
	var skills = get_tree().get_first_node_in_group("skills")
	if skills:
		save_data.skills_data = skills.get_save_data()
	
	var alchemy = get_tree().get_first_node_in_group("alchemy")
	if alchemy:
		save_data.alchemy_data = alchemy.get_save_data()
	
	var map_node = get_tree().get_first_node_in_group("map")
	if map_node:
		save_data.map_data = map_node.get_save_data()
	
	# 添加时间戳
	save_data.timestamp = Time.get_datetime_string_from_system()
	
	# 使用 ResourceSaver 保存
	var path = get_save_path(slot)
	var error = ResourceSaver.save(save_data, path)
	
	is_save_in_progress = false
	
	if error == OK:
		print("存档成功: " + path)
		current_save_slot = slot
		return true
	else:
		print("存档失败: 错误码 " + str(error))
		return false


# 加载游戏
func load_game(slot: int = 0) -> bool:
	var path = get_save_path(slot)
	
	if not save_exists(slot):
		print("存档不存在: " + path)
		return false
	
	var resource = load(path)
	if resource == null:
		print("存档加载失败")
		return false
	
	# 恢复所有系统数据
	var player = get_tree().get_first_node_in_group("player")
	if player and resource.player_data:
		player.load_save_data(resource.player_data)
	
	var inventory = get_tree().get_first_node_in_group("inventory")
	if inventory and resource.inventory_data:
		inventory.load_save_data(resource.inventory_data)
	
	var quest = get_tree().get_first_node_in_group("quest")
	if quest and resource.quest_data:
		quest.load_save_data(resource.quest_data)
	
	var shop = get_tree().get_first_node_in_group("shop")
	if shop and resource.shop_data:
		shop.load_save_data(resource.shop_data)
	
	var skills = get_tree().get_first_node_in_group("skills")
	if skills and resource.skills_data:
		skills.load_save_data(resource.skills_data)
	
	var alchemy = get_tree().get_first_node_in_group("alchemy")
	if alchemy and resource.alchemy_data:
		alchemy.load_save_data(resource.alchemy_data)
	
	var map_node = get_tree().get_first_node_in_group("map")
	if map_node and resource.map_data:
		map_node.load_save_data(resource.map_data)
	
	current_save_slot = slot
	print("读档成功!")
	return true


# 自动存档
func auto_save():
	print("自动存档...")
	save_game(current_save_slot)


# 删除存档
func delete_save(slot: int) -> bool:
	if not save_exists(slot):
		return false
	
	var path = get_save_path(slot)
	var dir = DirAccess.open(save_path.get_base_dir())
	if dir:
		var error = dir.remove(path)
		if error == OK:
			print("删除存档成功")
			return true
		else:
			print("删除存档失败: " + str(error))
	return false


# 获取所有存档信息
func get_all_save_info() -> Array:
	var saves = []
	for i in range(3):  # 假设有3个存档位
		saves.append(get_save_info(i))
	return saves


# 快速保存（覆盖当前槽位）
func quick_save() -> bool:
	return save_game(current_save_slot)


# 快速加载（加载当前槽位）
func quick_load() -> bool:
	return load_game(current_save_slot)
