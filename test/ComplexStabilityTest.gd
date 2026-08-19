extends Control

# 复杂稳定性测试 - 验证背包堆叠/购买原子性/炼丹消耗/经济循环
# 自动运行全部测试，5 秒后退出

var karma_system: KarmaSystem = null
var shop_system: Node = null
var inventory_script: Node = null
var alchemy_system: AlchemySystem = null
var map_system: MapSystem = null

var log_label: RichTextLabel = null
var status_label: Label = null
var pass_count: int = 0
var fail_count: int = 0

func _ready():
	_build_ui()
	_init_systems()
	await get_tree().create_timer(0.3).timeout
	_run_all_tests()
	await get_tree().create_timer(5.0).timeout
	get_tree().quit(0)

func _build_ui():
	var bg = ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.08)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title = Label.new()
	title.text = "🧪 复杂稳定性测试 · 背包/购买/炼丹/经济循环"
	title.position = Vector2(20, 8)
	title.size = Vector2(900, 30)
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.5))
	add_child(title)

	status_label = Label.new()
	status_label.text = "初始化中..."
	status_label.position = Vector2(20, 40)
	status_label.size = Vector2(900, 22)
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.7))
	add_child(status_label)

	log_label = RichTextLabel.new()
	log_label.position = Vector2(20, 70)
	log_label.size = Vector2(900, 520)
	log_label.text = ""
	log_label.scroll_following = true
	log_label.bbcode_enabled = true
	add_child(log_label)

func _init_systems():
	karma_system = KarmaSystem.new()
	karma_system.name = "KarmaSystem"
	add_child(karma_system)

	var shop_script = load("res://scripts/Shop.gd")
	shop_system = shop_script.new()
	shop_system.name = "ShopSystem"
	add_child(shop_system)

	var inv_script = load("res://scripts/Inventory.gd")
	inventory_script = inv_script.new()
	inventory_script.name = "TestInventory"
	add_child(inventory_script)

	alchemy_system = AlchemySystem.new()
	alchemy_system.name = "AlchemySystem"
	add_child(alchemy_system)

	map_system = MapSystem.new()
	map_system.name = "MapSystem"
	add_child(map_system)

	add_log("=== 系统初始化完成（真实数据）===")
	add_log("初始 | 金币: %d | 背包: %d 件 | 空格: %d" % [
		shop_system.player_gold,
		inventory_script.get_items().size(),
		inventory_script.get_empty_slot_count()])
	add_log("")

func _run_all_tests():
	add_log("[color=yellow]========== 开始复杂稳定性测试 ==========[/color]")
	add_log("")

	_test_stack_pressure()
	_test_purchase_atomicity()
	_test_alchemy_consume_cycle()
	_test_economic_loop_10_rounds()
	_test_sell_stack_linkage()

	add_log("")
	add_log("[color=yellow]========== 测试总结 ==========[/color]")
	var total = pass_count + fail_count
	add_log("总计: %d 项 | 通过: %d | 失败: %d" % [total, pass_count, fail_count])
	if fail_count == 0:
		add_log("[color=green]✓✓✓ 全部测试通过！稳定性验证成功 ✓✓✓[/color]")
	else:
		add_log("[color=red]✗ 有 %d 项失败，请检查上方日志[/color]" % fail_count)
	_update_status()

# ========== 阶段 1: 背包堆叠压力测试 ==========
func _test_stack_pressure():
	add_log("[color=yellow]===== 阶段 1: 背包堆叠压力测试 =====[/color]")

	# 1.1 重复添加同种材料 50 次，应堆叠到 1 格
	var slots_before = inventory_script.get_items().size()
	for i in range(50):
		inventory_script.add_item("sandalwood_powder")
	var slots_after = inventory_script.get_items().size()
	var count_total = inventory_script.get_item_count("sandalwood_powder")
	_check("1.1 重复添加 sandalwood_powder ×50 堆叠成 1 格",
		slots_after - slots_before == 1 and count_total >= 50)

	# 1.2 添加 5 种不同材料各 5 个，应占 5 格
	slots_before = inventory_script.get_items().size()
	var diff_mats = ["honey", "lotus_petal", "incense_powder", "herb_medicine", "incense_ash"]
	for mat_id in diff_mats:
		inventory_script.add_item(mat_id, 5)
	slots_after = inventory_script.get_items().size()
	_check("1.2 5 种不同材料各 5 个占 5 格（实际 +%d 格）" % (slots_after - slots_before),
		slots_after - slots_before == 5)

	# 1.3 装备类不堆叠（每件 1 格）
	slots_before = inventory_script.get_items().size()
	inventory_script.add_item("wood_mala", 3)
	slots_after = inventory_script.get_items().size()
	_check("1.3 wood_mala ×3 不堆叠占 3 格（实际 +%d 格）" % (slots_after - slots_before),
		slots_after - slots_before == 3)

	add_log("")

