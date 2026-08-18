extends Node
class_name RebirthSystem

# 三界定义
enum ThreeRealms {
	DESIRE_REALM = 0,     # 欲界：地狱、饿鬼、畜生、修罗、人、欲界天
	FORM_REALM = 1,       # 色界：四禅天
	FORMLESS_REALM = 2    # 无色界：四空天
}

# 六道定义（欲界）
enum SixRealms {
	HELL_REALM = 0,       # 地狱道
	HUNGRY_GHOST_REALM = 1,  # 饿鬼道
	ANIMAL_REALM = 2,     # 畜生道
	ASURA_REALM = 3,      # 阿修罗道
	HUMAN_REALM = 4,      # 人道
	DEVA_REALM = 5        # 天道
}

# 色界四禅天
enum FormHeaven {
	FIRST_DHYANA = 0,     # 初禅天
	SECOND_DHYANA = 1,    # 二禅天
	THIRD_DHYANA = 2,     # 三禅天
	FOURTH_DHYANA = 3     # 四禅天
}

# 无色界四空天
enum FormlessHeaven {
	EMPTY_INFINITY = 0,   # 空无边处天
	CONSCIOUSNESS_INFINITY = 1,  # 识无边处天
	NOTHINGNESS = 2,      # 无所有处天
	NEITHER_THOUGHT_NOR_NO_THOUGHT = 3  # 非想非非想处天
}

# 当前生命状态
var current_realm: int = SixRealms.HUMAN_REALM
var current_three_realm: int = ThreeRealms.DESIRE_REALM
var current_sub_realm: int = 0  # 细分领域（如色界的第几禅天）

# 生命状态数据
var lifespan: int = 100  # 当前寿命（年）
var current_age: int = 25
var rebirth_count: int = 0  # 轮回次数

# 累世记录
var past_lives: Array = []

# 解脱状态
var is_liberated: bool = false  # 是否已超脱轮回

# 信号
signal rebirth_occurred(new_realm: int, three_realm: int, sub_realm: int)
signal realm_changed(new_realm: int, old_realm: int)
signal lifespan_changed(remaining: int, total: int)
signal transcended_samsara()  # 超脱轮回

func _ready():
	add_to_group("rebirth")

# 获取道名称
func get_realm_name(realm_id: int) -> String:
	match realm_id:
		SixRealms.HELL_REALM:
			return "地狱道"
		SixRealms.HUNGRY_GHOST_REALM:
			return "饿鬼道"
		SixRealms.ANIMAL_REALM:
			return "畜生道"
		SixRealms.ASURA_REALM:
			return "阿修罗道"
		SixRealms.HUMAN_REALM:
			return "人道"
		SixRealms.DEVA_REALM:
			return "天道"
	return "未知道"

# 获取三界名称
func get_three_realm_name(realm_id: int) -> String:
	match realm_id:
		ThreeRealms.DESIRE_REALM:
			return "欲界"
		ThreeRealms.FORM_REALM:
			return "色界"
		ThreeRealms.FORMLESS_REALM:
			return "无色界"
	return "未知界"

# 获取细分领域名称
func get_sub_realm_name(three_realm: int, sub_realm: int) -> String:
	match three_realm:
		ThreeRealms.DESIRE_REALM:
			return get_realm_name(sub_realm)
		ThreeRealms.FORM_REALM:
			match sub_realm:
				FormHeaven.FIRST_DHYANA:
					return "初禅天"
				FormHeaven.SECOND_DHYANA:
					return "二禅天"
				FormHeaven.THIRD_DHYANA:
					return "三禅天"
				FormHeaven.FOURTH_DHYANA:
					return "四禅天"
		ThreeRealms.FORMLESS_REALM:
			match sub_realm:
				FormlessHeaven.EMPTY_INFINITY:
					return "空无边处天"
				FormlessHeaven.CONSCIOUSNESS_INFINITY:
					return "识无边处天"
				FormlessHeaven.NOTHINGNESS:
					return "无所有处天"
				FormlessHeaven.NEITHER_THOUGHT_NOR_NO_THOUGHT:
					return "非想非非想处天"
	return ""

# 获取道的详细描述
func get_realm_description(realm_id: int) -> String:
	match realm_id:
		SixRealms.HELL_REALM:
			return "地狱道：极苦之处，造作极重恶业者所生。常受寒热、刀兵等种种苦刑，寿命极长，苦报无尽。"
		SixRealms.HUNGRY_GHOST_REALM:
			return "饿鬼道：悭贪不舍、布施不修者所生。常受饥饿之苦，腹大如鼓，咽细如针，百千岁不得饮食。"
		SixRealms.ANIMAL_REALM:
			return "畜生道：愚痴邪见、毁犯戒律者所生。受畜生身，互相吞食，或被人驱使宰杀，苦多乐少。"
		SixRealms.ASURA_REALM:
			return "阿修罗道：有福无德，好争斗者所生。福报次于天人，然嗔恨心重，常与诸天战斗。"
		SixRealms.HUMAN_REALM:
			return "人道：修持五戒十善，苦乐参半者所生。具有修行的最佳机缘，易成道果，亦易造业堕落。"
		SixRealms.DEVA_REALM:
			return "天道：修持上品十善，广积功德者所生。受胜妙乐，寿命绵长，然享福既久，易造堕落。"
	return ""

