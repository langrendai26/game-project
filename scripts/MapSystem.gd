extends Node
class_name MapSystem

# ========== 三界地图探索系统 ==========
# 佛教三界：欲界、色界、无色界
# 每界有多个地点，不同地点有不同的机缘与考验

signal location_discovered(location_id: String, location_name: String)
signal location_entered(location_id: String, location_name: String)
signal event_triggered(event_data: Dictionary)
signal realm_changed(new_realm: int)

# ========== 三界定义 ==========
var three_realms = {
	"desire": {
		"name": "欲界",
		"icon": "🏯",
		"description": "有情世界，充满欲望与烦恼，是修行的起点",
		"locations": {
			"village": {
				"name": "贫苦村落",
				"description": "众生困苦，急需救助",
				"karma_type": "good",
				"karma_reward": {"merit": 10},
				"sin_risk": 0.1,
				"recommended_level": 1,
				"events": ["beggar", "sick_person", "orphan", "earthquake"]
			},
			"market": {
				"name": "繁华集市",
				"description": "热闹非凡，众生百态",
				"karma_type": "neutral",
				"karma_reward": {"merit": 5},
				"sin_risk": 0.3,
				"recommended_level": 1,
				"events": ["merchant", "thief", "kind_stranger", "temptation"]
			},
			"temple": {
				"name": "古刹名寺",
				"description": "清净道场，高僧云集",
				"karma_type": "good",
				"karma_reward": {"merit": 20},
				"sin_risk": 0.05,
				"recommended_level": 2,
				"events": ["monk", "dharma_preaching", "pilgrim", "scripture_found"]
			},
			"forest": {
				"name": "深山密林",
				"description": "野兽出没，亦可修行",
				"karma_type": "mixed",
				"karma_reward": {"merit": 15},
				"sin_risk": 0.25,
				"recommended_level": 2,
				"events": ["wild_beast", "hermit", "hidden_cave", "poacher"]
			},
			"river": {
				"name": "清净河流",
				"description": "水流潺潺，洗涤身心",
				"karma_type": "good",
				"karma_reward": {"merit": 8},
				"sin_risk": 0.1,
				"recommended_level": 1,
				"events": ["fisherman", "drowning", "lotus_gatherer", "reflection"]
			},
			"mountain": {
				"name": "灵山之巅",
				"description": "云雾缭绕，仙人遗迹",
				"karma_type": "good",
				"karma_reward": {"merit": 25},
				"sin_risk": 0.15,
				"recommended_level": 3,
				"events": ["sage", "relic", "meditation_spot", "vision"]
			}
		}
	},
	"form": {
		"name": "色界",
		"icon": "🌄",
		"description": "清净世界，已离欲念，修行更为深入",
		"locations": {
			"brahma_palace": {
				"name": "梵天宫",
				"description": "梵王所居，清净庄严",
				"karma_type": "good",
				"karma_reward": {"merit": 50},
				"sin_risk": 0.0,
				"recommended_level": 5,
				"events": ["brahma_teaches", "celestial_music", "wisdom_gift", "merit_gift"]
			},
			"meditation_hall": {
				"name": "禅定精舍",
				"description": "诸佛禅定之所，助你入定",
				"karma_type": "good",
				"karma_reward": {"merit": 40},
				"sin_risk": 0.0,
				"recommended_level": 4,
				"events": ["deep_meditation", "teachings", "inner_light", "samadhi"]
			},
			"healing_garden": {
				"name": "疗愈花园",
				"description": "天香满溢，疗愈身心",
				"karma_type": "good",
				"karma_reward": {"merit": 35},
				"sin_risk": 0.0,
				"recommended_level": 4,
				"events": ["healing", "fragrance", "medicine", "blessing"]
			},
			"debate_hall": {
				"name": "法辩讲堂",
				"description": "诸佛弟子辩论法义",
				"karma_type": "good",
				"karma_reward": {"merit": 45},
				"sin_risk": 0.05,
				"recommended_level": 5,
				"events": ["dharma_debate", "wisdom_blessing", "teachings", "skill_test"]
			},
			"stupa": {
				"name": "佛塔圣地",
				"description": "诸佛舍利所在，极圣之地",
				"karma_type": "good",
				"karma_reward": {"merit": 80},
				"sin_risk": 0.0,
				"recommended_level": 6,
				"events": ["relic_blessing", "vision_of_buddha", "merit_surge", "inner_peace"]
			}
		}
	},
	"formless": {
		"name": "无色界",
		"icon": "☯️",
		"description": "无形无色，纯精神世界，修行至高境界",
		"locations": {
			"emptiness": {
				"name": "虚空藏",
				"description": "空性境界，万法皆空",
				"karma_type": "neutral",
				"karma_reward": {"merit": 100},
				"sin_risk": 0.0,
				"recommended_level": 8,
				"events": ["emptiness_realization", "dharma_vision", "release", "truth"]
			},
			"consciousness": {
				"name": "识无边处",
				"description": "心识无量，照见一切",
				"karma_type": "good",
				"karma_reward": {"merit": 120},
				"sin_risk": 0.0,
				"recommended_level": 9,
				"events": ["consciousness_expansion", "omniscience", "compassion_surge", "wisdom_peak"]
			},
			"nothingness": {
				"name": "无所有处",
				"description": "一切无有，诸法寂灭",
				"karma_type": "neutral",
				"karma_reward": {"merit": 150},
				"sin_risk": 0.0,
				"recommended_level": 10,
				"events": ["nothingness_realization", "nirvana_gaze", "liberation", "final_truth"]
			},
			"pure_land": {
				"name": "极乐净土",
				"description": "阿弥陀佛净土，究竟解脱之地",
				"karma_type": "perfect",
				"karma_reward": {"merit": 300},
				"sin_risk": 0.0,
				"recommended_level": 10,
				"events": ["amituo_vision", "lotus_birth", "dharma_reception", "transcendence"]
			}
		}
	}
}

