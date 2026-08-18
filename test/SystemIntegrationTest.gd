extends Control

# 三界模拟器 · 综合系统集成测试
# 测试技能系统、炼丹系统、地图探索系统与业力系统的联动

var karma_system: KarmaSystem = null
var precept_system: PreceptSystem = null
var rebirth_system: RebirthSystem = null
var skill_system: SkillSystem = null
var alchemy_system: AlchemySystem = null
var map_system: MapSystem = null
var inventory_script: Node = null
var shop_system: Node = null

# UI 节点
var log_label: RichTextLabel = null
var status_label: Label = null
var progress_label: Label = null

func _ready():
	_build_ui()
	_init_systems()
	await get_tree().create_timer(0.3).timeout
	_run_auto_tests()

func _build_ui():
	# 背景
	var bg = ColorRect.new()
	bg.color = Color(0.06, 0.05, 0.08)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# 标题
	var title = Label.new()
	title.text = "🌍 三界模拟器 · 系统集成测试"
	title.position = Vector2(20, 8)
	title.size = Vector2(900, 36)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.5))
	add_child(title)
	
	# 状态栏
	status_label = Label.new()
	status_label.text = "初始化中..."
	status_label.position = Vector2(20, 48)
	status_label.size = Vector2(900, 28)
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.7))
	add_child(status_label)
	
	# 进度标签
	progress_label = Label.new()
	progress_label.text = ""
	progress_label.position = Vector2(20, 75)
	progress_label.size = Vector2(900, 22)
	progress_label.add_theme_font_size_override("font_size", 12)
	progress_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.9))
	add_child(progress_label)
	
	# 日志面板
	var log_panel = Panel.new()
	log_panel.position = Vector2(20, 105)
	log_panel.size = Vector2(880, 450)
	log_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(log_panel)
	
	var log_title = Label.new()
	log_title.text = "【测试日志】"
	log_title.position = Vector2(10, 5)
	log_title.size = Vector2(200, 24)
	log_title.add_theme_font_size_override("font_size", 15)
	log_title.add_theme_color_override("font_color", Color(0.8, 0.7, 0.4))
	log_panel.add_child(log_title)
	
	log_label = RichTextLabel.new()
	log_label.position = Vector2(10, 28)
	log_label.size = Vector2(860, 410)
	log_label.text = ""
	log_label.scroll_following = true
	log_label.bbcode_enabled = true
	log_panel.add_child(log_label)
	
	# 按钮栏
	var btn_panel = Panel.new()
	btn_panel.position = Vector2(20, 565)
	btn_panel.size = Vector2(880, 120)
	add_child(btn_panel)
	
	var grid = GridContainer.new()
	grid.columns = 4
	grid.position = Vector2(10, 8)
	grid.size = Vector2(860, 105)
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	btn_panel.add_child(grid)
	
	var btn_specs = [
		["🧘 测试技能系统", _test_skill_system],
		["🧪 测试炼丹系统", _test_alchemy_system],
		["🌍 测试地图探索", _test_map_system],
		["🔄 测试系统联动", _test_system_integration],
		["📈 测试业力变化", _test_karma_changes],
		["💊 测试丹药服用", _test_pill_usage],
		["🏔️ 测试境界升级", _test_realm_upgrade],
		["▶️ 运行全部测试", _run_all_tests],
		["🧹 清空日志", _clear_log],
	]
	
	for spec in btn_specs:
		var btn = Button.new()
		btn.text = spec[0]
		btn.custom_minimum_size = Vector2(210, 28)
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

	# 轮回系统
	rebirth_system = RebirthSystem.new()
	rebirth_system.name = "RebirthSystem"
	add_child(rebirth_system)

	# 技能系统
	skill_system = SkillSystem.new()
	skill_system.name = "SkillSystem"
	add_child(skill_system)

	# 炼丹系统
	alchemy_system = AlchemySystem.new()
	alchemy_system.name = "AlchemySystem"
	add_child(alchemy_system)

	# 地图系统
	map_system = MapSystem.new()
	map_system.name = "MapSystem"
	add_child(map_system)

	# 商店系统（使用默认金币 1000，不硬编码）
	var shop_script = load("res://scripts/Shop.gd")
	shop_system = shop_script.new()
	shop_system.name = "ShopSystem"
	add_child(shop_system)

	# 背包系统（使用真实 init_inventory 初始化，不手动注入物品）
	var inv_script = load("res://scripts/Inventory.gd")
	inventory_script = inv_script.new()
	inventory_script.name = "TestInventory"
	add_child(inventory_script)

	# 通过真实游戏流程获取炼丹材料：从商店购买
	# 按配方优先级排列，金币不足时优先购买低价基础材料
	# purchase_item 现在原子完成：扣金币 + 加背包（或校验失败回滚）
	add_log("--- 真实流程：从法物流通处购买炼丹材料 ---")
	var purchase_plan = [
		["sandalwood_powder", 3], ["pure_water", 5], ["honey", 2],
		["lotus_petal", 4], ["incense_powder", 2], ["wisdom_grass", 3],
		["sutra_fragment", 3], ["sacred_ash", 4], ["compassion_banner", 1],
		["golden_flower", 3], ["longevity_herb", 3]
	]
	var gold_before = shop_system.player_gold
	for entry in purchase_plan:
		var item_id = entry[0]
		var want_qty = entry[1]
		# 查单价，计算金币允许的实际购买量
		var item_data = shop_system.shop_database[shop_system.ShopType.GENERAL]["items"].get(item_id, {})
		if item_data.is_empty():
			add_log("  [color=red]✗ 商店无此物品: %s[/color]" % item_id)
			continue
		var unit_price = item_data["price"]
		var max_affordable = shop_system.player_gold / unit_price if unit_price > 0 else want_qty
		var buy_qty = min(want_qty, max_affordable)
		if buy_qty <= 0:
			add_log("  [color=yellow]⚠ 金币不足，跳过: %s（需 %d×%d=%d，余额 %d）[/color]" % [
				item_id, unit_price, want_qty, unit_price * want_qty, shop_system.player_gold])
			continue
		# 传入 inventory_script，让 purchase_item 原子完成（扣金币 + 校验容量 + 入包 + 回滚）
		var ok = shop_system.purchase_item(shop_system.ShopType.GENERAL, item_id, buy_qty, inventory_script)
		if not ok:
			add_log("  [color=red]✗ 购买失败: %s × %d[/color]" % [item_id, buy_qty])
	var gold_spent = gold_before - shop_system.player_gold
	add_log("  购买完成，花费金币: %d（剩余: %d）| 背包: %d 件" % [
		gold_spent, shop_system.player_gold, inventory_script.get_items().size()])

	# 连接信号
	skill_system.skill_used.connect(func(sid, r): add_log("  [技能] %s → %s" % [sid, r.get("messages", [""])[0]]))
	skill_system.skill_level_changed.connect(func(sid, lv): add_log("  [技能] %s 升级到 %d 级！" % [sid, lv]))
	alchemy_system.system_message.connect(func(msg): add_log("  [炼丹] %s" % msg))
	alchemy_system.pill_crafted.connect(func(pid, sc, q): add_log("  [炼丹] %s: %s × %d" % [pid, "成功" if sc else "失败", q]))
	map_system.location_entered.connect(func(_lid, ln): add_log("  [地图] 进入 %s" % ln))
	map_system.location_discovered.connect(func(_lid, ln): add_log("  [地图] 发现新地点: %s" % ln))
	map_system.event_triggered.connect(func(_ed): pass)

	_update_status()
	add_log("=== 系统集成测试环境初始化完成（真实数据）===")
	add_log("初始 | 功德: %d | 罪孽: %d | 金币: %d | 背包: %d 件" % [
		karma_system.merit, karma_system.sin_value, shop_system.player_gold, inventory_script.get_items().size()])
	add_log("")

