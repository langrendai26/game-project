extends Control
class_name MainGameScene

# === 系统引用 ===
var karma_system: KarmaSystem = null
var precept_system: PreceptSystem = null
var rebirth_system: RebirthSystem = null
var quest_system: Node = null
var skill_system: Node = null
var alchemy_system: Node = null
var map_system: Node = null

# === UI 节点 ===
@onready var title_label = $CanvasLayer/TopPanel/TitleLabel
@onready var status_label = $CanvasLayer/TopPanel/StatusLabel

# 业力面板
@onready var karma_panel = $CanvasLayer/KarmaPanel
@onready var merit_value_label = $CanvasLayer/KarmaPanel/MeritValueLabel
@onready var sin_value_label = $CanvasLayer/KarmaPanel/SinValueLabel
@onready var net_karma_label = $CanvasLayer/KarmaPanel/NetKarmaLabel
@onready var karma_level_label = $CanvasLayer/KarmaPanel/KarmaLevelLabel
@onready var karma_bar = $CanvasLayer/KarmaPanel/KarmaBar

# 戒律面板
@onready var precept_panel = $CanvasLayer/PreceptPanel
@onready var precept_0 = $CanvasLayer/PreceptPanel/Precept0
@onready var precept_1 = $CanvasLayer/PreceptPanel/Precept1
@onready var precept_2 = $CanvasLayer/PreceptPanel/Precept2
@onready var precept_3 = $CanvasLayer/PreceptPanel/Precept3
@onready var precept_4 = $CanvasLayer/PreceptPanel/Precept4
@onready var kept_count_label = $CanvasLayer/PreceptPanel/KeptCountLabel
@onready var merit_bonus_label = $CanvasLayer/PreceptPanel/MeritBonusLabel

# 轮回面板
@onready var rebirth_panel = $CanvasLayer/RebirthPanel
@onready var three_realm_label = $CanvasLayer/RebirthPanel/ThreeRealmLabel
@onready var realm_label = $CanvasLayer/RebirthPanel/RealmLabel
@onready var sub_realm_label = $CanvasLayer/RebirthPanel/SubRealmLabel
@onready var age_label = $CanvasLayer/RebirthPanel/AgeLabel
@onready var liberation_bar = $CanvasLayer/RebirthPanel/LiberationBar
@onready var rebirth_count_label = $CanvasLayer/RebirthPanel/RebirthCountLabel

# 操作按钮
@onready var actions_panel = $CanvasLayer/ActionsPanel
@onready var btn_save_animal = $CanvasLayer/ActionsPanel/GridBtn/BtnSaveAnimal
@onready var btn_donate = $CanvasLayer/ActionsPanel/GridBtn/BtnDonate
@onready var btn_offer = $CanvasLayer/ActionsPanel/GridBtn/BtnOffer
@onready var btn_recite_sutra = $CanvasLayer/ActionsPanel/GridBtn/BtnReciteSutra
@onready var btn_recite_mantra = $CanvasLayer/ActionsPanel/GridBtn/BtnReciteMantra
@onready var btn_meditate = $CanvasLayer/ActionsPanel/GridBtn/BtnMeditate
@onready var btn_keep_precept = $CanvasLayer/ActionsPanel/GridBtn/BtnKeepPrecept
@onready var btn_confess = $CanvasLayer/ActionsPanel/GridBtn/BtnConfess
@onready var btn_time_pass = $CanvasLayer/ActionsPanel/GridBtn/BtnTimePass
@onready var btn_do_evil = $CanvasLayer/ActionsPanel/GridBtn/BtnDoEvil

# 日志面板
@onready var log_label = $CanvasLayer/LogPanel/LogLabel

# 打开背包/任务
@onready var btn_open_inventory = $CanvasLayer/BottomBar/BtnOpenInventory
@onready var btn_open_quest = $CanvasLayer/BottomBar/BtnOpenQuest

# 新增：修行/探索按钮（动态添加或通过代码管理）
var inventory_panel: Node = null
var quest_panel: Node = null
var skill_panel: Node = null
var alchemy_panel: Node = null
var map_panel: Node = null