# 境界等级
var realm_desire = 0
var realm_form = 1
var realm_formless = 2

# 状态
var current_realm: int = realm_desire
var current_location: String = ""
var discovered_locations: Dictionary = {}
var visited_locations: Dictionary = {}
var total_explorations: int = 0
var total_merit_from_exploration: int = 0

# 地点访问冷却
var location_cooldowns: Dictionary = {}

# 随机事件文本库
var event_texts = {
	"beggar": "一位衣衫褴褛的乞丐向你走来，伸出双手。",
	"sick_person": "路边躺着一位患病的老者，气息微弱。",
	"orphan": "一个孤儿在街角哭泣，无人照料。",
	"earthquake": "忽然地动山摇，村中房屋倒塌！",
	"merchant": "一位商人在摆摊，售卖着各种货物。",
	"thief": "一个小偷正在偷取他人财物！",
	"kind_stranger": "一位慈祥的陌生人向你微笑。",
	"temptation": "你遇到了极大的诱惑，考验你的定力。",
	"monk": "一位高僧向你微笑，似有话要说。",
	"dharma_preaching": "僧人们正在开示佛法，众生云集。",
	"pilgrim": "一位朝圣者向你问路，他要去参拜圣地。",
	"scripture_found": "你发现了一卷古老的佛经！",
	"wild_beast": "一只凶猛的野兽向你扑来！",
	"hermit": "一位隐士在洞中修行，他邀请你入内。",
	"hidden_cave": "你发现了一个隐秘的山洞，似有异样。",
	"poacher": "一个猎人正准备射杀一只小鹿。",
	"fisherman": "一位渔夫在河边捕鱼。",
	"drowning": "有人落水呼救，情况危急！",
	"lotus_gatherer": "有人在采摘莲花，你上前相助。",
	"reflection": "你在水边照见自己的倒影，若有所思。",
	"sage": "一位白发苍苍的老人坐在山巅，仙风道骨。",
	"relic": "你发现了一块疑似佛舍利的碎片！",
	"meditation_spot": "这里似乎是过去诸佛的禅修之地。",
	"vision": "云雾散开，你看到了不可思议的景象！",
	"brahma_teaches": "梵天王亲自为你开示佛法奥义。",
	"celestial_music": "天乐奏响，天女散花，供养于你。",
	"wisdom_gift": "一位天人赠予你智慧之果。",
	"merit_gift": "诸天赞叹你的功德，赐予你福报。",
	"deep_meditation": "你进入了甚深禅定，见到内在光明。",
	"teachings": "你听闻了珍贵的佛法教义。",
	"inner_light": "你的内心升起了灿烂的光芒。",
	"samadhi": "你证得了三昧，身心安泰。",
	"healing": "神圣的光芒疗愈了你的身心。",
	"fragrance": "天香扑鼻，你感到身心清净。",
	"medicine": "你获得了珍贵的疗愈良药。",
	"blessing": "你得到了护法善神的祝福。",
	"dharma_debate": "你参与了一场精彩的法义辩论。",
	"wisdom_blessing": "智慧降临，你对佛法有了更深的理解。",
	"skill_test": "你的修行受到了考验，你通过了！",
	"relic_blessing": "佛舍利放出光芒，照耀于你。",
	"vision_of_buddha": "你亲眼见到了佛陀的真身！",
	"merit_surge": "你的功德急剧增长！",
	"inner_peace": "你的内心获得了前所未有的安宁。",
	"emptiness_realization": "你悟入了空性，万法皆空。",
	"dharma_vision": "你见到了诸法实相。",
	"release": "你获得了暂时的解脱体验。",
	"truth": "你窥见了真理的一角。",
	"consciousness_expansion": "你的心识扩展到了无边无际。",
	"omniscience": "你获得了短暂的全知体验。",
	"compassion_surge": "你的慈悲心无量无边。",
	"wisdom_peak": "智慧达到了前所未有的高峰。",
	"nothingness_realization": "你证入了无所有处。",
	"nirvana_gaze": "你瞥见了涅槃的境界。",
	"liberation": "你获得了解脱的体验。",
	"final_truth": "你触碰到了最终的真理。",
	"amituo_vision": "阿弥陀佛出现在你面前，金光万丈。",
	"lotus_birth": "你坐于莲台之上，身放光明。",
	"dharma_reception": "你亲闻佛陀传授甚深妙法。",
	"transcendence": "你超越了生死轮回！"
}

