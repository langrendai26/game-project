extends Node
class_name SkillSystem

# ========== 技能等级系统 ==========
# 每个技能有 1-10 级，等级越高效果越强
# 技能经验通过使用获得

signal skill_level_changed(skill_id: String, new_level: int)
signal skill_used(skill_id: String, result: Dictionary)

# ========== 技能定义 ==========
var skills_data = {
	"recite_sutra": {
		"name": "诵经",
		"icon": "📖",
		"description": "读诵佛经，增长智慧与功德",
		"max_level": 10,
		"base_exp": 10,
		"exp_growth": 1.5,
		"effect_per_level": "功德+5×等级，智慧+1×等级",
		"cooldown_seconds": 30
	},
	"recite_mantra": {
		"name": "持咒",
		"icon": "🕉️",
		"description": "持诵真言咒语，净化业障",
		"max_level": 10,
		"base_exp": 8,
		"exp_growth": 1.4,
		"effect_per_level": "功德+3×等级，业障-2×等级",
		"cooldown_seconds": 20
	},
	"meditation": {
		"name": "坐禅",
		"icon": "🧘",
		"description": "禅定修行，平息妄念，增长定力",
		"max_level": 10,
		"base_exp": 15,
		"exp_growth": 1.6,
		"effect_per_level": "功德+8×等级，净业力+2×等级，寿命+1×等级",
		"cooldown_seconds": 60
	},
	"dana": {
		"name": "布施",
		"icon": "💰",
		"description": "财布施、法布施、无畏布施",
		"max_level": 10,
		"base_exp": 12,
		"exp_growth": 1.5,
		"effect_per_level": "功德+10×等级，善缘+1×等级",
		"cooldown_seconds": 45
	},
	"keep_precept": {
		"name": "持戒",
		"icon": "📿",
		"description": "持守五戒，清净身心",
		"max_level": 10,
		"base_exp": 20,
		"exp_growth": 1.7,
		"effect_per_level": "戒律守护+等级×10%，功德加成+等级×2%",
		"cooldown_seconds": 0
	},
	"confess": {
		"name": "忏悔",
		"icon": "🙏",
		"description": "至诚忏悔，消除业障",
		"max_level": 10,
		"base_exp": 18,
		"exp_growth": 1.5,
		"effect_per_level": "业障-5×等级，解脱力+等级",
		"cooldown_seconds": 90
	},
	"pilgrimage": {
		"name": "朝圣",
		"icon": "🏔️",
		"description": "巡礼诸佛圣地，增长善缘",
		"max_level": 10,
		"base_exp": 30,
		"exp_growth": 1.8,
		"effect_per_level": "功德+15×等级，善缘+2×等级",
		"cooldown_seconds": 120
	},
	"chant": {
		"name": "念佛",
		"icon": "🪷",
		"description": "念诵佛号，忆佛念佛",
		"max_level": 10,
		"base_exp": 6,
		"exp_growth": 1.3,
		"effect_per_level": "功德+2×等级，净业力+1×等级",
		"cooldown_seconds": 10
	}
}

# 技能状态
var skill_levels: Dictionary = {}
var skill_exp: Dictionary = {}
var skill_last_used: Dictionary = {}
var skill_total_uses: Dictionary = {}

# 累计修行数据
var total_cultivation_time: float = 0.0
var total_merit_from_skills: int = 0
var total_sin_removed_by_skills: int = 0

func _ready():
	add_to_group("skills")
	for skill_id in skills_data:
		skill_levels[skill_id] = 1
		skill_exp[skill_id] = 0
		skill_total_uses[skill_id] = 0
	# 注意：skill_last_used 不预填充，仅在技能实际使用后记录时间戳，
	# 这样从未使用的技能不会误判为冷却中

# ========== 核心使用逻辑 ==========

