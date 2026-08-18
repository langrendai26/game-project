extends Node
class_name PreceptSystem

# 五戒定义
# 不杀生、不偷盗、不邪淫、不妄语、不饮酒
enum FivePrecepts {
	NO_KILLING = 0,      # 不杀生
	NO_STEALING = 1,     # 不偷盗
	NO_SEXUAL_MISCONDUCT = 2,  # 不邪淫
	NO_LYING = 3,        # 不妄语
	NO_ALCOHOL = 4       # 不饮酒
}

# 五戒状态
var precepts_status: Array = [true, true, true, true, true]  # true=持戒, false=破戒
var precepts_violation_count: Array = [0, 0, 0, 0, 0]  # 破戒次数

# 十善定义
# 身三善：不杀生、不偷盗、不邪淫
# 口四善：不妄语、不两舌、不恶口、不绮语
# 意三善：不贪欲、不嗔恚、不愚痴
enum TenGoodActions {
	BODY_NO_KILLING = 0,
	BODY_NO_STEALING = 1,
	BODY_NO_SEXUAL_MISCONDUCT = 2,
	MOUTH_NO_LYING = 3,
	MOUTH_NO_SLANDER = 4,
	MOUTH_NO_INSULT = 5,
	MOUTH_NO_GOSSIP = 6,
	MIND_NO_GREED = 7,
	MIND_NO_HATRED = 8,
	MIND_NO_DELUSION = 9
}

# 持戒功德倍率
var precept_merit_bonus: float = 1.0

# 信号
signal precept_broken(precept_id: int, precept_name: String)
signal precept_restored(precept_id: int, precept_name: String)
signal merit_bonus_changed(new_bonus: float)

func _ready():
	add_to_group("precept")
	_update_merit_bonus()

# 获取五戒名称
func get_precept_name(precept_id: int) -> String:
	match precept_id:
		FivePrecepts.NO_KILLING:
			return "不杀生戒"
		FivePrecepts.NO_STEALING:
			return "不偷盗戒"
		FivePrecepts.NO_SEXUAL_MISCONDUCT:
			return "不邪淫戒"
		FivePrecepts.NO_LYING:
			return "不妄语戒"
		FivePrecepts.NO_ALCOHOL:
			return "不饮酒戒"
	return "未知戒律"

# 获取五戒详细说明
func get_precept_description(precept_id: int) -> String:
	match precept_id:
		FivePrecepts.NO_KILLING:
			return "不杀生：慈悲为本，不伤害一切有情生命，常行放生。"
		FivePrecepts.NO_STEALING:
			return "不偷盗：不与不取，凡他人财物，未予不受，常行布施。"
		FivePrecepts.NO_SEXUAL_MISCONDUCT:
			return "不邪淫：守身如玉，不行非礼之事，保持身心清净。"
		FivePrecepts.NO_LYING:
			return "不妄语：诚实无欺，言而有信，不诳惑他人。"
		FivePrecepts.NO_ALCOHOL:
			return "不饮酒：不饮一切能令人迷醉失性之酒，保持神智清明。"
	return ""

# 获取十善名称
func get_ten_good_name(action_id: int) -> String:
	match action_id:
		TenGoodActions.BODY_NO_KILLING:
			return "身业·不杀生"
		TenGoodActions.BODY_NO_STEALING:
			return "身业·不偷盗"
		TenGoodActions.BODY_NO_SEXUAL_MISCONDUCT:
			return "身业·不邪淫"
		TenGoodActions.MOUTH_NO_LYING:
			return "口业·不妄语"
		TenGoodActions.MOUTH_NO_SLANDER:
			return "口业·不两舌"
		TenGoodActions.MOUTH_NO_INSULT:
			return "口业·不恶口"
		TenGoodActions.MOUTH_NO_GOSSIP:
			return "口业·不绮语"
		TenGoodActions.MIND_NO_GREED:
			return "意业·不贪欲"
		TenGoodActions.MIND_NO_HATRED:
			return "意业·不嗔恚"
		TenGoodActions.MIND_NO_DELUSION:
			return "意业·不愚痴"
	return "未知"

# 破戒
func break_precept(precept_id: int, karma_system: KarmaSystem) -> bool:
	if precept_id < 0 or precept_id >= 5:
		return false
	
	var precept_name = get_precept_name(precept_id)
	
	if precepts_status[precept_id]:
		precepts_status[precept_id] = false
		precepts_violation_count[precept_id] += 1
		
		# 破戒产生恶业
		var sin_amount = _get_precept_sin(precept_id)
		if karma_system:
			karma_system.add_sin(sin_amount, "破" + precept_name)
		
		_update_merit_bonus()
		emit_signal("precept_broken", precept_id, precept_name)
		return true
	else:
		# 已经破戒，再次违反增加破戒次数
		precepts_violation_count[precept_id] += 1
		var sin_amount = int(_get_precept_sin(precept_id) * 0.5)
		if karma_system:
			karma_system.add_sin(sin_amount, "再次犯" + precept_name)
		return true

