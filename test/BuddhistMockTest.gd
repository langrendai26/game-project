extends Control

# 三界模拟器 · 佛教主题测试场景
# 测试背包物品管理和商店购买/出售交互

var karma_system: KarmaSystem = null
var precept_system: PreceptSystem = null
var shop_system: Node = null
var inventory_script: Node = null

# UI 节点
var log_label: RichTextLabel = null
var status_label: Label = null

func _ready():
	_build_ui()
	_init_systems()
	_run_auto_tests()

func _build_ui():
	# 背景
	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.06, 0.04)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# 标题
	var title = Label.new()
	title.text = "三界模拟器 · 背包与商店交互测试"
	title.position = Vector2(20, 10)
	title.size = Vector2(800, 40)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	add_child(title)
	
	# 状态标签
	status_label = Label.new()
	status_label.text = "正在初始化..."
	status_label.position = Vector2(20, 50)
	status_label.size = Vector2(800, 30)
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.6))
	add_child(status_label)
	
	# 日志面板
	var log_panel = Panel.new()
	log_panel.position = Vector2(20, 90)
	log_panel.size = Vector2(850, 500)
	log_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(log_panel)
	
	var log_title = Label.new()
	log_title.text = "【测试日志】"
	log_title.position = Vector2(10, 5)
	log_title.size = Vector2(200, 25)
	log_title.add_theme_font_size_override("font_size", 16)
	log_title.add_theme_color_override("font_color", Color(0.8, 0.7, 0.4))
	log_panel.add_child(log_title)
	
	log_label = RichTextLabel.new()
	log_label.position = Vector2(10, 30)
	log_label.size = Vector2(830, 460)
	log_label.text = ""
	log_label.scroll_following = true
	log_label.bbcode_enabled = true
	log_panel.add_child(log_label)
	
	# 按钮栏
	var btn_panel = Panel.new()
	btn_panel.position = Vector2(20, 600)
	btn_panel.size = Vector2(850, 80)
	add_child(btn_panel)
	
	var grid = GridContainer.new()
	grid.columns = 4
	grid.position = Vector2(10, 10)
	grid.size = Vector2(830, 60)
	btn_panel.add_child(grid)
	
	var btn_specs = [
		["测试背包添加", _test_inventory_add],
		["测试背包点击", _test_inventory_click],
		["测试商店购买", _test_shop_purchase],
		["测试商店出售", _test_shop_sell],
		["测试功德加成", _test_merit_bonus],
		["测试限时商店", _test_limited_shop],
		["运行全部测试", _run_all_tests],
		["清空日志", _clear_log],
	]
	
	for spec in btn_specs:
		var btn = Button.new()
		btn.text = spec[0]
		btn.custom_minimum_size = Vector2(195, 28)
		btn.flat = false
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.pressed.connect(spec[1])
		grid.add_child(btn)

func _init_systems():
	# 业力系统
	karma_system = KarmaSystem.new()
	karma_system.name = "KarmaSystem"
	add_child(karma_system)
	
	# 戒律系统
	precept_system = PreceptSystem.new()
	precept_system.name = "PreceptSystem"
	add_child(precept_system)
	
	# 商店系统
	var shop_script = load("res://scripts/Shop.gd")
	shop_system = shop_script.new()
	shop_system.name = "ShopSystem"
	shop_system.add_to_group("shop")
	add_child(shop_system)
	
	# 背包系统（纯脚本实例，无UI）
	var inv_script = load("res://scripts/Inventory.gd")
	inventory_script = inv_script.new()
	inventory_script.name = "TestInventory"
	inventory_script.add_to_group("inventory")
	add_child(inventory_script)
	
	# 强制重置背包 - 清空所有物品
	inventory_script.max_slots = 50
	inventory_script.base_max_slots = 50
	inventory_script.inventory.clear()
	inventory_script.inventory.resize(50)
	inventory_script.inventory.fill(null)
	inventory_script.durability.clear()
	
	# 添加初始佛教物品
	inventory_script.add_item("wood_mala")
	inventory_script.add_item("monk_robe")
	inventory_script.add_item("sutra_heart")
	inventory_script.add_item("incense_stick")
	inventory_script.add_item("pure_water")
	inventory_script.add_item("lotus_flower")
	
	# 强制设置商店金币
	shop_system.player_gold = 1000
	
	status_label.text = "系统初始化完成 | 金币: %d | 背包物品: %d" % [shop_system.player_gold, inventory_script.get_items().size()]
	add_log("=== 三界模拟器 · 测试环境初始化完成 ===")
	add_log("功德: %d | 罪孽: %d | 金币: %d" % [karma_system.merit, karma_system.sin_value, shop_system.player_gold])
	add_log("背包初始物品: %d 件" % inventory_script.get_items().size())
	add_log("")