func _ready():
	_init_systems()
	_connect_signals()
	_setup_buttons()
	_refresh_all_ui()
	add_log("=== 🙏 三界模拟器 ===")
	add_log("愿一切众生离苦得乐，究竟解脱！")
	add_log("当前：" + rebirth_system.get_current_status()["realm_name"])

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
	
	# 任务系统
	quest_system = load("res://scripts/Quest.gd").new()
	quest_system.name = "QuestSystem"
	add_child(quest_system)
	
	# 技能系统
	skill_system = SkillSystem.new()
	skill_system.name = "SkillSystem"
	add_child(skill_system)
	
	# 炼丹系统
	alchemy_system = AlchemySystem.new()
	alchemy_system.name = "AlchemySystem"
	add_child(alchemy_system)
	
	# 地图系统
	map_system = load("res://scripts/MapSystem.gd").new()
	map_system.name = "MapSystem"
	add_child(map_system)

func _connect_signals():
	karma_system.karma_changed.connect(_on_karma_changed)
	karma_system.level_changed.connect(_on_karma_level_changed)
	precept_system.precept_broken.connect(_on_precept_broken)
	precept_system.precept_restored.connect(_on_precept_restored)
	precept_system.merit_bonus_changed.connect(_on_merit_bonus_changed)
	rebirth_system.realm_changed.connect(_on_realm_changed)
	rebirth_system.lifespan_changed.connect(_on_lifespan_changed)
	rebirth_system.transcended_samsara.connect(_on_transcended)
	
	# 技能系统
	skill_system.skill_used.connect(_on_skill_used)
	skill_system.skill_level_changed.connect(_on_skill_level_changed)
	
	# 炼丹系统
	alchemy_system.system_message.connect(_on_alchemy_message)
	alchemy_system.pill_crafted.connect(_on_pill_crafted)
	
	# 地图系统
	map_system.location_entered.connect(_on_location_entered)
	map_system.location_discovered.connect(_on_location_discovered)
	map_system.event_triggered.connect(_on_map_event)

func _setup_buttons():
	btn_save_animal.pressed.connect(func(): _do_action_save_animal())
	btn_donate.pressed.connect(func(): _do_action_donate())
	btn_offer.pressed.connect(func(): _do_action_offer())
	btn_recite_sutra.pressed.connect(func(): _do_action_recite_sutra())
	btn_recite_mantra.pressed.connect(func(): _do_action_recite_mantra())
	btn_meditate.pressed.connect(func(): _do_action_meditate())
	btn_keep_precept.pressed.connect(func(): _do_action_keep_precept())
	btn_confess.pressed.connect(func(): _do_action_confess())
	btn_time_pass.pressed.connect(func(): _do_action_time_pass())
	btn_do_evil.pressed.connect(func(): _do_action_do_evil())
	
	btn_open_inventory.pressed.connect(func(): _open_inventory())
	btn_open_quest.pressed.connect(func(): _open_quest())
	
	# 在底部动态添加新按钮
	_add_bottom_button("🧘 修行", func(): _open_skill_panel())
	_add_bottom_button("🧪 炼丹", func(): _open_alchemy_panel())
	_add_bottom_button("🌍 地图", func(): _open_map_panel())

func _add_bottom_button(text: String, callback: Callable):
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(80, 30)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.pressed.connect(callback)
	
	var bottom_bar = $CanvasLayer/BottomBar
	if bottom_bar:
		# 获取底部栏的最后一个子节点的位置
		var child_count = bottom_bar.get_child_count()
		if child_count > 0:
			var last_child = bottom_bar.get_child(child_count - 1)
			btn.position = Vector2(last_child.position.x + last_child.size.x + 15, last_child.position.y)
		else:
			btn.position = Vector2(10, 10)
		btn.size = Vector2(80, 30)
		bottom_bar.add_child(btn)
	else:
		add_child(btn)
		btn.position = Vector2(10, 500)

# ========== 行为系统 ==========

func _do_action_save_animal():
	karma_system.do_good_action("save_animal")
	add_log("🕊️ 你解救了一个生命，放归自然。善根增长！")
	_precept_system_do_ten_good(0)  # 身善·不杀生

