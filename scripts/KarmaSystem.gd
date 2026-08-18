extends Node
class_name KarmaSystem

# 善业与恶业值
var merit: int = 0  # 功德（善业）
var sin_value: int = 0    # 罪孽（恶业）

# 业力等级
enum KarmaLevel {
	EXTREMELY_EVIL,  # 极恶 -10000 以下
	VERY_EVIL,       # 大恶 -5000 ~ -10000
	EVIL,            # 恶 -1000 ~ -5000
	SLIGHTLY_EVIL,   # 微恶 -100 ~ -1000
	NEUTRAL,         # 中性 -100 ~ 100
	SLIGHTLY_GOOD,   # 微善 100 ~ 1000
	GOOD,            # 善 1000 ~ 5000
	VERY_GOOD,       # 大善 5000 ~ 10000
	EXTREMELY_GOOD   # 极善 10000 以上
}

# 业力事件记录
var karma_history: Array = []

signal karma_changed(merit: int, sin_value: int)
signal level_changed(new_level: int)

func _ready():
	add_to_group("karma")

# 添加善业
func add_merit(amount: int, reason: String = "") -> void:
	merit += amount
	if reason != "":
		karma_history.append({
			"type": "merit",
			"amount": amount,
			"reason": reason,
			"time": Time.get_datetime_string_from_system()
		})
		if karma_history.size() > 100:
			karma_history.remove_at(0)
	emit_signal("karma_changed", merit, sin_value)
	_check_level_change()

# 添加恶业
func add_sin(amount: int, reason: String = "") -> void:
	sin_value += amount
	if reason != "":
		karma_history.append({
			"type": "sin",
			"amount": amount,
			"reason": reason,
			"time": Time.get_datetime_string_from_system()
		})
		if karma_history.size() > 100:
			karma_history.remove_at(0)
	emit_signal("karma_changed", merit, sin_value)
	_check_level_change()

# 获取净业力（功德 - 罪孽）
func get_net_karma() -> int:
	return merit - sin_value

# 获取业力等级
func get_karma_level() -> int:
	var net = get_net_karma()
	if net <= -10000:
		return KarmaLevel.EXTREMELY_EVIL
	elif net <= -5000:
		return KarmaLevel.VERY_EVIL
	elif net <= -1000:
		return KarmaLevel.EVIL
	elif net <= -100:
		return KarmaLevel.SLIGHTLY_EVIL
	elif net < 100:
		return KarmaLevel.NEUTRAL
	elif net < 1000:
		return KarmaLevel.SLIGHTLY_GOOD
	elif net < 5000:
		return KarmaLevel.GOOD
	elif net < 10000:
		return KarmaLevel.VERY_GOOD
	else:
		return KarmaLevel.EXTREMELY_GOOD

# 获取业力等级名称
func get_karma_level_name() -> String:
	match get_karma_level():
		KarmaLevel.EXTREMELY_EVIL:
			return "极恶之人"
		KarmaLevel.VERY_EVIL:
			return "大恶之人"
		KarmaLevel.EVIL:
			return "邪恶之人"
		KarmaLevel.SLIGHTLY_EVIL:
			return "微恶之人"
		KarmaLevel.NEUTRAL:
			return "凡夫俗子"
		KarmaLevel.SLIGHTLY_GOOD:
			return "微善之人"
		KarmaLevel.GOOD:
			return "行善之人"
		KarmaLevel.VERY_GOOD:
			return "大善之人"
		KarmaLevel.EXTREMELY_GOOD:
			return "圣贤之人"
	return "凡夫俗子"

# 获取业力颜色
func get_karma_color() -> Color:
	match get_karma_level():
		KarmaLevel.EXTREMELY_EVIL:
			return Color(0.5, 0, 0)  # 暗红
		KarmaLevel.VERY_EVIL:
			return Color(0.8, 0.1, 0.1)  # 红
		KarmaLevel.EVIL:
			return Color(0.9, 0.3, 0.3)  # 浅红
		KarmaLevel.SLIGHTLY_EVIL:
			return Color(0.8, 0.6, 0.3)  # 橙
		KarmaLevel.NEUTRAL:
			return Color(0.7, 0.7, 0.7)  # 灰
		KarmaLevel.SLIGHTLY_GOOD:
			return Color(0.7, 0.9, 0.6)  # 浅绿
		KarmaLevel.GOOD:
			return Color(0.4, 0.8, 0.4)  # 绿
		KarmaLevel.VERY_GOOD:
			return Color(0.2, 0.9, 0.3)  # 翠绿
		KarmaLevel.EXTREMELY_GOOD:
			return Color(0.8, 0.8, 0.2)  # 金色
	return Color.WHITE