func use_skill(skill_id: String, karma_system = null, precept_system = null, rebirth_system = null) -> Dictionary:
	var result = {"success": false, "skill": skill_id, "messages": [], "gains": {}}
	
	if not skills_data.has(skill_id):
		result["messages"].append("未知技能: " + skill_id)
		return result
	
	var skill = skills_data[skill_id]
	var _current_level = skill_levels.get(skill_id, 1)
	
	# 冷却检查（仅对已使用过的技能生效，从未使用的技能无冷却）
	var cooldown = skill.get("cooldown_seconds", 0)
	if cooldown > 0 and skill_last_used.has(skill_id):
		var elapsed = Time.get_ticks_msec() / 1000.0 - skill_last_used[skill_id]
		if elapsed < cooldown:
			var remaining = cooldown - elapsed
			result["messages"].append("「%s」冷却中，还需 %.0f 秒" % [skill["name"], remaining])
			return result
	
	# 执行技能效果
	var level = skill_levels[skill_id]
	var merit_gain = 0
	var sin_reduction = 0
	var lifespan_gain = 0
	
	match skill_id:
		"recite_sutra":
			merit_gain = 5 * level
			result["messages"].append("📖 你诵读了一卷经文，智慧渐开。")
		"recite_mantra":
			merit_gain = 3 * level
			sin_reduction = 2 * level
			result["messages"].append("🕉️ 你持咒 %d 遍，业障渐消。" % (30 + randi() % 78))
		"meditation":
			merit_gain = 8 * level
			lifespan_gain = 1
			if randf() < 0.3:
				lifespan_gain = 2
			result["messages"].append("🧘 你静坐禅定，妄念不起，身心清净。")
		"dana":
			merit_gain = 10 * level
			result["messages"].append("💰 你广行布施，利乐有情。")
		"keep_precept":
			merit_gain = 2 * level
			result["messages"].append("📿 你持守戒律，身心清净。")
		"confess":
			merit_gain = 3 * level
			sin_reduction = 5 * level
			result["messages"].append("🙏 你至诚忏悔，往昔业障渐消。")
		"pilgrimage":
			merit_gain = 15 * level
			result["messages"].append("🏔️ 你朝圣归回，善缘增长。")
		"chant":
			merit_gain = 2 * level
			result["messages"].append("🪷 你念佛 %d 声，忆佛念佛。" % (49 + randi() % 60))
	
	# 应用效果到各系统
	if karma_system:
		if merit_gain > 0:
			karma_system.add_merit(merit_gain, "修习「%s」" % skill["name"])
			result["gains"]["merit"] = merit_gain
			total_merit_from_skills += merit_gain
		if sin_reduction > 0:
			karma_system.add_sin(-sin_reduction, "修习「%s」消除业障" % skill["name"])
			result["gains"]["sin_removed"] = sin_reduction
			total_sin_removed_by_skills += sin_reduction
	
	if rebirth_system and lifespan_gain > 0:
		rebirth_system.extend_lifespan(lifespan_gain, karma_system, precept_system)
		result["gains"]["lifespan"] = lifespan_gain
	
	# 增加经验
	var exp_gained = _calculate_exp_gain(skill_id, level)
	_add_skill_exp(skill_id, exp_gained, result)
	
	# 更新使用记录
	skill_last_used[skill_id] = Time.get_ticks_msec() / 1000.0
	skill_total_uses[skill_id] = skill_total_uses.get(skill_id, 0) + 1
	total_cultivation_time += cooldown if cooldown > 0 else 5
	
	result["success"] = true
	result["level"] = level
	result["exp_gained"] = exp_gained
	
	skill_used.emit(skill_id, result)
	return result

# ========== 经验与等级 ==========

func _calculate_exp_gain(skill_id: String, level: int) -> int:
	var skill = skills_data[skill_id]
	var base = skill.get("base_exp", 10)
	return int(base * level)

