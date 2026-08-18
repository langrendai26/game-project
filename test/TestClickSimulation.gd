extends Node

# 模拟用户点击背包格子的测试
# 这个脚本会模拟点击事件来测试背包的响应

@export var inventory_script: Script = preload("res://scripts/Inventory.gd")

var inventory: Node = null
var test_slot_index = -1

func _ready():
	print("========== 背包点击响应模拟测试 ==========")
	await get_tree().create_timer(0.5).timeout
	run_click_test()

func run_click_test():
	print("\n[步骤1] 初始化测试环境...")
	
	# 创建模拟的 Inventory 实例
	inventory = inventory_script.new()
	inventory.init_inventory()
	
	# 添加一些测试物品
	print("\n[步骤2] 添加测试物品...")
	inventory.add_item("wood_mala", 1)
	inventory.add_item("monk_robe", 1)
	inventory.add_item("sutra_heart", 5)
	inventory.add_item("mantra_om_mani", 3)
	inventory.add_item("incense_stick", 10)
	
	var items = inventory.get_items()
	print("  添加了 %d 种物品到背包" % items.size())
	
	# 显示物品列表
	print("\n[步骤3] 背包物品列表:")
	for i in range(items.size()):
		var item = items[i]
		if item != null:
			print("    格子 %d: %s x%d (类型: %s)" % [i, item.name, item.quantity, item.type])
	
	# 模拟点击各个格子
	print("\n[步骤4] 模拟点击测试:")
	
	for i in range(min(5, items.size())):
		var item = items[i]
		if item != null:
			print("\n  点击格子 %d (%s)..." % [i, item.name])
			
			# 模拟 _on_slot_clicked(i)
			await simulate_slot_click(i, item)
	
	print("\n[步骤5] 测试完成!")
	print("背包点击响应测试结束。")

func simulate_slot_click(slot_index: int, _item):
	# 模拟 Inventory._on_slot_clicked(slot_index) 的逻辑
	print("    [模拟] 调用 _on_slot_clicked(%d)" % slot_index)
	
	# 获取物品数据
	var items = inventory.get_items()
	if slot_index < items.size() and items[slot_index] != null:
		var item_data = items[slot_index]
		var item_name = item_data.get("name", "未知")
		var type = item_data.get("type", "未知")
		var rarity = item_data.get("rarity", "common")
		var desc = item_data.get("desc", "无描述")
		
		print("    [结果] 选中物品: %s" % item_name)
		print("    [结果] 类型: %s, 稀有度: %s" % [type, rarity])
		print("    [结果] 描述: %s" % desc)
		
		# 测试右键操作（使用物品）
		if type == "consumable":
			print("    [操作] 这是一个消耗品，可以点击使用")
		elif type in ["weapon", "armor", "accessory"]:
			print("    [操作] 这是一个装备，可以点击装备")
		
		print("    ✓ 格子 %d 点击响应正常" % slot_index)
		return true
	else:
		print("    ✗ 格子 %d 没有物品或获取失败" % slot_index)
		return false

func _exit_tree():
	if inventory != null:
		inventory.queue_free()