func _run_auto_tests():
	await get_tree().create_timer(0.5).timeout
	add_log(">>> 自动测试开始 <<<")

# ========== 测试用例 ==========

func _test_inventory_add():
	add_log("--- 测试：背包添加物品 ---")
	
	var test_items = [
		{"id": "wood_mala", "name": "木念珠"},
		{"id": "bodhi_mala", "name": "菩提子念珠"},
		{"id": "sandalwood_mala", "name": "檀香念珠"},
		{"id": "sutra_heart", "name": "心经"},
		{"id": "sutra_diamond", "name": "金刚经"},
		{"id": "mantra_om_mani", "name": "六字真言"},
		{"id": "incense_stick", "name": "檀香"},
		{"id": "lotus_flower", "name": "莲花"},
		{"id": "peace_pill", "name": "定心丹"},
		{"id": "monk_robe", "name": "缦衣"},
	]
	
	var success_count = 0
	for item in test_items:
		var result = inventory_script.add_item(item["id"])
		if result:
			add_log("[color=green]✓ 添加成功[/color]：%s" % item["name"])
			success_count += 1
		else:
			add_log("[color=red]✗ 添加失败[/color]：%s" % item["name"])
	
	var all_items = inventory_script.get_items()
	add_log("背包现有物品：%d 件（成功添加 %d/%d）" % [all_items.size(), success_count, test_items.size()])
	_update_status()

func _test_inventory_click():
	add_log("--- 测试：背包物品点击与详情 ---")
	
	var items = inventory_script.get_items()
	if items.is_empty():
		add_log("[color=yellow]背包为空，先执行「测试背包添加」[/color]")
		return
	
	var tested = 0
	for i in range(min(items.size(), 6)):
		var item = items[i]
		var item_name = item.get("name", "未知")
		var _item_id = item.get("id", "")
		var item_type = item.get("type", "")
		var item_desc = item.get("desc", "")
		var item_rarity = item.get("rarity", "")
		
		# 模拟点击显示详情
		var has_merit = item.has("merit_bonus")
		var merit_info = ""
		if has_merit:
			merit_info = " | 功德加成: +%.0f%%" % (item["merit_bonus"] * 100)
		
		add_log("[color=cyan]点击格子 %d[/color]：%s [%s/%s]" % [i, item_name, item_type, item_rarity])
		add_log("  描述：%s%s" % [item_desc, merit_info])
		tested += 1
	
	add_log("共测试 %d 个物品的点击详情" % tested)

func _test_shop_purchase():
	add_log("--- 测试：商店购买 ---")
	
	var shop_types = [
		{"type": shop_system.ShopType.GENERAL, "name": "法物流通处"},
		{"type": shop_system.ShopType.EQUIPMENT, "name": "法器铺"},
		{"type": shop_system.ShopType.CONSUMABLE, "name": "经咒坊"},
	]
	
	var gold_before = shop_system.player_gold
	
	for shop_info in shop_types:
		var st = shop_info["type"]
		var sname = shop_info["name"]
		var items = shop_system.get_shop_items(st)
		
		add_log("\n[color=yellow]%s[/color]（共 %d 件商品）：" % [sname, items.size()])
		
		# 列出前3件商品
		for j in range(min(items.size(), 3)):
			var item = items[j]
			add_log("  %s - 价格:%d金 - %s" % [item["name"], item["price"], item["desc"]])
		
		# 尝试购买第一件商品
		if items.size() > 0:
			var first = items[0]
			var result = shop_system.purchase_item(st, first["id"])
			if result:
				# 同步到背包
				inventory_script.add_item(first["id"])
				add_log("[color=green]  ✓ 购买成功[/color]：%s（花费 %d 金）" % [first["name"], first["price"]])
			else:
				add_log("[color=red]  ✗ 购买失败[/color]：%s" % first["name"])
	
	var gold_after = shop_system.player_gold
	add_log("\n金币变化：%d → %d（消费 %d）" % [gold_before, gold_after, gold_before - gold_after])
	_update_status()