func _run_auto_tests():
	add_log(">>> 启动自动运行全部测试 <<<")
	await _run_all_tests()
	add_log(">>> 自动测试结束，5秒后退出 <<<")
	await get_tree().create_timer(5.0).timeout
	get_tree().quit()

# ========== 测试：技能系统 ==========
func _test_skill_system():
	add_log("========== 测试：技能系统 ==========")
	
	var skills = skill_system.get_all_skills()
	add_log("已加载技能: %d 个" % skills.size())
	
	# 测试每个技能
	var skill_ids = ["recite_sutra", "recite_mantra", "meditation", "dana", "chant"]
	for sid in skill_ids:
		var level_before = skill_system.get_skill_level(sid)
		var _exp_before = skill_system.get_skill_exp(sid)
		var result = skill_system.use_skill(sid, karma_system, precept_system, rebirth_system)
		
		if result.get("success", false):
			var merit_gain = result.get("gains", {}).get("merit", 0)
			var sin_removed = result.get("gains", {}).get("sin_removed", 0)
			var level_after = skill_system.get_skill_level(sid)
			add_log("[color=green]✓[/color] %s | Lv.%d→%d | 功德+%d | 罪孽-%d" % [
				skill_system.skills_data.get(sid, {}).get("name", sid),
				level_before, level_after, merit_gain, sin_removed])
		else:
			add_log("[color=red]✗[/color] %s 失败: %s" % [sid, result.get("messages", [""])[0]])
	
	# 测试技能信息查询
	var sutra_info = skill_system.get_skill_info("recite_sutra")
	add_log("诵经信息: Lv.%d | 经验: %d/%d | 效果: %s" % [
		sutra_info["level"], sutra_info["exp"], sutra_info["required_exp"], sutra_info["effect"]])
	
	# 测试升级
	var total_merit_before = karma_system.merit
	for i in range(20):
		skill_system.use_skill("chant", karma_system)
	var total_merit_after = karma_system.merit
	add_log("念佛20次后 | 功德变化: %+d" % (total_merit_after - total_merit_before))
	
	# 测试技能冷却
	var cooldown = skill_system.get_skill_cooldown_remaining("meditation")
	add_log("坐禅冷却剩余: %.1f 秒" % cooldown)
	
	# 累计统计
	var stats = skill_system.get_total_cultivation_stats()
	add_log("累计修行: %d次, 总功德: %d, 总消业: %d" % [
		stats["total_uses"].values().reduce(func(a, b): return a + b, 0),
		stats["total_merit"], stats["total_sin_removed"]])
	
	_update_status()