func _add_skill_exp(skill_id: String, _exp: int, result: Dictionary):
	var current_level = skill_levels.get(skill_id, 1)
	var max_level = skills_data[skill_id].get("max_level", 10)

	if current_level >= max_level:
		return

	var current_exp = skill_exp.get(skill_id, 0)
	var new_exp = current_exp + _exp

	# 计算升级所需经验
	var required_exp = _get_required_exp(skill_id, current_level)

	result["messages"].append("EXP +%d (%d/%d)" % [_exp, new_exp, required_exp])
	
	if new_exp >= required_exp:
		# 升级
		var new_level = current_level + 1
		skill_levels[skill_id] = new_level
		skill_exp[skill_id] = new_exp - required_exp
		
		var skill_name = skills_data[skill_id]["name"]
		result["messages"].append("[color=yellow]🎊 「%s」升级到 %d 级！[/color]" % [skill_name, new_level])
		result["level_up"] = true
		skill_level_changed.emit(skill_id, new_level)
	else:
		skill_exp[skill_id] = new_exp

func _get_required_exp(skill_id: String, level: int) -> int:
	var skill = skills_data[skill_id]
	var base = skill.get("base_exp", 10)
	var growth = skill.get("exp_growth", 1.5)
	return int(base * pow(growth, level - 1))

# ========== 查询方法 ==========

func get_skill_level(skill_id: String) -> int:
	return skill_levels.get(skill_id, 1)

func get_skill_exp(skill_id: String) -> int:
	return skill_exp.get(skill_id, 0)

func get_skill_info(skill_id: String) -> Dictionary:
	if not skills_data.has(skill_id):
		return {}
	var skill = skills_data[skill_id]
	var level = skill_levels.get(skill_id, 1)
	var current_exp = skill_exp.get(skill_id, 0)
	var max_level = skill.get("max_level", 10)
	var required = _get_required_exp(skill_id, level)
	
	return {
		"id": skill_id,
		"name": skill["name"],
		"icon": skill["icon"],
		"description": skill["description"],
		"level": level,
		"max_level": max_level,
		"exp": current_exp,
		"required_exp": required,
		"exp_progress": float(current_exp) / float(required) if required > 0 else 1.0,
		"effect": skill["effect_per_level"],
		"cooldown": skill.get("cooldown_seconds", 0),
		"total_uses": skill_total_uses.get(skill_id, 0)
	}

func get_all_skills() -> Array:
	var result = []
	for skill_id in skills_data:
		result.append(get_skill_info(skill_id))
	return result

func get_skill_cooldown_remaining(skill_id: String) -> float:
	var skill = skills_data.get(skill_id, {})
	var cooldown = skill.get("cooldown_seconds", 0)
	if cooldown <= 0 or not skill_last_used.has(skill_id):
		return 0.0
	var elapsed = Time.get_ticks_msec() / 1000.0 - skill_last_used[skill_id]
	return max(0.0, cooldown - elapsed)

func get_total_cultivation_stats() -> Dictionary:
	return {
		"total_time": total_cultivation_time,
		"total_merit": total_merit_from_skills,
		"total_sin_removed": total_sin_removed_by_skills,
		"total_uses": skill_total_uses
	}

# ========== 持久化 ==========

func save_to_data(data: Dictionary):
	data["skill_levels"] = skill_levels
	data["skill_exp"] = skill_exp
	data["skill_total_uses"] = skill_total_uses
	data["total_cultivation_time"] = total_cultivation_time
	data["total_merit_from_skills"] = total_merit_from_skills
	data["total_sin_removed_by_skills"] = total_sin_removed_by_skills

func load_from_data(data: Dictionary):
	if data.has("skill_levels"):
		skill_levels = data["skill_levels"]
	if data.has("skill_exp"):
		skill_exp = data["skill_exp"]
	if data.has("skill_total_uses"):
		skill_total_uses = data["skill_total_uses"]
	if data.has("total_cultivation_time"):
		total_cultivation_time = data["total_cultivation_time"]
	if data.has("total_merit_from_skills"):
		total_merit_from_skills = data["total_merit_from_skills"]
	if data.has("total_sin_removed_by_skills"):
		total_sin_removed_by_skills = data["total_sin_removed_by_skills"]