# 消除罪孽（通过忏悔等方式）
func purify_sin(amount: int) -> void:
	var purified = min(amount, sin_value)
	sin_value -= purified
	emit_signal("karma_changed", merit, sin_value)
	_check_level_change()

# 检查等级变化
var _last_level: int = KarmaLevel.NEUTRAL
func _check_level_change() -> void:
	var current_level = get_karma_level()
	if current_level != _last_level:
		_last_level = current_level
		emit_signal("level_changed", current_level)

# 获取最近的业力历史
func get_recent_history(count: int = 20) -> Array:
	if count >= karma_history.size():
		return karma_history.duplicate()
	return karma_history.slice(karma_history.size() - count, karma_history.size())

# 业力事件定义 - 善业
var good_actions = {
	"donate_money": {"merit": 50, "name": "布施钱财", "desc": "以财物布施穷苦之人"},
	"donate_food": {"merit": 30, "name": "布施饮食", "desc": "施食于饥者"},
	"donate_clothes": {"merit": 40, "name": "布施衣物", "desc": "施衣于寒者"},
	"help_elderly": {"merit": 25, "name": "扶助老弱", "desc": "照顾老人弱者"},
	"save_animal": {"merit": 100, "name": "放生救命", "desc": "解救生命，放归自然"},
	"meditation": {"merit": 20, "name": "坐禅修行", "desc": "静心修禅，增长智慧"},
	"recite_sutra": {"merit": 30, "name": "诵读经典", "desc": "诵经持咒，种下善根"},
	"keep_precept": {"merit": 40, "name": "严持戒律", "desc": "守持五戒十善"},
	"forgive_other": {"merit": 15, "name": "忍辱宽恕", "desc": "不嗔不怒，宽恕他人"},
	"teach_dharma": {"merit": 80, "name": "弘法利生", "desc": "为人讲说佛法"},
	"offer_to_monk": {"merit": 60, "name": "供养僧宝", "desc": "以衣食财物供养出家人"},
	"offer_to_buddha": {"merit": 50, "name": "供养佛宝", "desc": "以香花灯果供养诸佛"},
	"build_temple": {"merit": 200, "name": "修建寺院", "desc": "建造伽蓝，安奉三宝"},
	"help_sick": {"merit": 60, "name": "施药救人", "desc": "照顾病患，施医舍药"},
	"comfort_grieving": {"merit": 20, "name": "安慰忧苦", "desc": "抚慰悲伤之人"}
}

# 业力事件定义 - 恶业
var evil_actions = {
	"kill_human": {"sin": 500, "name": "杀人", "desc": "夺取人命，最重恶业"},
	"kill_animal": {"sin": 100, "name": "杀生害命", "desc": "杀害动物，造作杀业"},
	"steal": {"sin": 150, "name": "偷盗抢劫", "desc": "盗取他人财物"},
	"sexual_misconduct": {"sin": 200, "name": "邪淫", "desc": "行非礼之事"},
	"lie": {"sin": 60, "name": "妄语说谎", "desc": "以虚言诳骗他人"},
	"slander": {"sin": 80, "name": "两舌挑拨", "desc": "挑拨离间，破人和合"},
	"insult": {"sin": 50, "name": "恶口伤人", "desc": "以粗恶言语辱骂他人"},
	"gossip": {"sin": 30, "name": "绮语妄言", "desc": "说无意义之言辞"},
	"greedy": {"sin": 40, "name": "贪婪悭吝", "desc": "贪求无度，不肯布施"},
	"hateful": {"sin": 70, "name": "嗔恚愤怒", "desc": "心怀嗔恨，恼怒他人"},
	"delusion": {"sin": 30, "name": "愚痴邪见", "desc": "不信因果，起诸邪见"},
	"break_precept": {"sin": 100, "name": "毁犯戒律", "desc": "故意破戒，坏善根"},
	"disrespect_dharma": {"sin": 120, "name": "轻毁三宝", "desc": "不敬佛法僧"},
	"abuse_elderly": {"sin": 80, "name": "虐待老弱", "desc": "欺辱老人弱者"},
	"waste_food": {"sin": 20, "name": "浪费粮食", "desc": "暴殄天物，不惜福报"}
}

# 执行善业
func do_good_action(action_id: String) -> bool:
	if good_actions.has(action_id):
		var action = good_actions[action_id]
		add_merit(action["merit"], action["name"])
		return true
	return false

# 执行恶业
func do_evil_action(action_id: String) -> bool:
	if evil_actions.has(action_id):
		var action = evil_actions[action_id]
		add_sin(action["sin"], action["name"])
		return true
	return false