var realm_names = {"desire": "欲界", "form": "色界", "formless": "无色界"}
var realm_keys = ["desire", "form", "formless"]

func _ready():
	add_to_group("map")
	for realm_key in three_realms:
		for loc_id in three_realms[realm_key]["locations"]:
			discovered_locations[loc_id] = false
			visited_locations[loc_id] = 0

# ========== 探索核心 ==========

func explore_location(location_id: String, karma_system = null, skill_system = null) -> Dictionary:
	var result = {"success": false, "messages": [], "events": []}
	
	var location_data = _find_location(location_id)
	if location_data.is_empty():
		result["messages"].append("未知地点: " + location_id)
		return result
	
	# 冷却检查
	var cooldown = location_cooldowns.get(location_id, 0.0)
	var now = Time.get_ticks_msec() / 1000.0
	if cooldown > now:
		var remaining = cooldown - now
		result["messages"].append("「%s」正在恢复中，还需 %.0f 秒" % [location_data["name"], remaining])
		return result
	
	# 设置冷却（10-30秒随机）
	location_cooldowns[location_id] = now + randf_range(10, 30)
	
	# 发现地点
	if not discovered_locations.get(location_id, false):
		discovered_locations[location_id] = true
		result["messages"].append("🗺️ 发现新地点：「%s」" % location_data["name"])
		location_discovered.emit(location_id, location_data["name"])
	
	# 进入地点
	current_location = location_id
	location_entered.emit(location_id, location_data["name"])
	
	# 触发随机事件
	var events = location_data.get("events", [])
	var total_gold = 0
	var all_items = []
	if events.size() > 0:
		var event_id = events[randi() % events.size()]
		var event_result = _process_event(event_id, location_data, karma_system, skill_system)
		result["events"].append(event_result)
		result["messages"].append(event_result.get("text", ""))
		total_gold += event_result.get("gold_gained", 0)
		all_items.append_array(event_result.get("items_gained", []))

	# 汇总金币和物品到结果
	result["gold_gained"] = total_gold
	result["items_gained"] = all_items

	# 累计统计
	visited_locations[location_id] = visited_locations.get(location_id, 0) + 1
	total_explorations += 1

	result["success"] = true
	result["location"] = location_data["name"]
	return result

