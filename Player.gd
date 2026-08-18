extends Node2D

@export var level = 1
@export var max_health = 100
@export var current_health = 100
@export var base_attack = 10
@export var base_defense = 5
@export var realm = "炼气期"
@export var spirit_power = 100
@export var experience = 0
@export var exp_needed = 100

# 装备槽位（使用字典存储）
var weapon = null      # 武器
var armor = null       # 防具
var accessory = null   # 饰品

# 计算总属性
func get_total_attack():
	var total = base_attack
	if weapon and weapon.has("attack"): total += weapon.attack
	if accessory and accessory.has("attack"): total += accessory.attack
	return total

func get_total_defense():
	var total = base_defense
	if armor and armor.has("defense"): total += armor.defense
	if accessory and accessory.has("defense"): total += accessory.defense
	return total

func get_total_max_health():
	var total = max_health
	if armor and armor.has("health"): total += armor.health
	if accessory and accessory.has("health"): total += accessory.health
	return total

# 装备物品
func equip(item):
	match item.type:
		"weapon":
			weapon = item
		"armor":
			armor = item
		"accessory":
			accessory = item
	update_status()

# 卸下装备
func unequip(slot):
	match slot:
		"weapon":
			weapon = null
		"armor":
			armor = null
		"accessory":
			accessory = null
	update_status()

func take_damage(damage):
	current_health -= damage - get_total_defense()
	if current_health <= 0:
		current_health = 0

func meditate():
	spirit_power = min(100, spirit_power + 20)

func add_exp(amount):
	experience += amount
	print("获得 " + str(amount) + " 经验值！")
	if experience >= exp_needed:
		level_up()

func level_up():
	level += 1
	experience = 0
	exp_needed = int(exp_needed * 1.5)
	max_health += 20
	current_health = get_total_max_health()
	base_attack += 3
	base_defense += 2
	print("升级！当前等级: " + str(level))

func update_status():
	pass

# 添加到 Player.gd 的末尾
func use_consumable(item):
	match item.effect:
		"heal":
			current_health = min(current_health + item.value, max_health)
		"spirit":
			spirit_power = min(spirit_power + item.value, 100)
		"exp":
			add_exp(item.value)

# ===== 存档支持 =====
func get_save_data() -> Dictionary:
	return {
		"level": level,
		"max_health": max_health,
		"current_health": current_health,
		"base_attack": base_attack,
		"base_defense": base_defense,
		"realm": realm,
		"spirit_power": spirit_power,
		"experience": experience,
		"exp_needed": exp_needed,
		"weapon": weapon,
		"armor": armor,
		"accessory": accessory
	}

func load_save_data(data: Dictionary):
	if data.has("level"):
		level = data["level"]
	if data.has("max_health"):
		max_health = data["max_health"]
	if data.has("current_health"):
		current_health = data["current_health"]
	if data.has("base_attack"):
		base_attack = data["base_attack"]
	if data.has("base_defense"):
		base_defense = data["base_defense"]
	if data.has("realm"):
		realm = data["realm"]
	if data.has("spirit_power"):
		spirit_power = data["spirit_power"]
	if data.has("experience"):
		experience = data["experience"]
	if data.has("exp_needed"):
		exp_needed = data["exp_needed"]
	if data.has("weapon"):
		weapon = data["weapon"]
	if data.has("armor"):
		armor = data["armor"]
	if data.has("accessory"):
		accessory = data["accessory"]
	
	update_status()