# 根据业力决定投生之道
func determine_realm(karma_system: KarmaSystem, precept_system: PreceptSystem) -> Dictionary:
	var net_karma = karma_system.get_net_karma() if karma_system else 0
	var precept_count = precept_system.get_kept_precept_count() if precept_system else 0
	var purity = precept_system.get_precept_purity() if precept_system else 0.0
	
	var result = {
		"three_realm": ThreeRealms.DESIRE_REALM,
		"realm": SixRealms.HUMAN_REALM,
		"sub_realm": SixRealms.HUMAN_REALM,
		"lifespan": 100,
		"reason": ""
	}
	
	# 检查是否可以超脱轮回
	if precept_system and karma_system:
		if precept_system.can_transcend_samsara(karma_system):
			is_liberated = true
			emit_signal("transcended_samsara")
			result["reason"] = "功德圆满，超越轮回，证得圣果！"
			return result
	
	# 业力判定
	if net_karma <= -5000:
		# 极重恶业 → 地狱
		result["realm"] = SixRealms.HELL_REALM
		result["sub_realm"] = SixRealms.HELL_REALM
		result["lifespan"] = int(max(1000, abs(net_karma) * 10))
		result["reason"] = "造作极重恶业，堕入地狱"
	elif net_karma <= -2000:
		# 大恶业 → 饿鬼
		result["realm"] = SixRealms.HUNGRY_GHOST_REALM
		result["sub_realm"] = SixRealms.HUNGRY_GHOST_REALM
		result["lifespan"] = int(max(500, abs(net_karma) * 2))
		result["reason"] = "悭贪嫉妒，生饿鬼道"
	elif net_karma <= -500:
		# 恶业 → 畜生
		result["realm"] = SixRealms.ANIMAL_REALM
		result["sub_realm"] = SixRealms.ANIMAL_REALM
		result["lifespan"] = int(max(50, abs(net_karma)))
		result["reason"] = "愚痴犯戒，生畜生道"
	elif net_karma <= 200:
		# 善少恶多 → 修罗
		if precept_count < 2:
			# 持戒太少 → 还是三恶道的边缘
			result["realm"] = SixRealms.ANIMAL_REALM
			result["sub_realm"] = SixRealms.ANIMAL_REALM
			result["lifespan"] = 80
			result["reason"] = "善根微薄，生畜生道"
		else:
			result["realm"] = SixRealms.ASURA_REALM
			result["sub_realm"] = SixRealms.ASURA_REALM
			result["lifespan"] = int(300 + net_karma)
			result["reason"] = "有福无德，好斗争故，生阿修罗道"
	elif net_karma <= 2000:
		# 人 → 人道
		result["realm"] = SixRealms.HUMAN_REALM
		result["sub_realm"] = SixRealms.HUMAN_REALM
		result["lifespan"] = int(80 + precept_count * 20 + net_karma * 0.05)
		result["reason"] = "修持五戒十善，得生人道"
	else:
		# 大善 → 天道
		if net_karma <= 6000:
			# 欲界天
			result["realm"] = SixRealms.DEVA_REALM
			result["sub_realm"] = SixRealms.DEVA_REALM
			result["lifespan"] = int(1000 + net_karma * 0.5)
			result["reason"] = "修上品十善，生欲界诸天"
		elif net_karma <= 10000:
			# 色界（需要持戒清净 + 禅定功德）
			if purity >= 0.7 and precept_count >= 4:
				result["three_realm"] = ThreeRealms.FORM_REALM
				result["realm"] = SixRealms.DEVA_REALM
				if net_karma <= 7500:
					result["sub_realm"] = FormHeaven.FIRST_DHYANA
				elif net_karma <= 8500:
					result["sub_realm"] = FormHeaven.SECOND_DHYANA
				elif net_karma <= 9500:
					result["sub_realm"] = FormHeaven.THIRD_DHYANA
				else:
					result["sub_realm"] = FormHeaven.FOURTH_DHYANA
				result["lifespan"] = int(10000 + (net_karma - 6000) * 2)
				result["reason"] = "持戒修禅，生色界天"
			else:
				result["realm"] = SixRealms.DEVA_REALM
				result["sub_realm"] = SixRealms.DEVA_REALM
				result["lifespan"] = 5000
				result["reason"] = "福虽大而戒不清净，生欲界天"
		else:
			# 无色界（需要极高的禅定功夫 + 持戒清净）
			if purity >= 0.9 and precept_count >= 5:
				result["three_realm"] = ThreeRealms.FORMLESS_REALM
				result["realm"] = SixRealms.DEVA_REALM
				if net_karma <= 12000:
					result["sub_realm"] = FormlessHeaven.EMPTY_INFINITY
				elif net_karma <= 15000:
					result["sub_realm"] = FormlessHeaven.CONSCIOUSNESS_INFINITY
				elif net_karma <= 20000:
					result["sub_realm"] = FormlessHeaven.NOTHINGNESS
				else:
					result["sub_realm"] = FormlessHeaven.NEITHER_THOUGHT_NOR_NO_THOUGHT
				result["lifespan"] = int(50000 + (net_karma - 10000) * 10)
				result["reason"] = "四禅八定，深修禅定，生无色界天"
			else:
				result["three_realm"] = ThreeRealms.FORM_REALM
				result["realm"] = SixRealms.DEVA_REALM
				result["sub_realm"] = FormHeaven.FOURTH_DHYANA
				result["lifespan"] = 30000
				result["reason"] = "福极广大，生色界四禅天"
	
	return result

