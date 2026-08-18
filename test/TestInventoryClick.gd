extends Node

# 测试背包点击响应脚本
# 运行方法：在 GameScene 中添加此脚本，或创建一个测试场景

@export var inventory_script: Script = preload("res://scripts/Inventory.gd")

var test_results = []

func _ready():
	print("========== 背包点击响应测试 ==========")
	
	# 等待一下让系统初始化
	await get_tree().create_timer(0.5).timeout
	
	# 测试1：检查背包系统是否存在
	test_inventory_system_exists()
	
	# 测试2：检查背包数据初始化
	test_inventory_data_initialization()
	
	# 测试3：检查物品数据库
	test_item_database()
	
	# 测试4：模拟添加物品
	test_add_item()
	
	# 测试5：检查物品获取
	test_get_items()
	
	# 测试6：检查物品使用（装备）
	test_use_item()
	
	# 测试7：检查物品出售
	test_sell_item()
	
	# 测试8：检查物品丢弃
	test_remove_item()
	
	# 输出测试结果
	print_test_summary()

func test_inventory_system_exists():
	print("\n[测试1] 检查背包系统是否存在...")
	var inventory = get_tree().get_first_node_in_group("inventory")
	if inventory != null:
		print("  ✓ 背包系统存在")
		test_results.append(true)
	else:
		print("  ✗ 背包系统不存在 (这可能是正常的，如果还没打开过背包)")
		test_results.append(false)

func test_inventory_data_initialization():
	print("\n[测试2] 检查背包数据初始化...")
	var inv = inventory_script.new()  # 创建一个新的背包实例
	inv.init_inventory()
	
	if inv.inventory.size() == 0:
		print("  ✓ 背包初始化成功 (空背包)")
		test_results.append(true)
	else:
		print("  ✗ 背包初始化异常")
		test_results.append(false)
	
	inv.queue_free()

func test_item_database():
	print("\n[测试3] 检查物品数据库...")
	var inv = inventory_script.new()
	var db = inv.get_item_database()
	
	if db.size() > 0:
		print("  ✓ 物品数据库有 %d 个物品" % db.size())
		# 打印前5个物品
		var count = 0
		for item_id in db:
			if count >= 5:
				break
			var item = db[item_id]
			print("    - %s: %s (类型: %s, 稀有度: %s)" % [item_id, item.name, item.type, item.rarity])
			count += 1
		test_results.append(true)
	else:
		print("  ✗ 物品数据库为空")
		test_results.append(false)
	
	inv.queue_free()

func test_add_item():
	print("\n[测试4] 测试添加物品...")
	var inv = inventory_script.new()
	inv.init_inventory()
	
	# 添加一个武器
	var result = inv.add_item("wood_mala", 1)
	if result:
		print("  ✓ 添加 wood_mala 成功")
		test_results.append(true)
	else:
		print("  ✗ 添加 wood_mala 失败")
		test_results.append(false)
	
	# 再次添加同一个物品（测试堆叠）
	result = inv.add_item("wood_mala", 1)
	if result:
		print("  ✓ 堆叠添加 wood_mala 成功")
	else:
		print("  ✗ 堆叠添加失败")
	
	# 添加一个防具
	result = inv.add_item("monk_robe", 1)
	if result:
		print("  ✓ 添加 monk_robe 成功")
	
	inv.queue_free()

func test_get_items():
	print("\n[测试5] 测试获取物品列表...")
	var inv = inventory_script.new()
	inv.init_inventory()
	inv.add_item("wood_mala", 2)
	inv.add_item("sutra_heart", 5)
	
	var items = inv.get_items()
	print("  背包中的物品数量: %d" % items.size())
	
	for item in items:
		if item != null:
			print("    - %s x%d" % [item.name, item.quantity])
	
	if items.size() >= 2:
		print("  ✓ 获取物品列表成功")
		test_results.append(true)
	else:
		print("  ✗ 获取物品列表失败")
		test_results.append(false)
	
	inv.queue_free()

func test_use_item():
	print("\n[测试6] 测试使用物品...")
	var inv = inventory_script.new()
	inv.init_inventory()
	
	# 先添加一个可装备的物品
	inv.add_item("wood_mala", 1)
	
	# 获取背包中的物品
	var items = inv.get_items()
	var sword_item = null
	for item in items:
		if item != null and item.id == "wood_mala":
			sword_item = item
			break
	
	if sword_item != null:
		# 尝试装备武器
		inv.equip_item(0)  # 装备到槽位0
		print("  ✓ 装备物品调用成功")
		test_results.append(true)
	else:
		print("  ✗ 找不到要装备的物品")
		test_results.append(false)
	
	inv.queue_free()

func test_sell_item():
	print("\n[测试7] 测试出售物品...")
	var inv = inventory_script.new()
	inv.init_inventory()
	
	# 添加一个物品
	inv.add_item("sutra_heart", 3)
	
	# 出售物品
	var result = inv.sell_item(0)  # 出售槽位0的物品
	
	if result:
		print("  ✓ 出售物品调用成功")
		test_results.append(true)
	else:
		print("  ✗ 出售物品失败")
		test_results.append(false)
	
	inv.queue_free()


func test_remove_item():
	print("\n[测试8] 测试丢弃物品...")
	var inv = inventory_script.new()
	inv.init_inventory()
	
	# 添加一个物品
	inv.add_item("wood_mala", 2)
	
	# 丢弃物品
	var result = inv.remove_item(0, 1)
	
	if result:
		print("  ✓ 丢弃物品成功")
		test_results.append(true)
	else:
		print("  ✗ 丢弃物品失败")
		test_results.append(false)
	
	inv.queue_free()

func print_test_summary():
	print("\n========== 测试结果汇总 ==========")
	var passed = 0
	var failed = 0
	
	for result in test_results:
		if result:
			passed += 1
		else:
			failed += 1
	
	print("总测试数: %d" % test_results.size())
	print("通过: %d" % passed)
	print("失败: %d" % failed)
	
	if failed == 0:
		print("\n🎉 所有测试通过！背包系统工作正常。")
	else:
		print("\n⚠️ 部分测试失败，请检查上述失败项。")

	# 退出测试
	print("\n按 Ctrl+C 退出测试，或直接关闭窗口。")