# 受戒 / 恢复戒律
func restore_precept(precept_id: int, karma_system: KarmaSystem) -> bool:
	if precept_id < 0 or precept_id >= 5:
		return false
	
	if not precepts_status[precept_id]:
		precepts_status[precept_id] = true
		
		# 受戒产生善业，但少于破戒的恶业
		var merit_amount = int(_get_precept_sin(precept_id) * 0.3)
		if karma_system:
			karma_system.add_merit(merit_amount, "受持" + get_precept_name(precept_id))
		
		_update_merit_bonus()
		emit_signal("precept_restored", precept_id, get_precept_name(precept_id))
		return true
	return false

# 获取某戒破戒产生的罪孽
func _get_precept_sin(precept_id: int) -> int:
	match precept_id:
		FivePrecepts.NO_KILLING:
			return 300
		FivePrecepts.NO_STEALING:
			return 200
		FivePrecepts.NO_SEXUAL_MISCONDUCT:
			return 250
		FivePrecepts.NO_LYING:
			return 100
		FivePrecepts.NO_ALCOHOL:
			return 80
	return 50

# 检查是否持戒
func is_precept_kept(precept_id: int) -> bool:
	if precept_id < 0 or precept_id >= 5:
		return false
	return precepts_status[precept_id]

# 获取持戒数量
func get_kept_precept_count() -> int:
	var count = 0
	for p in precepts_status:
		if p:
			count += 1
	return count

# 更新功德倍率
func _update_merit_bonus() -> void:
	var kept_count = get_kept_precept_count()
	# 每持一戒，功德增加20%
	precept_merit_bonus = 1.0 + float(kept_count) * 0.2
	emit_signal("merit_bonus_changed", precept_merit_bonus)

# 计算带持戒加成的功德
func calculate_merit_with_bonus(base_merit: int) -> int:
	return int(float(base_merit) * precept_merit_bonus)

# 履行十善业
func perform_ten_good(action_id: int, karma_system: KarmaSystem) -> bool:
	if action_id < 0 or action_id >= 10:
		return false
	
	var merit_map = [
		40,  # 不杀生
		35,  # 不偷盗
		30,  # 不邪淫
		20,  # 不妄语
		15,  # 不两舌
		18,  # 不恶口
		10,  # 不绮语
		25,  # 不贪欲
		30,  # 不嗔恚
		35   # 不愚痴
	]
	
	if action_id < merit_map.size():
		var base_merit = merit_map[action_id]
		var final_merit = calculate_merit_with_bonus(base_merit)
		if karma_system:
			karma_system.add_merit(final_merit, "修" + get_ten_good_name(action_id))
		return true
	return false

# 犯十恶业
func commit_ten_evil(action_id: int, karma_system: KarmaSystem) -> bool:
	if action_id < 0 or action_id >= 10:
		return false
	
	var sin_map = [
		200,  # 杀生
		180,  # 偷盗
		220,  # 邪淫
		80,   # 妄语
		70,   # 两舌
		90,   # 恶口
		50,   # 绮语
		100,  # 贪欲
		150,  # 嗔恚
		120   # 愚痴
	]
	
	if action_id < sin_map.size():
		if karma_system:
			karma_system.add_sin(sin_map[action_id], "犯十恶·" + get_ten_good_name(action_id).replace("不", "行").replace("·", "·"))
		return true
	return false

# 取得五戒戒相
func get_precepts_summary() -> Dictionary:
	var summary = {}
	for i in range(5):
		summary[i] = {
			"name": get_precept_name(i),
			"kept": precepts_status[i],
			"violation_count": precepts_violation_count[i],
			"description": get_precept_description(i)
		}
	return summary

# 忏悔消除破戒业障
func confess(precept_id: int, karma_system: KarmaSystem) -> bool:
	if precept_id < 0 or precept_id >= 5:
		return false
	
	if precepts_violation_count[precept_id] > 0:
		# 忏悔只能消除一部分罪孽，不能立刻恢复戒律
		var sin_amount = _get_precept_sin(precept_id)
		var purify_amount = int(sin_amount * 0.5)
		if karma_system:
			karma_system.purify_sin(purify_amount)
			karma_system.add_merit(20, "真诚忏悔·" + get_precept_name(precept_id))
		return true
	return false

# 判断是否可以出离三界
func can_transcend_samsara(karma_system: KarmaSystem) -> bool:
	# 需要五戒清净 + 净业力达到一定程度
	if get_kept_precept_count() < 5:
		return false
	if karma_system:
		return karma_system.get_net_karma() >= 8000
	return false

# 获取戒体清净程度
func get_precept_purity() -> float:
	var total_violations = 0
	for count in precepts_violation_count:
		total_violations += count
	
	if total_violations == 0:
		return 1.0
	# 破戒次数越多，清净度越低
	var purity = max(0.0, 1.0 - float(total_violations) * 0.1)
	return purity