func _do_action_donate():
	karma_system.do_good_action("donate_money")
	karma_system.do_good_action("donate_food")
	add_log("💰🍞 你布施钱财与饮食予穷苦之人。")
	_precept_system_do_ten_good(7)  # 意善·不贪

func _do_action_offer():
	karma_system.do_good_action("offer_to_buddha")
	karma_system.do_good_action("offer_to_monk")
	add_log("🪔 你以香花灯果供养佛法僧三宝。")
	_add_random_offering_item()

func _do_action_recite_sutra():
	karma_system.do_good_action("recite_sutra")
	add_log("📿 你诵持一卷经文，法音宣流，智慧渐开。")
	_precept_system_do_ten_good(3)  # 口善·不妄语

func _do_action_recite_mantra():
	var amount = int(randf_range(30, 108))
	var bonus = precept_system.calculate_merit_with_bonus(amount)
	karma_system.add_merit(bonus, "持咒 %d 遍" % amount)
	add_log("🕉️ 你持咒 %d 遍，声声入耳，念念入心。" % amount)

func _do_action_meditate():
	karma_system.do_good_action("meditation")
	add_log("🧘 你端身正坐，禅定片刻。妄念渐息，心渐清净。")
	_precept_system_do_ten_good(8)  # 意善·不嗔
	_precept_system_do_ten_good(9)  # 意善·不痴

func _do_action_keep_precept():
	var kept = precept_system.get_kept_precept_count()
	var broken_ids = []
	for i in range(5):
		if not precept_system.is_precept_kept(i):
			broken_ids.append(i)
	
	if broken_ids.size() > 0:
		var id = broken_ids[0]
		if precept_system.restore_precept(id, karma_system):
			add_log("🙌 你发心受持：%s！愿从今以往，终不毁犯。" % precept_system.get_precept_name(id))
	else:
		if kept >= 5:
			add_log("🪷 五戒清净，甚为稀有！继续保持。")
			karma_system.add_merit(precept_system.calculate_merit_with_bonus(30), "五戒清净")

func _do_action_confess():
	var confessed = false
	for i in range(5):
		if precept_system.confess(i, karma_system):
			add_log("😢 你至诚忏悔：往昔所造诸恶业，皆由无始贪嗔痴。")
			confessed = true
			break
	if not confessed:
		add_log("🫖 你无戒可忏，身心清净，善哉善哉。")
		karma_system.add_merit(5, "常自忏悔")

func _do_action_time_pass():
	var years = int(randf_range(1, 5))
	var result = rebirth_system.advance_time(years, karma_system, precept_system)
	add_log("⏳ 时间流逝：过去了 %d 年。" % years)
	
	if result["rebirth_occurred"]:
		var reb = result["rebirth_result"]
		if result["is_liberated"]:
			add_log("🌟🌟🌟 %s 🌟🌟🌟" % reb["reason"])
		else:
			add_log("💀 寿命已尽，命终投胎...")
			add_log("👉 投生：%s · %s" % [rebirth_system.get_three_realm_name(reb["three_realm"]), reb["reason"]])
			# 轮回后重置部分业力
			karma_system.add_sin(int(karma_system.sin_value * 0.3), "轮回余报")
			karma_system.add_merit(int(karma_system.merit * 0.5), "轮回余福")

func _do_action_do_evil():
	# 随机造作一些恶业
	var evil_list = ["insult", "gossip", "greedy", "hateful", "delusion", "waste_food"]
	var evil_id = evil_list[randi() % evil_list.size()]
	karma_system.do_evil_action(evil_id)
	
	# 破戒几率
	if randf() < 0.4:
		var p_id = randi() % 5
		precept_system.break_precept(p_id, karma_system)
	
	var evil_name = karma_system.evil_actions.get(evil_id, {}).get("name", "恶业")
	add_log("😈 你生起烦恼，造作：%s。当勤忏悔！" % evil_name)

func _precept_system_do_ten_good(action_id: int):
	precept_system.perform_ten_good(action_id, karma_system)

