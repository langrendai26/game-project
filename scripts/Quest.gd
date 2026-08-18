extends Node

# 任务系统 - 三界模拟器
# 支持主线、支线、每日任务 + 佛教修行任务

signal quest_updated(quest_id: String)
signal quest_completed(quest_id: String)

enum QuestType { MAIN, SIDE, DAILY, PRACTICE }
enum QuestStatus { LOCKED, AVAILABLE, ACCEPTED, COMPLETED, REWARDED }

# 任务数据库
var quest_database = {
	# ===== 主线任务 - 三界修行路 =====
	"main_001": {
		"name": "初入三界",
		"desc": "得闻佛法，了解因果。聆听善知识开示，明白三界六道之真相。",
		"type": QuestType.MAIN,
		"target": {"type": "listen_dharma", "count": 1},
		"reward": {"exp": 100, "gold": 50, "merit": 100, "items": ["sutra_heart"]},
		"next_quest": "main_002",
		"level_required": 1
	},
	"main_002": {
		"name": "受持五戒",
		"desc": "归依三宝，受持五戒（不杀生、不偷盗、不邪淫、不妄语、不饮酒），以此作为修行根本。",
		"type": QuestType.MAIN,
		"target": {"type": "keep_precepts", "count": 5},
		"reward": {"exp": 200, "gold": 100, "merit": 500, "items": ["kashaya_robe", "wood_mala"]},
		"next_quest": "main_003",
		"level_required": 2
	},
	"main_003": {
		"name": "行十善业",
		"desc": "身三善、口四善、意三善，修十善业，生人天道。",
		"type": QuestType.MAIN,
		"target": {"type": "do_ten_good", "count": 10},
		"reward": {"exp": 500, "gold": 200, "merit": 1000, "items": ["sutra_diamond", "incense_stick"]},
		"next_quest": "main_004",
		"level_required": 3
	},
	"main_004": {
		"name": "修布施度",
		"desc": "布施为首度，财布施、法布施、无畏布施，广行布施积功累德。",
		"type": QuestType.MAIN,
		"target": {"type": "give_dana", "count": 20},
		"reward": {"exp": 800, "gold": 300, "merit": 2000, "items": ["sutra_lotus", "lotus_flower"]},
		"next_quest": "main_005",
		"level_required": 5
	},
	"main_005": {
		"name": "修禅定",
		"desc": "坐禅入定，观身不净、观受是苦、观心无常、观法无我。",
		"type": QuestType.MAIN,
		"target": {"type": "meditation", "count": 30},
		"reward": {"exp": 1500, "gold": 500, "merit": 3000, "items": ["sutra_surangama", "peace_pill"]},
		"next_quest": "main_006",
		"level_required": 8
	},
	"main_006": {
		"name": "明心见性",
		"desc": "持戒清净、功德具足，看破放下，超越三界轮回。",
		"type": QuestType.MAIN,
		"target": {"type": "transcend_samsara", "count": 1},
		"reward": {"exp": 10000, "gold": 5000, "merit": 10000, "items": ["sutra_huayan", "liberation_pill", "relic_mala"]},
		"next_quest": "",
		"level_required": 12
	},
	
	# ===== 支线任务 - 诸善奉行 =====
	"side_001": {
		"name": "救护生命",
		"desc": "放生十只生命，体会众生平等，慈悲为本。",
		"type": QuestType.SIDE,
		"target": {"type": "save_life", "count": 10},
		"reward": {"exp": 100, "merit": 500, "items": ["sutra_medicine"]},
		"next_quest": "side_002",
		"level_required": 1
	},
	"side_002": {
		"name": "布施穷苦",
		"desc": "以钱财衣食布施贫困之人，广结善缘。",
		"type": QuestType.SIDE,
		"target": {"type": "donate_poor", "count": 5},
		"reward": {"exp": 120, "merit": 300, "gold": 50, "items": ["lotus_pendant"]},
		"next_quest": "",
		"level_required": 1
	},
	"side_003": {
		"name": "供养三宝",
		"desc": "以香花灯果饮食衣服供养佛法僧三宝。",
		"type": QuestType.SIDE,
		"target": {"type": "offer_triple_gem", "count": 10},
		"reward": {"exp": 200, "merit": 600, "items": ["incense_stick", "pure_water", "lamp_offering"]},
		"next_quest": "side_004",
		"level_required": 2
	},
	"side_004": {
		"name": "助印经书",
		"desc": "出资助印佛经，流通法宝，弘法利生。",
		"type": QuestType.SIDE,
		"target": {"type": "print_sutra", "count": 3},
		"reward": {"exp": 350, "merit": 800, "items": ["sutra_earth_store"]},
		"next_quest": "",
		"level_required": 3
	},
	"side_005": {
		"name": "建寺安僧",
		"desc": "发心修建寺院、安奉三宝，令僧众安心办道。",
		"type": QuestType.SIDE,
		"target": {"type": "build_temple", "count": 1},
		"reward": {"exp": 1000, "merit": 3000, "items": ["elder_robe", "gold_mala"]},
		"next_quest": "",
		"level_required": 6
	},
	"side_006": {
		"name": "临终关怀",
		"desc": "助念临终者，令其正念分明，往生善道。",
		"type": QuestType.SIDE,
		"target": {"type": "chant_for_dying", "count": 5},
		"reward": {"exp": 500, "merit": 1500, "items": ["mantra_om_mani", "sutra_amitabha"]},
		"next_quest": "",
		"level_required": 4
	},
	
	# ===== 每日任务 - 日常修行 =====
	"daily_001": {
		"name": "晨课诵经",
		"desc": "清晨诵持经文一卷，开启清净的一天。",
		"type": QuestType.DAILY,
		"target": {"type": "recite_sutra_daily", "count": 1},
		"reward": {"exp": 30, "merit": 50, "items": []},
		"next_quest": "",
		"level_required": 1
	},
	"daily_002": {
		"name": "供佛上香",
		"desc": "以清净香、花、水、果供养诸佛。",
		"type": QuestType.DAILY,
		"target": {"type": "offer_to_buddha", "count": 3},
		"reward": {"exp": 25, "merit": 40, "items": []},
		"next_quest": "",
		"level_required": 1
	},
	"daily_003": {
		"name": "日行一善",
		"desc": "今日行至少一件善事，勿以善小而不为。",
		"type": QuestType.DAILY,
		"target": {"type": "daily_good_deed", "count": 1},
		"reward": {"exp": 40, "merit": 60, "items": []},
		"next_quest": "",
		"level_required": 1
	},
	"daily_004": {
		"name": "持戒清净",
		"desc": "今日严持五戒，不起恶念，不造恶业。",
		"type": QuestType.DAILY,
		"target": {"type": "keep_precept_daily", "count": 1},
		"reward": {"exp": 35, "merit": 80, "items": []},
		"next_quest": "",
		"level_required": 2
	},
	"daily_005": {
		"name": "坐禅半柱香",
		"desc": "静坐一柱香，收摄身心，观照实相。",
		"type": QuestType.DAILY,
		"target": {"type": "meditate_daily", "count": 1},
		"reward": {"exp": 50, "merit": 70, "items": ["peace_pill"]},
		"next_quest": "",
		"level_required": 2
	},
	"daily_006": {
		"name": "念佛持咒",
		"desc": "持念佛号或咒语，不令间断。",
		"type": QuestType.DAILY,
		"target": {"type": "chant_mantra_daily", "count": 108},
		"reward": {"exp": 45, "merit": 90, "items": []},
		"next_quest": "",
		"level_required": 1
	},
	
	# ===== 修行任务 - 六度万行 =====
	"practice_001": {
		"name": "不杀护生",
		"desc": "尽形寿不杀生，常行放生，培养慈悲心。",
		"type": QuestType.PRACTICE,
		"target": {"type": "no_killing", "count": 100},
		"reward": {"merit": 5000, "items": ["mantra_great_compassion"]},
		"next_quest": "",
		"level_required": 2
	},
	"practice_002": {
		"name": "不与不取",
		"desc": "尽形寿不偷盗，凡物非予不取。",
		"type": QuestType.PRACTICE,
		"target": {"type": "no_stealing", "count": 100},
		"reward": {"merit": 4000, "items": ["bodhi_mala"]},
		"next_quest": "",
		"level_required": 2
	},
	"practice_003": {
		"name": "梵行清净",
		"desc": "尽形寿不邪淫，守持清净梵行。",
		"type": QuestType.PRACTICE,
		"target": {"type": "no_sexual_misconduct", "count": 100},
		"reward": {"merit": 4500, "items": ["kashaya_robe"]},
		"next_quest": "",
		"level_required": 3
	},
	"practice_004": {
		"name": "实语不妄",
		"desc": "尽形寿不妄语，所言诚实，心口如一。",
		"type": QuestType.PRACTICE,
		"target": {"type": "no_lying", "count": 100},
		"reward": {"merit": 3500, "items": ["sutra_heart"]},
		"next_quest": "",
		"level_required": 2
	},
	"practice_005": {
		"name": "不饮诸酒",
		"desc": "尽形寿不饮酒，保持神智清明，不造放逸。",
		"type": QuestType.PRACTICE,
		"target": {"type": "no_alcohol", "count": 100},
		"reward": {"merit": 3000, "items": ["sandalwood_mala"]},
		"next_quest": "",
		"level_required": 2
	},
	"practice_006": {
		"name": "布施波罗蜜",
		"desc": "财布施得财富，法布施得智慧，无畏布施得健康长寿。广行布施。",
		"type": QuestType.PRACTICE,
		"target": {"type": "perfection_of_giving", "count": 500},
		"reward": {"merit": 10000, "items": ["sutra_lotus", "food_offering"]},
		"next_quest": "",
		"level_required": 4
	},
	"practice_007": {
		"name": "忍辱波罗蜜",
		"desc": "忍人所不能忍，行人所不能行。顺逆境不动于心。",
		"type": QuestType.PRACTICE,
		"target": {"type": "perfection_of_patience", "count": 300},
		"reward": {"merit": 8000, "items": ["vajra_pendant", "sutra_diamond"]},
		"next_quest": "",
		"level_required": 5
	},
	"practice_008": {
		"name": "禅定波罗蜜",
		"desc": "深入禅定，心得自在，不为境转。",
		"type": QuestType.PRACTICE,
		"target": {"type": "perfection_of_meditation", "count": 500},
		"reward": {"merit": 12000, "items": ["sutra_surangama", "crystal_mala"]},
		"next_quest": "",
		"level_required": 6
	},
	"practice_009": {
		"name": "般若波罗蜜",
		"desc": "修学般若智慧，照见五蕴皆空，度一切苦厄。",
		"type": QuestType.PRACTICE,
		"target": {"type": "perfection_of_wisdom", "count": 400},
		"reward": {"merit": 20000, "items": ["sutra_huayan", "relic_mala", "liberation_pill"]},
		"next_quest": "",
		"level_required": 10
	}
}