# ========== 测试：炼丹系统 ==========
func _test_alchemy_system():
	add_log("========== 测试：炼丹系统 ==========")
	
	var recipes = alchemy_system.get_recipe_list()
	add_log("可用丹方: %d 个" % recipes.size())
	
	# 显示丹方信息
	for recipe in recipes:
		add_log("  %s [%s] | 炼制等级: %.1f%% | 持有: %d" % [
			recipe["name"], recipe["tier_name"],
			recipe["success_rate"] * 100, recipe["owned"]])
	
	# 尝试炼制定心丹（材料充足）
	add_log("\n尝试炼制「定心丹」...")
	var result = alchemy_system.start_crafting("calming_pill", inventory_script, skill_system)
	if result:
		add_log("[color=green]✓ 炼制已开始[/color]")
		# 模拟完成炼制
		await get_tree().create_timer(0.5).timeout
		var craft_result = alchemy_system.update_crafting(0.5)
		add_log("炼制状态: %s, 进度: %.0f%%" % [
			"完成" if craft_result.get("completed", false) else "进行中",
			craft_result.get("progress", 0) * 100])
		
		# 如果还在炼制，手动完成
		if not craft_result.get("completed", false):
			var final_result = alchemy_system.update_crafting(100)
			if final_result.get("success", false):
				add_log("[color=green]🎉 炼制成功！[/color]")
			else:
				add_log("[color=red]💨 炼制失败[/color]")
	else:
		add_log("[color=yellow]材料不足或正在炼制中[/color]")
	
	# 测试炼制状态查询
	var status = alchemy_system.get_craft_status()
	add_log("炼制等级: %d | 累计炼制: %d | 成功率: %.1f%%" % [
		status["craft_level"], status["total_crafts"], status["success_rate"] * 100])
	
	# 服用已炼制的丹药
	var pills = alchemy_system.get_recipe_list()
	for p in pills:
		if p["owned"] > 0:
			add_log("\n尝试服用「%s」..." % p["name"])
			var use_result = alchemy_system.use_pill(p["id"], karma_system, rebirth_system)
			for msg in use_result.get("messages", []):
				add_log("  %s" % msg)
			break
	
	_update_status()