# 执行轮回
func do_rebirth(karma_system: KarmaSystem, precept_system: PreceptSystem) -> Dictionary:
	var old_realm = current_realm
	var result = determine_realm(karma_system, precept_system)
	
	if is_liberated:
		return result
	
	# 记录前世
	var this_life = {
		"realm": current_realm,
		"realm_name": get_realm_name(current_realm),
		"three_realm": current_three_realm,
		"age": current_age,
		"total_lifespan": lifespan,
		"merit": karma_system.merit if karma_system else 0,
		"sin": karma_system.sin_value if karma_system else 0,
		"kept_precepts": precept_system.get_kept_precept_count() if precept_system else 0
	}
	past_lives.append(this_life)
	if past_lives.size() > 100:
		past_lives.remove_at(0)
	
	# 更新当前状态
	current_realm = result["realm"]
	current_three_realm = result["three_realm"]
	current_sub_realm = result["sub_realm"]
	lifespan = result["lifespan"]
	current_age = 0
	rebirth_count += 1
	
	emit_signal("rebirth_occurred", current_realm, current_three_realm, current_sub_realm)
	emit_signal("realm_changed", current_realm, old_realm)
	emit_signal("lifespan_changed", lifespan - current_age, lifespan)
	
	return result

# 时间流逝
func advance_time(years: int, karma_system: KarmaSystem, precept_system: PreceptSystem) -> Dictionary:
	var result = {
		"event": "time_advanced",
		"rebirth_occurred": false,
		"new_age": current_age + years
	}
	
	current_age += years
	emit_signal("lifespan_changed", max(0, lifespan - current_age), lifespan)
	
	if current_age >= lifespan:
		# 寿命结束，进入轮回
		var rebirth_result = do_rebirth(karma_system, precept_system)
		result["event"] = "rebirth"
		result["rebirth_occurred"] = true
		result["rebirth_result"] = rebirth_result
		result["is_liberated"] = is_liberated
	
	return result

# 延长寿命（用于坐禅、丹药等效果）
func extend_lifespan(years: int, _karma_system = null, _precept_system = null) -> void:
	lifespan += years
	emit_signal("lifespan_changed", max(0, lifespan - current_age), lifespan)

# 获取当前状态概览
func get_current_status() -> Dictionary:
	return {
		"three_realm": current_three_realm,
		"three_realm_name": get_three_realm_name(current_three_realm),
		"realm": current_realm,
		"realm_name": get_realm_name(current_realm),
		"sub_realm": current_sub_realm,
		"sub_realm_name": get_sub_realm_name(current_three_realm, current_sub_realm),
		"age": current_age,
		"lifespan": lifespan,
		"remaining_lifespan": max(0, lifespan - current_age),
		"rebirth_count": rebirth_count,
		"is_liberated": is_liberated
	}

# 获取累世记录
func get_past_lives(count: int = 10) -> Array:
	if count >= past_lives.size():
		return past_lives.duplicate()
	return past_lives.slice(past_lives.size() - count, past_lives.size())

# 获取当前道的颜色
func get_realm_color(realm_id: int) -> Color:
	match realm_id:
		SixRealms.HELL_REALM:
			return Color(0.4, 0, 0)  # 暗红
		SixRealms.HUNGRY_GHOST_REALM:
			return Color(0.5, 0.3, 0.1)  # 土黄
		SixRealms.ANIMAL_REALM:
			return Color(0.4, 0.4, 0.2)  # 暗黄
		SixRealms.ASURA_REALM:
			return Color(0.6, 0.4, 0.1)  # 金棕
		SixRealms.HUMAN_REALM:
			return Color(0.7, 0.7, 0.8)  # 浅蓝
		SixRealms.DEVA_REALM:
			return Color(0.8, 0.6, 0.2)  # 金色
	return Color.WHITE

# 从当前状态计算解脱难度（用于显示进度）
func get_liberation_progress(karma_system: KarmaSystem, precept_system: PreceptSystem) -> float:
	var net_karma = karma_system.get_net_karma() if karma_system else 0
	var precept_count = precept_system.get_kept_precept_count() if precept_system else 0
	
	# 两个维度：净业力(70%) + 持戒数(30%)
	var karma_progress = clampf(float(net_karma) / 8000.0, 0.0, 1.0)
	var precept_progress = float(precept_count) / 5.0
	var total = karma_progress * 0.7 + precept_progress * 0.3
	return clampf(total, 0.0, 1.0)