# 当前任务进度
var active_quests = {}  # {quest_id: {"status": QuestStatus, "progress": int}}
var completed_quests = []
var daily_quests_completed_today = []
var last_daily_reset = ""


func _ready():
	# 添加到 quest_system 组
	add_to_group("quest")
	add_to_group("quest_system")
	# 检查每日任务重置
	check_daily_reset()


# 获取任务数据
func get_quest(quest_id: String) -> Dictionary:
	return quest_database.get(quest_id, {})


# 获取任务状态
func get_quest_status(quest_id: String) -> int:
	if active_quests.has(quest_id):
		return active_quests[quest_id]["status"]
	return QuestStatus.LOCKED


# 获取任务进度
func get_quest_progress(quest_id: String) -> int:
	if active_quests.has(quest_id):
		return active_quests[quest_id]["progress"]
	return 0


# 检查任务是否可接取
func can_accept_quest(quest_id: String) -> bool:
	var quest = get_quest(quest_id)
	if quest.is_empty():
		return false
	
	var status = get_quest_status(quest_id)
	if status != QuestStatus.AVAILABLE and status != QuestStatus.LOCKED:
		return false
	
	# 检查前置任务
	var prev_quest = quest.get("prev_quest", "")
	if prev_quest != "" and not completed_quests.has(prev_quest):
		return false
	
	# 检查等级要求
	var player_level = get_player_level()
	if quest.get("level_required", 1) > player_level:
		return false
	
	return true