# ========== 测试：地图探索系统 ==========
func _test_map_system():
	add_log("========== 测试：地图探索系统 ==========")
	
	var locations = map_system.get_available_locations()
	add_log("当前境界: %s" % map_system.get_current_realm_name())
	add_log("可用地点: %d 个" % locations.size())
	
	for loc in locations:
		var status = "已发现" if loc["discovered"] else "未发现"
		add_log("  %s %s (等级%d) | 功德+%d | 风险%.0f%%" % [
			status, loc["name"], loc["recommended_level"],
			loc["merit_reward"], loc["sin_risk"] * 100])
	
	# 探索多个不同地点（验证金币/物品循环获取）
	var explore_count = min(locations.size(), 3)
	if explore_count > 0:
		var gold_before_explore = shop_system.player_gold
		var inv_before_explore = inventory_script.get_items().size()
		add_log("\n探索 %d 个不同地点（验证金币/物品获取）..." % explore_count)
		var total_gold_from_explore = 0
		var items_from_explore = 0
		for i in range(explore_count):
			var loc = locations[i]
			var result = map_system.explore_location(loc["id"], karma_system, skill_system)
			for msg in result.get("messages", []):
				add_log("  %s" % msg)
			for event in result.get("events", []):
				add_log("  事件: %s" % event.get("text", ""))
				if event.get("karma_change", {}).has("merit"):
					add_log("  [color=green]功德+%d[/color]" % event["karma_change"]["merit"])
				if event.get("karma_change", {}).has("sin"):
					add_log("  [color=red]罪孽+%d[/color]" % event["karma_change"]["sin"])
			# 领取金币
			var gold = result.get("gold_gained", 0)
			if gold > 0:
				shop_system.player_gold += gold
				total_gold_from_explore += gold
			# 领取物品
			for item in result.get("items_gained", []):
				if item is Dictionary and item.has("id"):
					var ok = inventory_script.add_item(item["id"])
					if ok:
						items_from_explore += 1
		add_log("  [color=yellow]探索%d次共获得金币: +%d | 物品: +%d 件[/color]" % [explore_count, total_gold_from_explore, items_from_explore])
		add_log("  金币: %d → %d | 背包: %d → %d 件" % [
			gold_before_explore, shop_system.player_gold,
			inv_before_explore, inventory_script.get_items().size()])
	
	# 测试探索统计
	var stats = map_system.get_exploration_stats()
	add_log("\n探索统计:")
	add_log("  当前境界: %s" % stats["current_realm"])
	add_log("  总探索次数: %d" % stats["total_explorations"])
	add_log("  功德累计: %d" % stats["total_merit"])
	add_log("  已发现地点: %d/%d" % [stats["discovered_count"], stats["total_locations"]])
	
	# 测试发现状态
	var loc_data = map_system.get_location("village")
	if not loc_data.is_empty():
		var discovered = map_system.discovered_locations.get("village", false)
		add_log("  村落发现状态: %s" % ("已发现 ✓" if discovered else "未发现"))
	
	_update_status()

# ========== 测试：系统联动 ==========
func _test_system_integration():
	add_log("========== 测试：系统联动 ==========")
	
	var merit_before = karma_system.merit
	var sin_before = karma_system.sin_value
	var skill_level_before = skill_system.get_skill_level("recite_sutra")
	var craft_level_before = alchemy_system.craft_level
	
	# 1. 使用技能 → 增加功德
	add_log("\n1. 诵经（技能）→ 增加功德")
	skill_system.use_skill("recite_sutra", karma_system, precept_system, rebirth_system)
	
	# 2. 功德变化触发业力等级变化
	add_log("2. 业力等级: %s" % karma_system.get_karma_level_name())
	
	# 3. 使用丹药 → 功德+消业障
	add_log("3. 尝试服用定心丹...")
	var recipes = alchemy_system.get_recipe_list()
	for r in recipes:
		if r["owned"] > 0 and r["id"] == "calming_pill":
			var result = alchemy_system.use_pill(r["id"], karma_system, rebirth_system)
			for msg in result.get("messages", []):
				add_log("  %s" % msg)
			break
	
	# 4. 地图探索 → 随机触发功德/罪孽变化
	add_log("4. 地图探索 → 随机业力变化")
	var locations = map_system.get_available_locations()
	if locations.size() > 0:
		map_system.explore_location(locations[0]["id"], karma_system, skill_system)
	
	# 5. 汇总变化
	var merit_after = karma_system.merit
	var sin_after = karma_system.sin_value
	add_log("\n联动测试结果:")
	add_log("  功德: %d → %d (%+d)" % [merit_before, merit_after, merit_after - merit_before])
	add_log("  罪孽: %d → %d (%+d)" % [sin_before, sin_after, sin_after - sin_before])
	add_log("  诵经等级: Lv.%d → Lv.%d" % [skill_level_before, skill_system.get_skill_level("recite_sutra")])
	add_log("  炼制等级: %d → %d" % [craft_level_before, alchemy_system.craft_level])
	
	var net = karma_system.get_net_karma()
	add_log("  净业力: %+d" % net)
	add_log("  业力境界: %s" % karma_system.get_karma_level_name())
	
	_update_status()

