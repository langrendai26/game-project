extends Node
class_name AlchemySystem

# ========== 佛教丹药炼制系统 ==========
# 以佛教修行理念为核心，炼制具有特殊功效的丹药

signal pill_crafted(pill_id: String, success: bool, qty: int)
signal crafting_progress(percent: float)
signal system_message(msg: String)

# ========== 丹药配方 ==========
# 每个配方包含：材料、等级、功效、炼制时间、成功率
var pill_recipes = {
	"calming_pill": {
		"name": "定心丹",
		"icon": "🧪",
		"description": "安定心神，平息妄念",
		"tier": 1,
		"craft_time": 10,
		"base_success_rate": 0.9,
		"materials": {
			"sandalwood_powder": 2,
			"pure_water": 1
		},
		"effects": {
			"merit": 5,
			"stabilize_mind": true,
			"description": "服用后平息烦恼，功德+5"
		}
	},
	"wisdom_pill": {
		"name": "般若丹",
		"icon": "💊",
		"description": "开启智慧，明悟佛法",
		"tier": 2,
		"craft_time": 30,
		"base_success_rate": 0.75,
		"materials": {
			"wisdom_grass": 2,
			"sutra_fragment": 1,
			"honey": 1
		},
		"effects": {
			"merit": 15,
			"wisdom_boost": true,
			"description": "服用后智慧增长，功德+15"
		}
	},
	"compassion_pill": {
		"name": "大悲丹",
		"icon": "🪷",
		"description": "增长慈悲心，悲悯众生",
		"tier": 2,
		"craft_time": 45,
		"base_success_rate": 0.7,
		"materials": {
			"lotus_petal": 3,
			"pure_water": 2,
			"compassion_banner": 1
		},
		"effects": {
			"merit": 20,
			"compassion_boost": true,
			"description": "服用后慈悲心增长，功德+20"
		}
	},
	"purification_pill": {
		"name": "净化丹",
		"icon": "✨",
		"description": "净化身口意三业",
		"tier": 3,
		"craft_time": 60,
		"base_success_rate": 0.6,
		"materials": {
			"sacred_ash": 3,
			"pure_water": 3,
			"incense_powder": 2
		},
		"effects": {
			"merit": 25,
			"sin_reduction": 15,
			"purify_karma": true,
			"description": "服用后净化业障，功德+25，罪孽-15"
		}
	},
	"longevity_pill": {
		"name": "长寿丹",
		"icon": "🌟",
		"description": "延年益寿，精力充沛",
		"tier": 3,
		"craft_time": 80,
		"base_success_rate": 0.55,
		"materials": {
			"longevity_herb": 2,
			"golden_flower": 1,
			"pure_water": 2
		},
		"effects": {
			"lifespan": 2,
			"merit": 20,
			"description": "服用后寿命+2年，功德+20"
		}
	},
	"liberation_pill": {
		"name": "解脱丹",
		"icon": "🙏",
		"description": "解脱烦恼，趋向涅槃",
		"tier": 4,
		"craft_time": 120,
		"base_success_rate": 0.4,
		"materials": {
			"sutra_fragment": 3,
			"sacred_ash": 2,
			"lotus_petal": 3,
			"golden_flower": 1
		},
		"effects": {
			"merit": 50,
			"sin_reduction": 30,
			"liberation_boost": true,
			"description": "服用后趋向解脱，功德+50，罪孽-30"
		}
	},
	"buddha_pill": {
		"name": "佛元丹",
		"icon": "🪷",
		"description": "诸佛加持，功德圆满",
		"tier": 5,
		"craft_time": 180,
		"base_success_rate": 0.25,
		"materials": {
			"relic_fragment": 1,
			"sutra_fragment": 5,
			"sacred_ash": 3,
			"golden_flower": 3
		},
		"effects": {
			"merit": 100,
			"sin_reduction": 60,
			"liberation_boost": true,
			"description": "服用后功德圆满，功德+100，罪孽-60"
		}
	}
}

# 丹药等级对应名称
var tier_names = {1: "凡品", 2: "良品", 3: "上品", 4: "极品", 5: "佛品"}

# 炼制状态
var is_crafting: bool = false
var current_pill: String = ""
var craft_progress: float = 0.0
var craft_start_time: float = 0.0
var craft_duration: float = 0.0

# 炼制等级与累计统计
var craft_level: int = 1
var craft_experience: float = 0.0
var total_crafts: int = 0
var total_successes: int = 0
var total_failures: int = 0
var crafted_pills: Dictionary = {}  # pill_id -> total crafted

func _ready():
	add_to_group("alchemy")