func _add_random_offering_item():
	# 随机获得一些供品作为佛力加持
	var offerings = ["incense_stick", "lotus_flower", "pure_water", "fruit_offering"]
	var id = offerings[randi() % offerings.size()]
	var inv = get_tree().get_first_node_in_group("inventory")
	if inv and inv.has_method("add_item"):
		inv.add_item(id)
		add_log("  (佛赐供品×1)")

# ========== UI 刷新 ==========

func _refresh_all_ui():
	_refresh_karma_ui()
	_refresh_precept_ui()
	_refresh_rebirth_ui()

func _refresh_karma_ui():
	if not karma_system:
		return
	
	merit_value_label.text = "功德\n%d" % karma_system.merit
	sin_value_label.text = "罪孽\n%d" % karma_system.sin_value
	var net = karma_system.get_net_karma()
	net_karma_label.text = "净业力: %+d" % net
	karma_level_label.text = karma_system.get_karma_level_name()
	karma_level_label.modulate = karma_system.get_karma_color()
	
	# 进度条：-10000 ~ 10000 映射到 0~1
	var ratio = clampf((float(net) + 10000.0) / 20000.0, 0.0, 1.0)
	karma_bar.value = ratio * 100.0

func _refresh_precept_ui():
	if not precept_system:
		return
	
	var precept_labels = [precept_0, precept_1, precept_2, precept_3, precept_4]
	for i in range(5):
		var label = precept_labels[i]
		if label:
			var pname = precept_system.get_precept_name(i)
			var kept = precept_system.is_precept_kept(i)
			var count = precept_system.precepts_violation_count[i]
			if kept:
				label.text = "✅ %s (犯 %d 次)" % [pname.replace("戒", ""), count]
				label.modulate = Color(0.4, 0.8, 0.4)
			else:
				label.text = "❌ %s (犯 %d 次)" % [pname.replace("戒", ""), count]
				label.modulate = Color(0.9, 0.4, 0.4)
	
	var kept_count = precept_system.get_kept_precept_count()
	kept_count_label.text = "持戒: %d/5  |  清净度: %d%%" % [kept_count, int(precept_system.get_precept_purity() * 100)]
	merit_bonus_label.text = "功德加成: +%d%%" % int((precept_system.precept_merit_bonus - 1.0) * 100)

func _refresh_rebirth_ui():
	if not rebirth_system:
		return
	
	var status = rebirth_system.get_current_status()
	three_realm_label.text = status["three_realm_name"]
	realm_label.text = status["realm_name"]
	realm_label.modulate = rebirth_system.get_realm_color(status["realm"])
	sub_realm_label.text = "现居: " + status["sub_realm_name"]
	age_label.text = "寿命: %d / %d  (余 %d)" % [status["age"], status["lifespan"], status["remaining_lifespan"]]
	rebirth_count_label.text = "轮回次数: %d" % status["rebirth_count"]
	
	var progress = rebirth_system.get_liberation_progress(karma_system, precept_system)
	liberation_bar.value = progress * 100.0

# ========== 信号回调 ==========

func _on_karma_changed(_merit: int, _sin: int):
	_refresh_karma_ui()

func _on_karma_level_changed(_new_level: int):
	add_log("🎐 业力境界变化：现为「%s」" % karma_system.get_karma_level_name())

func _on_precept_broken(_p_id: int, p_name: String):
	add_log("⚠️ 破戒！「%s」当速忏悔！" % p_name)
	_refresh_precept_ui()

func _on_precept_restored(_p_id: int, p_name: String):
	add_log("🕊️ 重受「%s」，回头是岸！" % p_name)
	_refresh_precept_ui()

func _on_merit_bonus_changed(_bonus: float):
	_refresh_precept_ui()

func _on_realm_changed(new_realm: int, _old_realm: int):
	add_log("🌍 现生处：%s" % rebirth_system.get_realm_name(new_realm))
	_refresh_rebirth_ui()

func _on_lifespan_changed(_remaining: int, _total: int):
	_refresh_rebirth_ui()