func _test_shop_sell():
	add_log("--- 测试：商店出售 + 功德联动 ---")
	
	var items = inventory_script.get_items()
	if items.is_empty():
		add_log("[color=yellow]背包为空，无法测试出售[/color]")
		return
	
	var gold_before = shop_system.player_gold
	var merit_before = karma_system.merit
	var sin_before = karma_system.sin_value
	var sold_count = 0
	
	add_log("出售前 | 功德: %d | 罪孽: %d" % [merit_before, sin_before])
	add_log("")
	
	# 尝试出售前3件物品，传递 karma_system 以触发业力联动
	for i in range(min(items.size(), 3)):
		var item = items[i]
		var item_id = item.get("id", "")
		var item_name = item.get("name", "未知")
		
		var sell_price = shop_system.get_item_sell_price(item_id)
		if sell_price > 0:
			var result = shop_system.sell_item(item_id, 1, inventory_script.inventory, karma_system)
			if result:
				# 获取原价和售价对比
				var original_price = 0
				if inventory_script.item_database.has(item_id):
					original_price = inventory_script.item_database[item_id].get("price", 0)
				var ratio = float(sell_price) / float(max(original_price, 1))
				var karma_note = ""
				if ratio <= 0.5:
					karma_note = " [color=green](法布施→功德+%d)[/color]" % int(original_price * 0.05)
				add_log("[color=green]✓ 出售成功[/color]：%s（获得 %d 金，原价 %d，出售比例 %.0f%%）%s" % [
					item_name, sell_price, original_price, ratio * 100, karma_note])
				sold_count += 1
			else:
				add_log("[color=red]✗ 出售失败[/color]：%s" % item_name)
		else:
			add_log("[color=yellow]○ 不可出售[/color]：%s" % item_name)
	
	var gold_after = shop_system.player_gold
	var merit_after = karma_system.merit
	var sin_after = karma_system.sin_value
	
	add_log("")
	add_log("出售后 | 功德: %d (变化: %+d) | 罪孽: %d (变化: %+d)" % [merit_after, merit_after - merit_before, sin_after, sin_after - sin_before])
	add_log("出售 %d 件 | 金币: %d → %d（+%d）" % [sold_count, gold_before, gold_after, gold_after - gold_before])
	_update_status()

func _test_merit_bonus():
	add_log("--- 测试：功德加成计算 ---")
	
	# 获取所有有功德加成的物品
	var items = inventory_script.get_items()
	var total_bonus = 0.0
	var bonus_items = []
	
	for item in items:
		if item.has("merit_bonus"):
			bonus_items.append(item)
			total_bonus += item["merit_bonus"]
	
	if bonus_items.is_empty():
		add_log("[color=yellow]背包中没有功德加成物品[/color]")
		add_log("提示：购买佛珠、法器、僧衣可获得功德加成")
		return
	
	for item in bonus_items:
		var item_name = item.get("name", "未知")
		var bonus = item.get("merit_bonus", 0)
		add_log("  %s → 功德加成 +%.0f%%" % [item_name, bonus * 100])
	
	add_log("[color=green]总功德加成：+%.0f%%[/color]" % (total_bonus * 100))
	
	# 测试持戒加成
	var precept_bonus = precept_system.precept_merit_bonus
	add_log("持戒功德加成：+%.0f%%（持戒 %d/5）" % [(precept_bonus - 1.0) * 100, precept_system.get_kept_precept_count()])
	
	# 综合加成
	var combined = precept_bonus + total_bonus
	add_log("[color=yellow]综合功德倍率：%.2f 倍[/color]" % combined)

func _test_limited_shop():
	add_log("--- 测试：限时法布施商店 ---")
	
	shop_system.init_limited_shop()
	var items = shop_system.get_shop_items(shop_system.ShopType.LIMITED)
	
	if items.is_empty():
		add_log("[color=red]限时商店无商品[/color]")
		return
	
	add_log("限时法布施商品（%d 件）：" % items.size())
	for item in items:
		var discount_tag = " [打折]" if item["on_sale"] else ""
		add_log("  %s - 原价:%d → 现价:%d%s" % [item["name"], item["original_price"], item["price"], discount_tag])
	
	# 尝试购买一件
	if items.size() > 0 and shop_system.player_gold >= items[0]["price"]:
		var first = items[0]
		var result = shop_system.purchase_item(shop_system.ShopType.LIMITED, first["id"])
		if result:
			inventory_script.add_item(first["id"])
			add_log("[color=green]✓ 限时购买成功[/color]：%s（花费 %d 金）" % [first["name"], first["price"]])
		else:
			add_log("[color=red]✗ 购买失败[/color]")
	else:
		add_log("[color=yellow]金币不足或无商品可购买[/color]")
	
	_update_status()