# ========== 炼制核心 ==========

func start_crafting(pill_id: String, inventory = null, _skill_system = null) -> bool:
	if is_crafting:
		system_message.emit("正在炼制中，请稍候...")
		return false
	
	if not pill_recipes.has(pill_id):
		system_message.emit("未知丹药配方")
		return false
	
	var recipe = pill_recipes[pill_id]
	
	# 检查材料
	if not _check_materials(recipe["materials"], inventory):
		system_message.emit("材料不足，无法炼制「%s」" % recipe["name"])
		return false
	
	# 扣除材料
	_consume_materials(recipe["materials"], inventory)
	
	# 开始炼制
	is_crafting = true
	current_pill = pill_id
	craft_start_time = Time.get_ticks_msec() / 1000.0
	craft_duration = recipe["craft_time"]
	craft_progress = 0.0
	
	system_message.emit("🔥 开始炼制「%s」，预计 %.0f 秒" % [recipe["name"], craft_duration])
	return true

func update_crafting(_delta: float) -> Dictionary:
	var result = {"crafting": is_crafting, "progress": craft_progress}
	
	if not is_crafting:
		return result
	
	var elapsed = Time.get_ticks_msec() / 1000.0 - craft_start_time
	craft_progress = clampf(elapsed / craft_duration, 0.0, 1.0)
	result["progress"] = craft_progress
	crafting_progress.emit(craft_progress)
	
	# 炼制完成
	if craft_progress >= 1.0:
		is_crafting = false
		result["crafting"] = false
		result["completed"] = true
		var finish_result = _complete_crafting()
		result.update(finish_result)
	
	return result

func _complete_crafting() -> Dictionary:
	var pill_id = current_pill
	var recipe = pill_recipes[pill_id]
	
	# 计算成功率（炼制等级加成）
	var success_rate = recipe["base_success_rate"] + (craft_level - 1) * 0.03
	success_rate = min(success_rate, 0.95)
	
	var success = randf() < success_rate
	var result = {
		"pill_id": pill_id,
		"success": success,
		"pill_name": recipe["name"],
		"tier": recipe["tier"]
	}
	
	if success:
		var qty = 1
		# 低等级丹药有几率多产出
		if recipe["tier"] <= 2 and randf() < 0.2:
			qty = 2
		elif recipe["tier"] <= 3 and randf() < 0.1:
			qty = 2
		
		crafted_pills[pill_id] = crafted_pills.get(pill_id, 0) + qty
		total_successes += 1
		
		system_message.emit("[color=green]🎉 炼制成功！获得「%s」×%d[/color]" % [recipe["name"], qty])
		result["qty"] = qty
	else:
		total_failures += 1
		# 失败损失部分材料
		var lost_pct = 0.5
		system_message.emit("[color=red]💨 炼制失败！材料损失 %.0f%%[/color]" % (lost_pct * 100))
		result["qty"] = 0
	
	total_crafts += 1
	current_pill = ""
	
	# 增加炼制经验
	var exp_gain = recipe["tier"] * (10 if success else 3)
	_add_craft_experience(exp_gain)
	
	pill_crafted.emit(pill_id, success, result.get("qty", 0))
	return result

func cancel_crafting(inventory = null) -> bool:
	if not is_crafting:
		return false
	
	var recipe = pill_recipes[current_pill]
	# 返还一半材料
	for mat_id in recipe["materials"]:
		var amount = int(recipe["materials"][mat_id] * 0.5)
		if amount > 0 and inventory and inventory.has_method("add_item"):
			inventory.add_item(mat_id, amount)
	
	is_crafting = false
	current_pill = ""
	craft_progress = 0.0
	system_message.emit("⏸️ 炼制已取消，返还部分材料")
	return true

# ========== 材料管理 ==========

func _check_materials(required: Dictionary, inventory = null) -> bool:
	if not inventory:
		return false
	for mat_id in required:
		var needed = required[mat_id]
		var owned = _get_material_count(mat_id, inventory)
		if owned < needed:
			return false
	return true

func _consume_materials(required: Dictionary, inventory = null):
	if not inventory:
		return
	for mat_id in required:
		var amount = required[mat_id]
		_remove_material(mat_id, amount, inventory)

func _get_material_count(item_id: String, inventory) -> int:
	if not inventory:
		return 0
	var items = inventory.get_items() if inventory.has_method("get_items") else []
	var count = 0
	for item in items:
		if item != null and item.get("id", "") == item_id:
			count += item.get("quantity", 1)
	return count