func _on_transcended():
	add_log("✨✨✨ 恭喜！超越三界，永离轮回！✨✨✨")
	_refresh_rebirth_ui()

# ========== 日志 ==========

func add_log(message: String):
	log_label.text += "\n" + message
	log_label.scroll_following = true
	print("[三界] " + message)

# ========== 打开背包 / 任务 ==========

func _open_inventory():
	if inventory_panel and is_instance_valid(inventory_panel):
		inventory_panel.queue_free()
		inventory_panel = null
	
	var inv_scene = load("res://scripts/InventoryScene.tscn")
	if inv_scene:
		inventory_panel = inv_scene.instantiate()
		add_child(inventory_panel)
		add_log("🎒 打开背包")

func _open_quest():
	if quest_panel and is_instance_valid(quest_panel):
		quest_panel.queue_free()
		quest_panel = null
	
	var q_scene = load("res://scripts/QuestScene.tscn")
	if q_scene:
		quest_panel = q_scene.instantiate()
		add_child(quest_panel)
		add_log("📜 打开任务列表")

# ========== 打开修行/炼丹/地图面板 ==========

func _open_skill_panel():
	if skill_panel and is_instance_valid(skill_panel):
		skill_panel.queue_free()
		skill_panel = null
	
	var panel = Control.new()
	panel.name = "SkillPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.set_offsets(Vector2(-250, -200), Vector2(250, 200))
	panel.modulate = Color(0.95, 0.95, 0.95, 0.98)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var title = Label.new()
	title.text = "🧘 修行技能"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.position = Vector2(10, 5)
	title.size = Vector2(480, 30)
	panel.add_child(title)
	
	var container = VBoxContainer.new()
	container.position = Vector2(10, 40)
	container.size = Vector2(480, 330)
	container.add_theme_constant_override("separation", 8)
	
	for skill in skill_system.get_all_skills():
		var row = HBoxContainer.new()
		var name_lbl = Label.new()
		name_lbl.text = "%s %s Lv.%d" % [skill["icon"], skill["name"], skill["level"]]
		name_lbl.custom_minimum_size = Vector2(130, 0)
		var exp_bar = ProgressBar.new()
		exp_bar.max_value = skill["required_exp"]
		exp_bar.value = skill["exp"]
		exp_bar.custom_minimum_size = Vector2(100, 15)
		var detail = Label.new()
		detail.text = skill["effect"]
		detail.add_theme_font_size_override("font_size", 11)
		detail.modulate = Color(0.6, 0.6, 0.6)
		
		row.add_child(name_lbl)
		row.add_child(exp_bar)
		row.add_child(detail)
		container.add_child(row)
	
	var close_btn = Button.new()
	close_btn.text = "关闭"
	close_btn.position = Vector2(210, 360)
	close_btn.size = Vector2(70, 30)
	close_btn.pressed.connect(func(): if skill_panel: skill_panel.queue_free(); skill_panel = null)
	
	panel.add_child(container)
	panel.add_child(close_btn)
	add_child(panel)
	skill_panel = panel
	add_log("🧘 打开修行技能面板")