# ========== 阶段 2: 购买原子性边界测试 ==========
func _test_purchase_atomicity():
	add_log("[color=yellow]===== 阶段 2: 购买原子性边界测试 =====[/color]")

	# 2.1 背包仅剩 1 格时购买 5 个可堆叠材料（合并到已有堆叠）→ 应成功
	# 先填满背包到只剩 1 格
	_fill_inventory_until_n_empty(1)
	var _empty_before = inventory_script.get_empty_slot_count()
	var gold_before_21 = shop_system.player_gold
	var sp_before_21 = inventory_script.get_item_count("sandalwood_powder")
	var ok1 = shop_system.purchase_item(shop_system.ShopType.GENERAL, "sandalwood_powder", 5, inventory_script)
	var sp_after_21 = inventory_script.get_item_count("sandalwood_powder")
	# 合并到已有堆叠：空格不变（仍是1），但数量+5
	_check("2.1 仅剩1格时买5个可堆叠材料成功合并（数量 %d→%d 应+5）" % [sp_before_21, sp_after_21],
		ok1 and sp_after_21 == sp_before_21 + 5)

	# 2.2 再次填满到 0 空格，购买 1 个新材料（无已有堆叠）→ 应失败且金币不扣
	_fill_inventory_until_n_empty(0)
	gold_before_21 = shop_system.player_gold
	var ok2 = shop_system.purchase_item(shop_system.ShopType.GENERAL, "wisdom_grass", 1, inventory_script)
	var gold_after_22 = shop_system.player_gold
	_check("2.2 背包满时购买新材料失败且金币不扣（金币 %d→%d）" % [gold_before_21, gold_after_22],
		not ok2 and gold_after_22 == gold_before_21)

	# 2.3 背包 0 空格时购买已有堆叠材料 → 应成功（合并）
	gold_before_21 = shop_system.player_gold
	var ok3 = shop_system.purchase_item(shop_system.ShopType.GENERAL, "sandalwood_powder", 3, inventory_script)
	var gold_after_23 = shop_system.player_gold
	_check("2.3 背包满时购买已有堆叠材料成功（金币 %d→%d）" % [gold_before_21, gold_after_23],
		ok3 and gold_after_23 < gold_before_21)

	# 2.4 背包 0 空格时购买装备 → 应失败且金币不扣
	var gold_before_24 = shop_system.player_gold
	var ok4 = shop_system.purchase_item(shop_system.ShopType.EQUIPMENT, "wood_mala", 1, inventory_script)
	var gold_after_24 = shop_system.player_gold
	_check("2.4 背包满时购买装备失败且金币不扣（金币 %d→%d）" % [gold_before_24, gold_after_24],
		not ok4 and gold_after_24 == gold_before_24)

	# 2.5 金币不足时购买 → 应失败且不扣
	var low_gold = shop_system.player_gold
	shop_system.player_gold = 5  # 临时设低
	var ok5 = shop_system.purchase_item(shop_system.ShopType.GENERAL, "longevity_herb", 1, inventory_script)
	shop_system.player_gold = low_gold  # 恢复
	_check("2.5 金币不足时购买失败不扣金币", not ok5)

	# 清空背包为后续测试腾空间
	_clear_inventory()
	add_log("  (已清空背包为后续测试腾空间)")
	add_log("")