func _run_all_tests():
	add_log("\n[color=yellow]========== 全部测试开始 ==========[/color]")
	
	# 重置
	_init_systems()
	
	await get_tree().create_timer(0.1).timeout
	_test_inventory_add()
	await get_tree().create_timer(0.1).timeout
	_test_inventory_click()
	await get_tree().create_timer(0.1).timeout
	_test_shop_purchase()
	await get_tree().create_timer(0.1).timeout
	_test_shop_sell()
	await get_tree().create_timer(0.1).timeout
	_test_merit_bonus()
	await get_tree().create_timer(0.1).timeout
	_test_limited_shop()
	await get_tree().create_timer(0.1).timeout
	_test_negative_price_safety()
	
	await get_tree().create_timer(0.2).timeout
	add_log("\n[color=green]========== 全部测试完成 ==========[/color]")
	_update_status()

func _test_negative_price_safety():
	add_log("--- 安全测试：负数/零价格物品 ---")
	
	var items = inventory_script.get_items()
	var count_before = items.size()
	var merit_before = karma_system.merit
	var sin_before = karma_system.sin_value
	var gold_before = shop_system.player_gold
	
	add_log("测试前 | 背包: %d 件 | 功德: %d | 罪孽: %d | 金币: %d" % [count_before, merit_before, sin_before, gold_before])
	
	# 测试1：出售不存在的物品（应该被拦截）
	add_log("\n测试1：出售不存在的物品 ID...")
	var r1 = shop_system.sell_item("nonexistent_item", 1, inventory_script.inventory, karma_system)
	add_log("  结果: %s (预期: false) → %s" % [str(r1), "[color=green]通过[/color]" if not r1 else "[color=red]未通过[/color]"])
	
	# 测试2：出售价格为0的物品（背包找不到 → sell_price=0 → 被拦截）
	add_log("测试2：出售 price=0 的物品...")
	var r2 = shop_system.sell_item("zero_price_item", 1, inventory_script.inventory, karma_system)
	add_log("  结果: %s (预期: false) → %s" % [str(r2), "[color=green]通过[/color]" if not r2 else "[color=red]未通过[/color]"])
	
	# 测试3：出售有效物品（验证背包数量减少）
	if items.size() > 0:
		var test_item = items[0]
		var test_id = test_item.get("id", "")
		var test_name = test_item.get("name", "未知")
		var sell_price = shop_system.get_item_sell_price(test_id)
		
		add_log("测试3：出售有效物品 %s（回收价 %d）..." % [test_name, sell_price])
		var r3 = shop_system.sell_item(test_id, 1, inventory_script.inventory, karma_system)
		var count_after = inventory_script.get_items().size()
		var merit_after = karma_system.merit
		var gold_after = shop_system.player_gold
		
		add_log("  出售结果: %s" % str(r3))
		add_log("  背包: %d → %d (变化: %+d)" % [count_before, count_after, count_after - count_before])
		add_log("  功德: %d → %d (变化: %+d)" % [merit_before, merit_after, merit_after - merit_before])
		add_log("  金币: %d → %d (变化: %+d)" % [gold_before, gold_after, gold_after - gold_before])
		
		# 验证
		var inv_ok = count_after == count_before - 1
		var gold_ok = gold_after == gold_before + sell_price
		add_log("  背包减少验证: %s → %s" % [str(inv_ok), "[color=green]通过[/color]" if inv_ok else "[color=red]未通过[/color]"])
		add_log("  金币增加验证: %s → %s" % [str(gold_ok), "[color=green]通过[/color]" if gold_ok else "[color=red]未通过[/color]"])
	else:
		add_log("  [color=yellow]背包为空，跳过[/color]")
	
	# 最终状态检查
	add_log("\n最终状态 | 背包: %d 件 | 功德: %d | 罪孽: %d | 金币: %d" % [
		inventory_script.get_items().size(), karma_system.merit, karma_system.sin_value, shop_system.player_gold])

func _clear_log():
	log_label.text = ""
	add_log("日志已清空")

# ========== 辅助函数 ==========

func add_log(msg: String):
	log_label.text += msg + "\n"
	print("[测试] " + msg)

func _update_status():
	var item_count = inventory_script.get_items().size()
	status_label.text = "金币: %d | 背包: %d 件 | 功德: %d | 罪孽: %d" % [
		shop_system.player_gold, item_count, karma_system.merit, karma_system.sin_value
	]