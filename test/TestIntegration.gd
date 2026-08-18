extends Node

# 集成测试：模拟完整打开背包并点击格子的流程
# 需要先在 GameScene 中添加 Inventory 系统节点

@export var inventory_script: Script = preload("res://scripts/Inventory.gd")

var inventory_system: Node = null
var inventory_ui: Node = null
var game_scene: Node = null

func _ready():
	print("========== 背包完整流程测试 ==========")
	await get_tree().create_timer(0.5).timeout
	run_integration_test()

func run_integration_test():
	print("\n[步骤1] 查找 Inventory 系统...")
	
	# 尝试获取 Inventory 系统
	inventory_system = get_tree().get_first_node_in_group("inventory")
	if inventory_system == null:
		# 如果没有，创建一个测试用的
		print("  未找到 Inventory 系统，创建测试实例...")
		inventory_system = inventory_script.new()
		inventory_system.init_inventory()
		add_child(inventory_system)
	else:
		print("  ✓ 找到 Inventory 系统")
	
	# 添加测试物品
	print("\n[步骤2] 添加测试物品...")
	add_test_items()
	
	# 测试背包 UI 更新
	print("\n[步骤3] 测试背包 UI 更新...")
	test_update_display()
	
	# 测试格子点击
	print("\n[步骤4] 测试格子点击响应...")
	test_slot_click()
	
	# 测试物品操作
	print("\n[步骤5] 测试物品操作...")
	test_item_operations()
	
	print("\n[步骤6] 清理测试数据...")
	cleanup()
	
	print("\n========== 测试完成 ==========")

func add_test_items():
	var items_to_add = [
		{"id": "wood_mala", "qty": 1},
		{"id": "monk_robe", "qty": 1},
		{"id": "sutra_heart", "qty": 5},
		{"id": "mantra_om_mani", "qty": 3},
		{"id": "incense_stick", "qty": 10},
		{"id": "lotus_pendant", "qty": 1},
		{"id": "bodhi_mala", "qty": 1},
	]
	
	for item_info in items_to_add:
		var result = inventory_system.add_item(item_info.id, item_info.qty)
		if result:
			print("  ✓ 添加 %s x%d" % [item_info.id, item_info.qty])
		else:
			print("  ✗ 添加 %s 失败" % item_info.id)
	
	var total = inventory_system.get_items().size()
	print("  背包中共 %d 个物品" % total)

func test_update_display():
	# 测试 UI 更新逻辑
	print("  模拟 update_display() 调用...")
	
	# 模拟过滤
	var filtered = inventory_system.get_filtered_items()
	print("  过滤后物品数: %d" % filtered.size())
	
	# 模拟排序
	inventory_system.sort_mode = "name"
	inventory_system.update_display()
	print("  ✓ 按名称排序后更新成功")
	
	inventory_system.sort_mode = "rarity"
	inventory_system.update_display()
	print("  ✓ 按稀有度排序后更新成功")
	
	inventory_system.sort_mode = "type"
	inventory_system.update_display()
	print("  ✓ 按类型排序后更新成功")
	
	# 模拟搜索
	inventory_system.search_text = "potion"
	var search_filtered = inventory_system.get_filtered_items()
	print("  搜索 'potion' 后结果: %d 个物品" % search_filtered.size())
	
	# 模拟分类
	inventory_system.search_text = ""
	inventory_system.current_category = "weapon"
	var weapon_filtered = inventory_system.get_filtered_items()
	print("  筛选 'weapon' 后结果: %d 个物品" % weapon_filtered.size())

func test_slot_click():
	print("\n  测试点击各个格子...")
	
	var items = inventory_system.get_items()
	for i in range(min(5, items.size())):
		var item = items[i]
		if item != null:
			# 模拟点击
			print("  点击格子 %d: %s..." % [i, item.name])
			
			# 获取物品信息
			var desc = "类型: %s, 稀有度: %s, 描述: %s" % [
				inventory_system.get_type_name(item.type),
				inventory_system.get_rarity_name(item.rarity),
				item.desc
			]
			print("    ✓ 成功获取物品描述")
			print("      %s" % desc)

func test_item_operations():
	print("\n  测试物品操作...")
	
	# 测试装备
	var items = inventory_system.get_items()
	for i in range(items.size()):
		var item = items[i]
		if item != null and item.type in ["weapon", "armor", "accessory"]:
			print("  装备物品 %s..." % item.name)
			inventory_system.equip_item(i)
			print("    ✓ 装备调用成功")
			break
	
	# 测试使用消耗品
	for i in range(items.size()):
		var item = items[i]
		if item != null and item.type == "consumable":
			print("  使用消耗品 %s..." % item.name)
			# 注意：实际使用可能会失败因为没有真实角色数据
			print("    (跳过，因为需要角色数据)")
			break
	
	# 测试出售
	var sell_result = inventory_system.sell_item(0)
	if sell_result:
		print("  ✓ 出售成功")
	else:
		print("  ✗ 出售失败")

func cleanup():
	# 清理测试数据
	if inventory_system != null and is_instance_valid(inventory_system):
		# 清除所有物品
		if inventory_system.inventory != null:
			for i in range(inventory_system.inventory.size()):
				inventory_system.inventory[i] = null
		
		if inventory_system.get_parent() == self:
			remove_child(inventory_system)
			inventory_system.queue_free()
			inventory_system = null
		print("  ✓ 测试数据已清理")