# ========== 测试：业力变化 ==========
func _test_karma_changes():
	add_log("========== 测试：业力变化 ==========")
	
	var _merit_before = karma_system.merit
	var _sin_before = karma_system.sin_value

	# 测试各种善业
	var good_actions = ["save_animal", "donate_money", "donate_food", "offer_to_buddha", "meditation", "recite_sutra", "forgive_other", "teach_dharma"]
	add_log("\n测试善业行为:")
	for action_id in good_actions:
		var result = karma_system.do_good_action(action_id)
		var action_data = karma_system.good_actions.get(action_id, {})
		var merit_gain = action_data.get("merit", 0)
		add_log("  %s: 功德+%d → %s" % [
			action_data.get("name", action_id), merit_gain,
			"[color=green]✓ 成功[/color]" if result else "[color=red]✗ 失败[/color]"])
	
	# 测试恶业
	var evil_actions = ["insult", "gossip", "greedy", "hateful", "delusion"]
	add_log("\n测试恶业行为（模拟造恶）:")
	for action_id in evil_actions:
		var action_data = karma_system.evil_actions.get(action_id, {})
		var sin_gain = action_data.get("sin", 0)
		add_log("  %s: 罪孽+%d (已记录)[color=gray] 不实际执行[/color]" % [
			action_data.get("name", action_id), sin_gain])
	
	# 实际测试一个恶业
	add_log("\n实际测试恶业:")
	var evil_result = karma_system.do_evil_action("waste_food")
	add_log("  浪费粮食: %s" % ("[color=red]✓ 罪孽+20[/color]" if evil_result else "失败"))
	
	# 测试净业力
	var net = karma_system.get_net_karma()
	add_log("\n当前业力状态:")
	add_log("  功德: %d" % karma_system.merit)
	add_log("  罪孽: %d" % karma_system.sin_value)
	add_log("  净业力: %+d" % net)
	add_log("  境界: %s" % karma_system.get_karma_level_name())
	add_log("  颜色: %s" % karma_system.get_karma_color())
	
	# 测试消业障
	add_log("\n测试消业障:")
	var before = karma_system.sin_value
	karma_system.purify_sin(5)
	add_log("  忏悔消业: 罪孽 %d → %d (-%d)" % [before, karma_system.sin_value, before - karma_system.sin_value])
	
	# 业力历史
	var history = karma_system.get_recent_history(5)
	add_log("\n最近业力记录（%d条）:" % history.size())
	for record in history:
		var type_icon = "📈" if record["type"] == "merit" else "📉"
		add_log("  %s %s: %d (%s)" % [type_icon, record["reason"], record["amount"], record["time"]])
	
	_update_status()

# ========== 测试：丹药服用 ==========
func _test_pill_usage():
	add_log("========== 测试：丹药服用 ==========")
	
	var recipes = alchemy_system.get_recipe_list()
	var available_pills = []
	for r in recipes:
		if r["owned"] > 0:
			available_pills.append(r)
	
	if available_pills.is_empty():
		add_log("[color=yellow]背包中没有丹药可服用[/color]")
		add_log("提示：先炼丹或在商店购买")
		# 显示可炼制的丹药
		add_log("\n可炼制丹药:")
		for r in recipes:
			var can_craft = _check_can_craft(r["id"])
			var craft_status = "✓ 可炼制" if can_craft else "✗ 材料不足"
			add_log("  %s [%s] %s" % [r["name"], r["tier_name"], craft_status])
		return
	
	add_log("可服用丹药: %d 种" % available_pills.size())
	
	for pill in available_pills:
		add_log("\n服用「%s」×1（持有%d）:" % [pill["name"], pill["owned"]])
		var result = alchemy_system.use_pill(pill["id"], karma_system, rebirth_system)
		for msg in result.get("messages", []):
			add_log("  %s" % msg)
	
	# 检查服用后效果
	add_log("\n服用后状态:")
	add_log("  功德: %d" % karma_system.merit)
	add_log("  罪孽: %d" % karma_system.sin_value)
	var status = rebirth_system.get_current_status()
	add_log("  寿命: %d / %d" % [status["age"], status["lifespan"]])
	
	_update_status()

func _check_can_craft(recipe_id: String) -> bool:
	var recipes = alchemy_system.get_recipe_list()
	for r in recipes:
		if r["id"] == recipe_id:
			var materials = r["materials"]
			for mat_id in materials:
				var needed = materials[mat_id]
				var owned = inventory_script.get_item_count(mat_id) if inventory_script else 0
				if owned < needed:
					return false
			return true
	return false