# 接取任务
func accept_quest(quest_id: String) -> bool:
	if not can_accept_quest(quest_id):
		return false
	
	active_quests[quest_id] = {
		"status": QuestStatus.ACCEPTED,
		"progress": 0
	}
	quest_updated.emit(quest_id)
	print("接取任务: " + quest_database[quest_id]["name"])
	return true


# 更新任务进度
func update_quest_progress(target_type: String, target_id: String, amount: int = 1):
	for quest_id in active_quests:
		var quest = get_quest(quest_id)
		if quest.is_empty() or quest["target"]["type"] != target_type:
			continue
		
		if quest["target"].get("enemy_id", "") == target_id or \
		   quest["target"].get("item_id", "") == target_id or \
		   quest["target"].get("npc_id", "") == target_id or \
		   quest["target"].get("item_type", "") == target_id:
			
			active_quests[quest_id]["progress"] += amount
			var target_count = quest["target"]["count"]
			
			quest_updated.emit(quest_id)
			print("任务进度: " + quest["name"] + " (" + str(active_quests[quest_id]["progress"]) + "/" + str(target_count) + ")")
			
			# 检查是否完成
			if active_quests[quest_id]["progress"] >= target_count:
				active_quests[quest_id]["status"] = QuestStatus.COMPLETED