func _remove_material(item_id: String, amount: int, inventory):
	if not inventory:
		return
	var items = inventory.inventory if "inventory" in inventory else []
	var remaining = amount
	for i in range(items.size()):
		if remaining <= 0:
			break
		if items[i] != null and items[i].get("id", "") == item_id:
			var qty = items[i].get("quantity", 1)
			if qty <= remaining:
				items[i] = null
				remaining -= qty
			else:
				items[i]["quantity"] = qty - remaining
				remaining = 0

# ========== 服用丹药 ==========

func use_pill(pill_id: String, karma_system = null, rebirth_system = null) -> Dictionary:
	var result = {"success": false, "messages": []}
	
	if not crafted_pills.has(pill_id) or crafted_pills[pill_id] <= 0:
		result["messages"].append("没有「%s」可服用" % get_pill_name(pill_id))
		return result
	
	if not pill_recipes.has(pill_id):
		result["messages"].append("未知丹药")
		return result
	
	var recipe = pill_recipes[pill_id]
	crafted_pills[pill_id] -= 1
	
	var effects = recipe["effects"]
	
	# 应用功德
	if karma_system:
		if effects.has("merit"):
			karma_system.add_merit(effects["merit"], "服用「%s」" % recipe["name"])
			result["messages"].append("[color=green]功德+%d[/color]" % effects["merit"])
		if effects.has("sin_reduction"):
			karma_system.add_sin(-effects["sin_reduction"], "服用「%s」净化业障" % recipe["name"])
			result["messages"].append("[color=blue]罪孽-%d[/color]" % effects["sin_reduction"])
	
	# 应用寿命
	if rebirth_system and effects.has("lifespan"):
		rebirth_system.extend_lifespan(effects["lifespan"], karma_system)
		result["messages"].append("[color=yellow]寿命+%d年[/color]" % effects["lifespan"])
	
	result["messages"].append("🪷 服用「%s」：%s" % [recipe["name"], effects.get("description", "")])
	result["success"] = true
	return result

# ========== 炼制经验 ==========

func _add_craft_experience(_exp: float):
	craft_experience += _exp
	var required = _get_craft_level_exp(craft_level)
	if craft_experience >= required:
		craft_level += 1
		craft_experience -= required
		system_message.emit("[color=yellow]🎊 炼制等级提升！现为 %d 级[/color]" % craft_level)

func _get_craft_level_exp(level: int) -> float:
	return 50.0 * pow(1.4, level - 1)

# ========== 查询方法 ==========

func get_pill_name(pill_id: String) -> String:
	if pill_recipes.has(pill_id):
		return pill_recipes[pill_id]["name"]
	return "未知丹药"

func get_recipe_list() -> Array:
	var result = []
	for pill_id in pill_recipes:
		var recipe = pill_recipes[pill_id]
		var pill_count = crafted_pills.get(pill_id, 0)
		var entry = {
			"id": pill_id,
			"name": recipe["name"],
			"icon": recipe["icon"],
			"tier": recipe["tier"],
			"tier_name": tier_names.get(recipe["tier"], "未知"),
			"description": recipe["description"],
			"craft_time": recipe["craft_time"],
			"success_rate": recipe["base_success_rate"] + (craft_level - 1) * 0.03,
			"materials": recipe["materials"],
			"effects": recipe["effects"],
			"owned": pill_count
		}
		result.append(entry)
	return result

func get_craft_status() -> Dictionary:
	return {
		"is_crafting": is_crafting,
		"current_pill": get_pill_name(current_pill) if is_crafting else "",
		"progress": craft_progress,
		"craft_level": craft_level,
		"craft_experience": craft_experience,
		"craft_level_exp": _get_craft_level_exp(craft_level),
		"total_crafts": total_crafts,
		"total_successes": total_successes,
		"total_failures": total_failures,
		"success_rate": float(total_successes) / float(max(total_crafts, 1))
	}

# ========== 持久化 ==========

func save_to_data(data: Dictionary):
	data["craft_level"] = craft_level
	data["craft_experience"] = craft_experience
	data["total_crafts"] = total_crafts
	data["total_successes"] = total_successes
	data["total_failures"] = total_failures
	data["crafted_pills"] = crafted_pills

func load_from_data(data: Dictionary):
	if data.has("craft_level"):
		craft_level = data["craft_level"]
	if data.has("craft_experience"):
		craft_experience = data["craft_experience"]
	if data.has("total_crafts"):
		total_crafts = data["total_crafts"]
	if data.has("total_successes"):
		total_successes = data["total_successes"]
	if data.has("total_failures"):
		total_failures = data["total_failures"]
	if data.has("crafted_pills"):
		crafted_pills = data["crafted_pills"]