func _open_alchemy_panel():
	if alchemy_panel and is_instance_valid(alchemy_panel):
		alchemy_panel.queue_free()
		alchemy_panel = null
	
	var panel = Control.new()
	panel.name = "AlchemyPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.set_offsets(Vector2(-250, -200), Vector2(250, 200))
	panel.modulate = Color(0.95, 0.95, 0.95, 0.98)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var title = Label.new()
	title.text = "🧪 炼丹坊"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.position = Vector2(10, 5)
	title.size = Vector2(480, 30)
	panel.add_child(title)
	
	var craft_info = Label.new()
	var status = alchemy_system.get_craft_status()
	craft_info.text = "炼制等级: %d | 成功率: %.1f%% | 已炼制: %d" % [
		status["craft_level"], status["success_rate"] * 100, status["total_crafts"]]
	craft_info.position = Vector2(10, 35)
	craft_info.size = Vector2(480, 20)
	craft_info.modulate = Color(0.5, 0.5, 0.5)
	panel.add_child(craft_info)
	
	var container = VBoxContainer.new()
	container.position = Vector2(10, 60)
	container.size = Vector2(480, 290)
	container.add_theme_constant_override("separation", 6)
	
	for recipe in alchemy_system.get_recipe_list():
		var row = HBoxContainer.new()
		var name_lbl = Label.new()
		name_lbl.text = "%s %s [%s]" % [recipe["icon"], recipe["name"], recipe["tier_name"]]
		name_lbl.custom_minimum_size = Vector2(140, 0)
		var owned_lbl = Label.new()
		owned_lbl.text = "持有: %d" % recipe["owned"]
		owned_lbl.custom_minimum_size = Vector2(60, 0)
		var effect_lbl = Label.new()
		effect_lbl.text = recipe["effects"].get("description", "")
		effect_lbl.add_theme_font_size_override("font_size", 10)
		effect_lbl.modulate = Color(0.6, 0.6, 0.6)
		effect_lbl.custom_minimum_size = Vector2(140, 0)
		
		var craft_btn = Button.new()
		craft_btn.text = "炼制"
		craft_btn.custom_minimum_size = Vector2(50, 0)
		craft_btn.pressed.connect(func():
			var r = alchemy_system.start_crafting(recipe["id"], get_tree().get_first_node_in_group("inventory"), skill_system)
			if r:
				add_log("🔥 开始炼制「%s」" % recipe["name"])
		)
		
		var use_btn = Button.new()
		use_btn.text = "服用"
		use_btn.custom_minimum_size = Vector2(50, 0)
		use_btn.pressed.connect(func():
			var r = alchemy_system.use_pill(recipe["id"], karma_system, rebirth_system)
			for m in r.get("messages", []):
				add_log(m)
		)
		use_btn.disabled = recipe["owned"] <= 0
		
		row.add_child(name_lbl)
		row.add_child(owned_lbl)
		row.add_child(effect_lbl)
		row.add_child(craft_btn)
		row.add_child(use_btn)
		container.add_child(row)
	
	var close_btn = Button.new()
	close_btn.text = "关闭"
	close_btn.position = Vector2(210, 360)
	close_btn.size = Vector2(70, 30)
	close_btn.pressed.connect(func(): if alchemy_panel: alchemy_panel.queue_free(); alchemy_panel = null)
	
	panel.add_child(container)
	panel.add_child(close_btn)
	add_child(panel)
	alchemy_panel = panel
	add_log("🧪 打开炼丹坊")