# 领取任务奖励
func claim_quest_reward(quest_id: String) -> Dictionary:
	var quest = get_quest(quest_id)
	if quest.is_empty():
		return {}
	
	var status = get_quest_status(quest_id)
	if status != QuestStatus.COMPLETED:
		return {}
	
	# 标记为已领取
	active_quests[quest_id]["status"] = QuestStatus.REWARDED
	completed_quests.append(quest_id)
	
	# 每日任务记录
	if quest["type"] == QuestType.DAILY:
		daily_quests_completed_today.append(quest_id)
	
	var reward = quest["reward"]
	quest_completed.emit(quest_id)
	
	# 触发下一个任务
	var next_quest = quest.get("next_quest", "")
	if next_quest != "":
		active_quests[next_quest] = {"status": QuestStatus.AVAILABLE, "progress": 0}
	
	print("完成任务: " + quest["name"])
	print("获得奖励: 经验+" + str(reward["exp"]) + " 金币+" + str(reward["gold"]))
	
	return reward


# 获取可接取的任务列表
func get_available_quests(type: QuestType = QuestType.MAIN) -> Array:
	var available = []
	for quest_id in quest_database:
		var quest = quest_database[quest_id]
		if quest["type"] != type:
			continue
		
		var status = get_quest_status(quest_id)
		if status == QuestStatus.AVAILABLE or status == QuestStatus.LOCKED:
			# 检查前置任务是否完成
			var prev_quest = quest.get("prev_quest", "")
			if prev_quest == "" or completed_quests.has(prev_quest):
				available.append(quest_id)
	return available


# 获取进行中的任务
func get_active_quests(type: QuestType = QuestType.MAIN) -> Array:
	var active = []
	for quest_id in active_quests:
		var quest = get_quest(quest_id)
		if quest.is_empty() or quest["type"] != type:
			continue
		
		var status = active_quests[quest_id]["status"]
		if status == QuestStatus.ACCEPTED or status == QuestStatus.COMPLETED:
			active.append(quest_id)
	return active


# 检查每日任务重置
func check_daily_reset():
	var now = float(Time.get_ticks_msec())
	var today = str(int(now / 86400000.0))  # 按天划分
	if last_daily_reset != today:
		last_daily_reset = today
		daily_quests_completed_today = []
		# 重置每日任务状态
		for quest_id in quest_database:
			var quest = quest_database[quest_id]
			if quest["type"] == QuestType.DAILY:
				if active_quests.has(quest_id):
					active_quests.erase(quest_id)


# 初始化每日任务
func init_daily_quests():
	for quest_id in quest_database:
		var quest = quest_database[quest_id]
		if quest["type"] == QuestType.DAILY:
			if not daily_quests_completed_today.has(quest_id):
				active_quests[quest_id] = {"status": QuestStatus.AVAILABLE, "progress": 0}


# 获取玩家等级（临时实现，需要从Player获取）
func get_player_level() -> int:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		return player.level
	return 1


# 任务类型名称
func get_quest_type_name(type: QuestType) -> String:
	match type:
		QuestType.MAIN: return "主线任务"
		QuestType.SIDE: return "支线任务"
		QuestType.DAILY: return "每日任务"
	return "未知"


# 存档数据
func get_save_data() -> Dictionary:
	return {
		"active_quests": active_quests,
		"completed_quests": completed_quests,
		"daily_quests_completed_today": daily_quests_completed_today,
		"last_daily_reset": last_daily_reset
	}


# 加载存档数据
func load_save_data(data: Dictionary):
	if data.has("active_quests"):
		active_quests = data["active_quests"]
	if data.has("completed_quests"):
		completed_quests = data["completed_quests"]
	if data.has("daily_quests_completed_today"):
		daily_quests_completed_today = data["daily_quests_completed_today"]
	if data.has("last_daily_reset"):
		last_daily_reset = data["last_daily_reset"]