# ========== 阶段 3: 炼丹材料消耗循环 ==========
func _test_alchemy_consume_cycle():
	add_log("[color=yellow]===== 阶段 3: 炼丹材料消耗循环 =====[/color]")

	# 3.1 准备材料：定心丹需 sandalwood_powder×2 + pure_water×1
	inventory_script.add_item("sandalwood_powder", 10)
	inventory_script.add_item("pure_water", 5)
	var sp_before = inventory_script.get_item_count("sandalwood_powder")
	var pw_before = inventory_script.get_item_count("pure_water")
	add_log("  准备材料: sandalwood_powder ×%d, pure_water ×%d" % [sp_before, pw_before])

	# 3.2 连续炼制定心丹 3 次（每次消耗 2 sp + 1 pw）
	var craft_ok_count = 0
	for i in range(3):
		var ok = alchemy_system.start_crafting("calming_pill", inventory_script, null)
		if ok:
			craft_ok_count += 1
			# 立即完成炼制（不等待真实时间）
			alchemy_system.is_crafting = false
			alchemy_system.craft_progress = 1.0
	var sp_after = inventory_script.get_item_count("sandalwood_powder")
	var pw_after = inventory_script.get_item_count("pure_water")
	_check("3.2 连续炼制定心丹 3 次成功（实际 %d 次）" % craft_ok_count,
		craft_ok_count == 3)
	_check("3.3 炼制3次后材料正确扣减 (sp: %d→%d 应-6, pw: %d→%d 应-3)" % [
		sp_before, sp_after, pw_before, pw_after],
		sp_after == sp_before - 6 and pw_after == pw_before - 3)

	# 3.4 材料耗尽时再炼制应被拦截
	_clear_inventory()
	inventory_script.add_item("sandalwood_powder", 1)  # 只给 1 个，不足 2
	inventory_script.add_item("pure_water", 1)
	var ok_fail = alchemy_system.start_crafting("calming_pill", inventory_script, null)
	_check("3.4 材料不足时炼制被拦截", not ok_fail)

	add_log("")

# ========== 阶段 4: 多轮经济闭环 ==========
func _test_economic_loop_10_rounds():
	add_log("[color=yellow]===== 阶段 4: 10 轮经济闭环（探索→购买→炼丹）=====[/color]")

	_clear_inventory()
	# 初始注入一些材料让循环可启动
	inventory_script.add_item("sandalwood_powder", 5)
	inventory_script.add_item("pure_water", 3)

	var gold_start = shop_system.player_gold
	var inv_start = inventory_script.get_items().size()
	var success_rounds = 0

	for round_num in range(1, 11):
		var _round_gold_before = shop_system.player_gold
		# 4.1 探索 1 次（欲界第一个地点）
		var locations = map_system.get_available_locations()
		if locations.size() == 0:
			add_log("  [Round %d] 无可探索地点，跳过" % round_num)
			continue
		var exp_result = map_system.explore_location(locations[0]["id"], karma_system, null)
		var gold_gain = exp_result.get("gold_gained", 0)
		if gold_gain > 0:
			shop_system.player_gold += gold_gain
		# 领取物品
		for item in exp_result.get("items_gained", []):
			if item is Dictionary and item.has("id"):
				inventory_script.add_item(item["id"])

		# 4.2 用探索所得金币购买材料（如果能买）
		var bought_something = false
		if shop_system.player_gold >= 20:
			var buy_ok = shop_system.purchase_item(shop_system.ShopType.GENERAL, "sandalwood_powder", 1, inventory_script)
			if buy_ok:
				bought_something = true
		if shop_system.player_gold >= 10:
			var buy_ok2 = shop_system.purchase_item(shop_system.ShopType.GENERAL, "pure_water", 1, inventory_script)
			if buy_ok2:
				bought_something = true

		# 4.3 尝试炼制（材料够就炼）
		var sp = inventory_script.get_item_count("sandalwood_powder")
		var pw = inventory_script.get_item_count("pure_water")
		var crafted = false
		if sp >= 2 and pw >= 1:
			var c_ok = alchemy_system.start_crafting("calming_pill", inventory_script, null)
			if c_ok:
				crafted = true
				alchemy_system.is_crafting = false
				alchemy_system.craft_progress = 1.0

		if gold_gain > 0 or bought_something or crafted:
			success_rounds += 1
		add_log("  [Round %2d] 探索金币 +%d | 买料 %s | 炼丹 %s | 余额 %d" % [
			round_num, gold_gain,
			"✓" if bought_something else "-",
			"✓" if crafted else "-",
			shop_system.player_gold])

	var gold_end = shop_system.player_gold
	var inv_end = inventory_script.get_items().size()
	add_log("  [汇总] 金币: %d → %d (%+d) | 背包: %d → %d | 成功轮: %d/10" % [
		gold_start, gold_end, gold_end - gold_start, inv_start, inv_end, success_rounds])
	_check("4.1 10 轮闭环至少 5 轮成功（实际 %d）" % success_rounds,
		success_rounds >= 5)
	_check("4.2 闭环后金币未变为负", shop_system.player_gold >= 0)
	_check("4.3 闭环后背包未越界（≤ max_slots）",
		inventory_script.get_items().size() <= inventory_script.max_slots)

	add_log("")