func _process_event(event_id: String, location_data: Dictionary, karma_system = null, skill_system = null) -> Dictionary:
	var result = {"event_id": event_id, "text": "", "karma_change": {}, "items_gained": [], "gold_gained": 0}

	var text = event_texts.get(event_id, "你在这里经历了一些事。")
	result["text"] = text

	var karma_reward = location_data.get("karma_reward", {})
	var sin_risk = location_data.get("sin_risk", 0.0)

	var merit_change = karma_reward.get("merit", 0)

	# 金币奖励：地点级 gold_reward 优先，否则按境界默认值
	var realm = location_data.get("realm", "desire")
	var gold_reward = location_data.get("gold_reward", {})
	var gold_min = gold_reward.get("min", 0)
	var gold_max = gold_reward.get("max", 0)
	if gold_min == 0 and gold_max == 0:
		match realm:
			"desire":
				gold_min = 10
				gold_max = 30
			"form":
				gold_min = 40
				gold_max = 80
			"formless":
				gold_min = 100
				gold_max = 200
	var gold_gained = int(randf_range(gold_min, gold_max))
	result["gold_gained"] = gold_gained
	
	# 根据地点类型调整
	var karma_type = location_data.get("karma_type", "neutral")
	match karma_type:
		"good":
			merit_change += int(randf_range(5, 15))
		"mixed":
			if randf() < 0.5:
				merit_change += int(randf_range(3, 10))
			else:
				sin_risk += 0.1
		"perfect":
			merit_change += int(randf_range(20, 50))
	
	# 风险：可能造恶业
	if randf() < sin_risk and karma_type != "perfect":
		var sin_amount = int(randf_range(3, 15))
		if karma_system:
			karma_system.add_sin(sin_amount, "探索「%s」遭遇恶缘" % location_data.get("name", ""))
		result["karma_change"]["sin"] = sin_amount
		result["text"] += " [color=red]你遭遇了恶缘，罪孽+%d[/color]" % sin_amount
	else:
		# 获得功德
		if merit_change > 0:
			if karma_system:
				karma_system.add_merit(merit_change, "探索「%s」" % location_data.get("name", ""))
			result["karma_change"]["merit"] = merit_change
			result["text"] += " [color=green]功德+%d[/color]" % merit_change
			total_merit_from_exploration += merit_change
	
	# 特殊事件效果
	match event_id:
		"beggar", "orphan", "sick_person":
			if randf() < 0.7:
				var gift = _get_random_item("供品", realm)
				result["items_gained"].append(gift)
				result["text"] += " 你救助了他人，心生欢喜。"
		"scripture_found", "relic":
			result["items_gained"].append({"id": "sutra_fragment", "name": "佛经残片"})
			result["text"] += " [color=yellow]你获得了珍贵物品！[/color]"
		"wild_beast":
			if randf() < 0.6:
				var gift = _get_random_item("材料", realm)
				result["items_gained"].append(gift)
		"healing", "medicine":
			result["items_gained"].append({"id": "herb_medicine", "name": "药草"})
		"relic_blessing", "vision_of_buddha", "amituo_vision":
			# 极高等级奖励
			if karma_system:
				karma_system.add_merit(100, "佛菩萨加持")
			result["karma_change"]["merit"] = result["karma_change"].get("merit", 0) + 100
			result["text"] += " [color=yellow]✨ 佛菩萨加持！功德+100[/color]"
	
	if skill_system:
		var skill_result = skill_system.use_skill("recite_sutra", karma_system)
		if skill_result.get("success", false):
			result["text"] += " 你的修行技能也得到了锻炼。"

	# 显示金币奖励
	if gold_gained > 0:
		result["text"] += " [color=yellow]💰 金币+%d[/color]" % gold_gained

	result["text"] += " [color=gray]（地点：%s）[/color]" % location_data.get("name", "")
	
	event_triggered.emit(result)
	return result

func _get_random_item(category: String, realm: String = "desire") -> Dictionary:
	# 按境界分级的掉落池（所有 ID 均在 Inventory.item_database 中存在）
	var items_by_category = {
		"供品": [
			{"id": "incense_stick", "name": "香枝"},
			{"id": "flower_offering", "name": "鲜花"},
			{"id": "pure_water", "name": "净水"}
		],
		"材料_desire": [
			{"id": "sandalwood_powder", "name": "檀香粉"},
			{"id": "honey", "name": "蜂蜜"},
			{"id": "lotus_petal", "name": "莲瓣"},
			{"id": "incense_powder", "name": "香粉"},
			{"id": "herb_medicine", "name": "药草"},
			{"id": "incense_ash", "name": "香灰"}
		],
		"材料_form": [
			{"id": "wisdom_grass", "name": "慧草"},
			{"id": "sutra_fragment", "name": "经文残片"},
			{"id": "sacred_ash", "name": "圣灰"},
			{"id": "compassion_banner", "name": "慈悲幡"},
			{"id": "bodhi_seed", "name": "菩提子"}
		],
		"材料_formless": [
			{"id": "longevity_herb", "name": "长生草"},
			{"id": "golden_flower", "name": "金莲花"},
			{"id": "sandalwood_log", "name": "檀香木"},
			{"id": "relic_fragment", "name": "舍利碎片"}
		]
	}
	# 根据境界选择材料池
	var pool_key = category
	if category == "材料":
		match realm:
			"form":
				pool_key = "材料_form"
			"formless":
				pool_key = "材料_formless"
			_:
				pool_key = "材料_desire"
	var category_items = items_by_category.get(pool_key, [{"id": "incense_ash", "name": "香灰"}])
	return category_items[randi() % category_items.size()]