# ========== 测试：境界升级 ==========
func _test_realm_upgrade():
	add_log("========== 测试：境界升级 ==========")
	
	var current_realm = map_system.get_current_realm_name()
	add_log("当前境界: %s" % current_realm)
	add_log("当前持戒: %d/5" % precept_system.get_kept_precept_count())
	add_log("当前净业力: %+d" % karma_system.get_net_karma())
	
	# 尝试提升境界
	add_log("\n尝试提升境界:")
	var result = map_system.try_upgrade_realm(karma_system, precept_system)
	add_log("  结果: %s" % result["message"])
	
	if result.get("upgraded", false):
		add_log("[color=green]🎉 境界提升成功！[/color]")
	else:
		add_log("[color=yellow]条件不足，需要:[/color]")
		var target_realm = map_system.current_realm + 1
		var required_merit = [500, 3000][target_realm] if target_realm < 2 else 10000
		var required_precept = [4, 5][target_realm] if target_realm < 2 else 5
		add_log("  净业力 ≥ %d (当前 %+d)" % [required_merit, karma_system.get_net_karma()])
		add_log("  持戒 ≥ %d (当前 %d)" % [required_precept, precept_system.get_kept_precept_count()])
	
	# 尝试突破轮回
	add_log("\n轮回状态:")
	var rebirth_status = rebirth_system.get_current_status()
	add_log("  三界: %s" % rebirth_status["three_realm_name"])
	add_log("  道: %s" % rebirth_status["realm_name"])
	add_log("  寿命: %d/%d" % [rebirth_status["age"], rebirth_status["lifespan"]])
	add_log("  解脱进度: %.1f%%" % (rebirth_system.get_liberation_progress(karma_system, precept_system) * 100))
	
	# 时间流逝测试
	add_log("\n时间流逝10年：")
	var result2 = rebirth_system.advance_time(10, karma_system, precept_system)
	add_log("  年龄: %d" % rebirth_system.current_age)
	if result2.get("rebirth_occurred", false):
		add_log("  [color=yellow]发生了轮回！[/color]")
		add_log("  投生: %s" % result2.get("rebirth_result", {}).get("reason", ""))
	
	# 最终检查
	var net = karma_system.get_net_karma()
	add_log("\n最终状态:")
	add_log("  净业力: %+d → %s" % [net, karma_system.get_karma_level_name()])
	add_log("  境界: %s" % map_system.get_current_realm_name())
	add_log("  解脱进度: %.1f%%" % (rebirth_system.get_liberation_progress(karma_system, precept_system) * 100))
	
	_update_status()

# ========== 运行全部测试 ==========
func _run_all_tests():
	add_log("\n[color=yellow]==============================[/color]")
	add_log("[color=yellow]    开始综合系统测试    [/color]")
	add_log("[color=yellow]==============================[/color]")
	
	# 重置系统
	_init_systems()
	
	await get_tree().create_timer(0.2).timeout
	
	_test_skill_system()
	await get_tree().create_timer(0.2).timeout
	
	_test_alchemy_system()
	await get_tree().create_timer(0.2).timeout
	
	_test_map_system()
	await get_tree().create_timer(0.2).timeout
	
	_test_system_integration()
	await get_tree().create_timer(0.2).timeout
	
	_test_karma_changes()
	await get_tree().create_timer(0.2).timeout
	
	_test_pill_usage()
	await get_tree().create_timer(0.2).timeout
	
	_test_realm_upgrade()
	
	add_log("\n[color=green]==============================[/color]")
	add_log("[color=green]    综合测试完成！    [/color]")
	add_log("[color=green]==============================[/color]")

# ========== 辅助函数 ==========
func add_log(msg: String):
	log_label.text += msg + "\n"
	print("[集成测试] " + msg)

func _update_status():
	if karma_system and shop_system and inventory_script:
		status_label.text = "功德: %d | 罪孽: %d | 金币: %d | 背包: %d 件 | 技能: %d | 丹药: %d | 境界: %s" % [
			karma_system.merit, karma_system.sin_value,
			shop_system.player_gold,
			inventory_script.get_items().size(),
			skill_system.get_skill_level("recite_sutra"),
			alchemy_system.get_recipe_list().filter(func(r): return r["owned"] > 0).size(),
			map_system.get_current_realm_name()
		]

func _clear_log():
	log_label.text = ""
	add_log("日志已清空，请选择测试项目")