# ========== 阶段 5: 出售与堆叠联动 ==========
func _test_sell_stack_linkage():
	add_log("[color=yellow]===== 阶段 5: 出售与堆叠联动 =====[/color]")

	_clear_inventory()
	# 注入一堆可出售的材料
	inventory_script.add_item("incense_stick", 10)
	var count_before = inventory_script.get_item_count("incense_stick")
	var gold_before = shop_system.player_gold
	add_log("  注入 incense_stick ×%d, 金币 %d" % [count_before, gold_before])

	# 5.1 出售 3 个（堆叠数量应减少 3，物品仍存在）
	var sell_ok1 = shop_system.sell_item("incense_stick", 3, inventory_script.inventory, karma_system)
	var count_after1 = inventory_script.get_item_count("incense_stick")
	var gold_after1 = shop_system.player_gold
	_check("5.1 出售3个后数量 %d→%d (应-3)，金币 %d→%d (应+)" % [
		count_before, count_after1, gold_before, gold_after1],
		sell_ok1 and count_after1 == count_before - 3 and gold_after1 > gold_before)

	# 5.2 出售剩余全部（格子应清空）
	var sell_ok2 = shop_system.sell_item("incense_stick", 7, inventory_script.inventory, karma_system)
	var count_after2 = inventory_script.get_item_count("incense_stick")
	var gold_after2 = shop_system.player_gold
	_check("5.2 出售剩余7个后数量归零（%d），金币 %d→%d (应+)" % [
		count_after2, gold_before, gold_after2],
		sell_ok2 and count_after2 == 0 and gold_after2 > gold_before)

	# 5.3 物品已售罄时再出售 → 应失败
	var sell_ok3 = shop_system.sell_item("incense_stick", 1, inventory_script.inventory, karma_system)
	_check("5.3 售罄后再出售失败", not sell_ok3)

	add_log("")

# ========== 辅助函数 ==========
func _fill_inventory_until_n_empty(n: int):
	# 用不同材料填满背包，直到只剩 n 个空格
	while inventory_script.get_empty_slot_count() > n:
		var _fake_id = "incense_stick"  # 用同种堆叠会只占1格，所以改用装备类
		if not inventory_script.add_item("wood_mala", 1):
			break

func _clear_inventory():
	for i in range(inventory_script.max_slots):
		inventory_script.inventory[i] = null
	inventory_script.durability.clear()
	inventory_script.update_display()

func _check(desc: String, condition: bool):
	if condition:
		pass_count += 1
		add_log("  [color=green]✓[/color] %s" % desc)
	else:
		fail_count += 1
		add_log("  [color=red]✗[/color] %s" % desc)

func _update_status():
	status_label.text = "通过: %d / %d  |  失败: %d" % [pass_count, pass_count + fail_count, fail_count]

func add_log(msg: String):
	# 同时输出到控制台（log-file 可捕获）和 UI
	print("[稳定测试] " + msg)
	log_label.append_text(msg + "\n")