func _open_map_panel():
	if map_panel and is_instance_valid(map_panel):
		map_panel.queue_free()
		map_panel = null
	
	var panel = Control.new()
	panel.name = "MapPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.set_offsets(Vector2(-280, -220), Vector2(280, 220))
	panel.modulate = Color(0.92, 0.92, 0.95, 0.98)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var title = Label.new()
	title.text = "🌍 三界地图 · %s" % map_system.get_current_realm_name()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.position = Vector2(10, 5)
	title.size = Vector2(540, 30)
	panel.add_child(title)
	
	var container = VBoxContainer.new()
	container.position = Vector2(10, 40)
	container.size = Vector2(540, 340)
	container.add_theme_constant_override("separation", 6)
	
	for loc in map_system.get_available_locations():
		var row = HBoxContainer.new()
		var name_lbl = Label.new()
		var prefix = "🗺️" if loc["discovered"] else "❓"
		name_lbl.text = "%s %s (等级%d)" % [prefix, loc["name"], loc["recommended_level"]]
		name_lbl.custom_minimum_size = Vector2(180, 0)
		var merit_lbl = Label.new()
		merit_lbl.text = "功德+%d" % loc["merit_reward"]
		merit_lbl.add_theme_font_size_override("font_size", 11)
		merit_lbl.modulate = Color(0.4, 0.7, 0.4)
		merit_lbl.custom_minimum_size = Vector2(80, 0)
		var risk_lbl = Label.new()
		risk_lbl.text = "风险:%.0f%%" % (loc["sin_risk"] * 100)
		risk_lbl.add_theme_font_size_override("font_size", 11)
		risk_lbl.modulate = Color(0.7, 0.4, 0.4) if loc["sin_risk"] > 0.2 else Color(0.5, 0.5, 0.5)
		risk_lbl.custom_minimum_size = Vector2(70, 0)
		
		var explore_btn = Button.new()
		explore_btn.text = "探索"
		explore_btn.custom_minimum_size = Vector2(55, 0)
		explore_btn.disabled = loc["cooldown_remaining"] > 0
		explore_btn.pressed.connect(func():
			var r = map_system.explore_location(loc["id"], karma_system, skill_system)
			for e in r.get("events", []):
				for m in e.get("messages", []):
					add_log(m)
			for m in r.get("messages", []):
				add_log(m)
			# 领取探索金币奖励
			var gold = r.get("gold_gained", 0)
			var _shop = get_tree().get_first_node_in_group("shop")
			if gold > 0 and _shop:
				_shop.player_gold += gold
				add_log("💰 探索获得金币 +%d（当前：%d）" % [gold, _shop.player_gold])
			# 领取探索掉落物品
			var _inv = get_tree().get_first_node_in_group("inventory")
			for item in r.get("items_gained", []):
				if item is Dictionary and item.has("id"):
					var ok = _inv.add_item(item["id"])
					if ok:
						add_log("📦 获得物品：%s" % item.get("name", item["id"]))
		)
		
		row.add_child(name_lbl)
		row.add_child(merit_lbl)
		row.add_child(risk_lbl)
		row.add_child(explore_btn)
		container.add_child(row)
	
	# 境界升级按钮
	var upgrade_btn = Button.new()
	upgrade_btn.text = "🌟 尝试提升境界"
	upgrade_btn.position = Vector2(10, 390)
	upgrade_btn.size = Vector2(120, 30)
	upgrade_btn.pressed.connect(func():
		var r = map_system.try_upgrade_realm(karma_system, precept_system)
		add_log(r["message"])
	)
	
	var close_btn = Button.new()
	close_btn.text = "关闭"
	close_btn.position = Vector2(240, 390)
	close_btn.size = Vector2(70, 30)
	close_btn.pressed.connect(func(): if map_panel: map_panel.queue_free(); map_panel = null)
	
	panel.add_child(container)
	panel.add_child(upgrade_btn)
	panel.add_child(close_btn)
	add_child(panel)
	map_panel = panel
	add_log("🌍 打开三界地图")

# ========== 新系统信号回调 ==========

func _on_skill_used(_skill_id: String, result: Dictionary):
	for msg in result.get("messages", []):
		add_log(msg)
	if result.get("level_up", false):
		_refresh_skill_ui()

func _on_skill_level_changed(skill_id: String, new_level: int):
	var skill_name = skill_system.skills_data.get(skill_id, {}).get("name", skill_id)
	add_log("[color=yellow]🎊 「%s」升级到 %d 级！[/color]" % [skill_name, new_level])

func _on_alchemy_message(msg: String):
	add_log(msg)

func _on_pill_crafted(pill_id: String, success: bool, qty: int):
	var pill_name = alchemy_system.get_pill_name(pill_id)
	if success:
		add_log("[color=green]🎉 炼制成功：%s × %d[/color]" % [pill_name, qty])
	else:
		add_log("[color=red]💨 炼制失败：%s[/color]" % pill_name)

func _on_location_entered(_location_id: String, location_name: String):
	add_log("🌍 进入「%s」" % location_name)

func _on_location_discovered(_location_id: String, location_name: String):
	add_log("[color=yellow]🗺️ 发现新地点：「%s」[/color]" % location_name)

func _on_map_event(_event_data: Dictionary):
	pass

func _refresh_skill_ui():
	if skill_panel:
		_open_skill_panel()

# ========== 每帧更新（炼制进度等） ==========

func _process(delta: float):
	if alchemy_system and alchemy_system.is_crafting:
		var result = alchemy_system.update_crafting(delta)
		if result.get("completed", false):
			if result.get("success", false):
				add_log("[color=green]🎉 炼制完成！[/color]")
			else:
				add_log("[color=red]💨 炼制失败[/color]")