func _find_location(location_id: String) -> Dictionary:
	for realm_key in three_realms:
		var locations = three_realms[realm_key]["locations"]
		if locations.has(location_id):
			var data = locations[location_id].duplicate()
			data["realm"] = realm_key
			return data
	return {}

# 公开接口：按 ID 查询地点数据
func get_location(location_id: String) -> Dictionary:
	return _find_location(location_id)

# ========== 境界升级 ==========

func try_upgrade_realm(karma_system, precept_system) -> Dictionary:
	var result = {"upgraded": false, "from": current_realm, "to": current_realm}
	
	if current_realm >= realm_formless:
		result["message"] = "你已在最高境界"
		return result
	
	var required_merit = [500, 3000][current_realm]
	var required_precept = [4, 5][current_realm]
	var net_karma = karma_system.get_net_karma()
	var kept_count = precept_system.get_kept_precept_count() if precept_system else 0
	
	if net_karma >= required_merit and kept_count >= required_precept:
		var old_realm = current_realm
		current_realm += 1
		result["upgraded"] = true
		result["from"] = old_realm
		result["to"] = current_realm
		result["message"] = "🌟 你已证入「%s」！" % get_realm_name(current_realm)
		realm_changed.emit(current_realm)
	else:
		var reason = ""
		if net_karma < required_merit:
			reason += "净业力不足（需%d，当前%d）" % [required_merit, net_karma]
		if kept_count < required_precept:
			if reason != "":
				reason += "；"
			reason += "持戒不足（需%d戒清净，当前%d）" % [required_precept, kept_count]
		result["message"] = "境界提升条件未满足：%s" % reason
	
	return result

# ========== 查询方法 ==========

func get_current_realm_name() -> String:
	var keys = ["desire", "form", "formless"]
	return realm_names.get(keys[current_realm], "未知")

func get_realm_name(realm: int) -> String:
	var keys = ["desire", "form", "formless"]
	if realm >= 0 and realm < keys.size():
		return realm_names.get(keys[realm], "未知")
	return "未知"

func get_current_realm_data() -> Dictionary:
	var keys = ["desire", "form", "formless"]
	var key = keys[current_realm]
	return three_realms.get(key, {})

func get_available_locations() -> Array:
	var result = []
	var realm_data = get_current_realm_data()
	var locations = realm_data.get("locations", {})
	
	for loc_id in locations:
		var loc = locations[loc_id]
		var discovered = discovered_locations.get(loc_id, false)
		var visited = visited_locations.get(loc_id, 0)
		var cooldown = location_cooldowns.get(loc_id, 0.0)
		var now = Time.get_ticks_msec() / 1000.0
		
		result.append({
			"id": loc_id,
			"name": loc["name"],
			"description": loc["description"],
			"recommended_level": loc["recommended_level"],
			"karma_type": loc["karma_type"],
			"merit_reward": loc["karma_reward"].get("merit", 0),
			"sin_risk": loc["sin_risk"],
			"discovered": discovered,
			"visited_count": visited,
			"cooldown_remaining": max(0.0, cooldown - now)
		})
	
	return result

func get_exploration_stats() -> Dictionary:
	return {
		"current_realm": get_current_realm_name(),
		"total_explorations": total_explorations,
		"total_merit": total_merit_from_exploration,
		"discovered_count": discovered_locations.values().filter(func(x): return x).size(),
		"total_locations": discovered_locations.size(),
		"visited_details": visited_locations
	}

# ========== 持久化 ==========

func save_to_data(data: Dictionary):
	data["current_realm"] = current_realm
	data["discovered_locations"] = discovered_locations
	data["visited_locations"] = visited_locations
	data["total_explorations"] = total_explorations
	data["total_merit_from_exploration"] = total_merit_from_exploration

func load_from_data(data: Dictionary):
	if data.has("current_realm"):
		current_realm = data["current_realm"]
	if data.has("discovered_locations"):
		discovered_locations = data["discovered_locations"]
	if data.has("visited_locations"):
		visited_locations = data["visited_locations"]
	if data.has("total_explorations"):
		total_explorations = data["total_explorations"]
	if data.has("total_merit_from_exploration"):
		total_merit_from_exploration = data["total_merit_from_exploration"]
