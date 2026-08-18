extends Control

# 专注测试：出售价格为负数的物品，系统如何处理

func _ready():
	var karma_system = KarmaSystem.new()
	add_child(karma_system)
	
	var shop_script = load("res://scripts/Shop.gd")
	var shop = shop_script.new()
	shop.player_gold = 1000
	add_child(shop)
	
	var inv_script = load("res://scripts/Inventory.gd")
	var inv = inv_script.new()
	inv.max_slots = 50
	inv.base_max_slots = 50
	inv.inventory.clear()
	inv.inventory.resize(50)
	inv.inventory.fill(null)
	add_child(inv)
	
	# === 注入一个价格为负数的物品到商店数据库 ===
	shop.shop_database[shop.ShopType.GENERAL]["items"]["cursed_item"] = {
		"price": -100,
		"stock": -1,
		"desc": "被诅咒的物品，价格为负数"
	}
	# 同时注入到背包物品库
	inv.item_database["cursed_item"] = {
		"name": "被诅咒的物品",
		"type": "material",
		"rarity": "common",
		"desc": "测试用：价格为负数的物品",
		"price": -100
	}
	
	# 添加到背包
	inv.add_item("cursed_item")
	
	var sell_price = shop.get_item_sell_price("cursed_item")
	var original_price = shop._get_item_original_price("cursed_item")
	var count_before = inv.get_items().size()
	var gold_before = shop.player_gold
	var merit_before = karma_system.merit
	var sin_before = karma_system.sin_value
	
	print("========== 专注测试：出售价格为负数的物品 ==========")
	print("物品: cursed_item (被诅咒的物品)")
	print("商店原价: -100")
	print("背包库原价: %d" % original_price)
	print("回收价格: %d (预期: 0，因 raw_price <= 0 被拦截)" % sell_price)
	print("出售前 | 背包: %d | 金币: %d | 功德: %d | 罪孽: %d" % [count_before, gold_before, merit_before, sin_before])
	
	# 尝试出售
	print("")
	print(">>> 尝试出售...")
	var result = shop.sell_item("cursed_item", 1, inv.inventory, karma_system)
	
	var count_after = inv.get_items().size()
	var gold_after = shop.player_gold
	var merit_after = karma_system.merit
	var sin_after = karma_system.sin_value
	
	print("")
	print("出售结果: %s (预期: false)" % str(result))
	print("出售后 | 背包: %d | 金币: %d | 功德: %d | 罪孽: %d" % [count_after, gold_after, merit_after, sin_after])
	print("")
	print("背包变化: %d (预期: 0)" % (count_after - count_before))
	print("金币变化: %d (预期: 0)" % (gold_after - gold_before))
	print("功德变化: %d (预期: 0)" % (merit_after - merit_before))
	print("罪孽变化: %d (预期: 0)" % (sin_after - sin_before))
	
	# 验证
	var result_ok = result == false
	var count_ok = count_after == count_before
	var gold_ok = gold_after == gold_before
	var merit_ok = merit_after == merit_before
	var sin_ok = sin_after == sin_before
	
	# 确认物品仍在背包
	var still_exists = false
	for item in inv.inventory:
		if item != null and item.get("id", "") == "cursed_item":
			still_exists = true
			break
	
	print("")
	print("验证1 - 出售被拦截:     %s → %s" % [str(result_ok), "✓ 通过" if result_ok else "✗ 未通过"])
	print("验证2 - 背包未减少:     %s → %s" % [str(count_ok), "✓ 通过" if count_ok else "✗ 未通过"])
	print("验证3 - 金币未变:       %s → %s" % [str(gold_ok), "✓ 通过" if gold_ok else "✗ 未通过"])
	print("验证4 - 功德未变:       %s → %s" % [str(merit_ok), "✓ 通过" if merit_ok else "✗ 未通过"])
	print("验证5 - 罪孽未变:       %s → %s" % [str(sin_ok), "✓ 通过" if sin_ok else "✗ 未通过"])
	print("验证6 - 物品仍在背包:   %s → %s" % [str(still_exists), "✓ 通过" if still_exists else "✗ 未通过"])
	print("验证7 - 无运行时崩溃:   ✓ 通过")
	
	print("")
	if result_ok and count_ok and gold_ok and merit_ok and sin_ok and still_exists:
		print("========== 全部通过 ✓ ==========")
	else:
		print("========== 存在未通过项 ✗ ==========")
	
	get_tree().quit()