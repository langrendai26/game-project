extends Control

# 背包系统 - 完善版
# 支持分类、搜索、扩容、耐久度

@onready var back_button = $CanvasLayer/BackButton
@onready var grid_container = $CanvasLayer/GridContainer
@onready var description_label = $CanvasLayer/DescriptionLabel
@onready var category_buttons = $CanvasLayer/CategoryButtons
@onready var search_box = $CanvasLayer/SearchBox
@onready var expand_button = $CanvasLayer/ExpandButton
@onready var sort_button = $CanvasLayer/SortButton
@onready var gold_label = $CanvasLayer/GoldLabel

# 背包容量
var base_max_slots = 20
var max_slots = 20
var inventory = []

# 物品数据库 - 三界模拟器（纯佛教世界观）
var item_database = {
	# ========== 佛珠 ==========
	"wood_mala": {"name": "木念珠", "type": "accessory", "rarity": "common", "merit_bonus": 0.02, "karma_effect": "minor", "desc": "普通木材所制念珠，持念可增长善根。", "price": 50},
	"bodhi_mala": {"name": "菩提子念珠", "type": "accessory", "rarity": "uncommon", "merit_bonus": 0.05, "karma_effect": "medium", "desc": "菩提子所串念珠，乃念佛持咒之法器。", "price": 200},
	"sandalwood_mala": {"name": "檀香念珠", "type": "accessory", "rarity": "rare", "merit_bonus": 0.10, "karma_effect": "good", "desc": "檀香木念珠，香气宜人，持之身心清净。", "price": 800},
	"crystal_mala": {"name": "水晶念珠", "type": "accessory", "rarity": "rare", "merit_bonus": 0.08, "karma_effect": "good", "desc": "水晶所制念珠，澄澈透明，助心入定。", "price": 600},
	"gold_mala": {"name": "金念珠", "type": "accessory", "rarity": "epic", "merit_bonus": 0.15, "karma_effect": "great", "desc": "以金铸造之念珠，珍贵稀有，供佛最佳。", "price": 3000},
	"relic_mala": {"name": "舍利念珠", "type": "accessory", "rarity": "legendary", "merit_bonus": 0.25, "karma_effect": "supreme", "desc": "内含舍利之念珠，加持力不可思议。", "price": 10000},
	
	# ========== 法器 ==========
	"dharma_ring": {"name": "法轮戒", "type": "accessory", "rarity": "rare", "merit_bonus": 0.06, "karma_effect": "good", "desc": "刻有法轮之戒指，象征转法轮度众生。", "price": 1000},
	"lotus_pendant": {"name": "莲花坠", "type": "accessory", "rarity": "uncommon", "merit_bonus": 0.03, "karma_effect": "medium", "desc": "莲花形吊坠，出淤泥而不染。", "price": 300},
	"vajra_pendant": {"name": "金刚杵坠", "type": "accessory", "rarity": "epic", "merit_bonus": 0.12, "karma_effect": "great", "desc": "金刚杵形吊坠，摧破烦恼，坚固不坏。", "price": 2500},
	"om_pendant": {"name": "嗡字坠", "type": "accessory", "rarity": "rare", "merit_bonus": 0.07, "karma_effect": "good", "desc": "刻有梵文嗡字之吊坠，万法之源。", "price": 900},
	
	# ========== 僧衣 ==========
	"monk_robe": {"name": "缦衣", "type": "armor", "rarity": "common", "defense": 2, "merit_bonus": 0.02, "desc": "出家人所著之缦衣，远离装饰，朴素为美。", "price": 100},
	"kashaya_robe": {"name": "袈裟", "type": "armor", "rarity": "uncommon", "defense": 4, "merit_bonus": 0.05, "desc": "坏色袈裟，三衣之一，表佛弟子之标帜。", "price": 400},
	"elder_robe": {"name": "长老衣", "type": "armor", "rarity": "rare", "defense": 6, "merit_bonus": 0.08, "desc": "德高望重长老所传之衣，加持深厚。", "price": 1500},
	"patriarch_robe": {"name": "祖师衣", "type": "armor", "rarity": "epic", "defense": 10, "merit_bonus": 0.15, "desc": "历代祖师所传法衣，代代相承，灯灯无尽。", "price": 5000},
	
	# ========== 佛经 ==========
	"sutra_heart": {"name": "心经", "type": "consumable", "rarity": "common", "effect": "merit", "value": 50, "desc": "《般若波罗蜜多心经》，诵之开智慧。", "price": 50, "use_effect": "recite_sutra"},
	"sutra_diamond": {"name": "金刚经", "type": "consumable", "rarity": "uncommon", "effect": "merit", "value": 100, "desc": "《金刚般若波罗蜜经》，破除一切相。", "price": 150, "use_effect": "recite_sutra"},
	"sutra_lotus": {"name": "法华经", "type": "consumable", "rarity": "rare", "effect": "merit", "value": 200, "desc": "《妙法莲华经》，开示一佛乘。", "price": 500, "use_effect": "recite_sutra"},
	"sutra_earth_store": {"name": "地藏经", "type": "consumable", "rarity": "rare", "effect": "purify_sin", "value": 80, "desc": "《地藏菩萨本愿经》，消业增福。", "price": 450, "use_effect": "purify_sutra"},
	"sutra_medicine": {"name": "药师经", "type": "consumable", "rarity": "rare", "effect": "merit_heal", "value": 150, "desc": "《药师琉璃光如来本愿功德经》，消灾延寿。", "price": 480, "use_effect": "heal_sutra"},
	"sutra_amitabha": {"name": "阿弥陀经", "type": "consumable", "rarity": "uncommon", "effect": "merit", "value": 120, "desc": "《佛说阿弥陀经》，念佛往生西方。", "price": 200, "use_effect": "recite_sutra"},
	"sutra_surangama": {"name": "楞严经", "type": "consumable", "rarity": "epic", "effect": "merit_purify", "value": 300, "desc": "《大佛顶首楞严经》，开悟之宝典。", "price": 2000, "use_effect": "great_sutra"},
	"sutra_huayan": {"name": "华严经", "type": "consumable", "rarity": "legendary", "effect": "supreme_merit", "value": 500, "desc": "《大方广佛华严经》，佛说圆满法。", "price": 5000, "use_effect": "supreme_sutra"},
	
	# ========== 咒语 ==========
	"mantra_om_mani": {"name": "六字真言", "type": "consumable", "rarity": "common", "effect": "merit", "value": 30, "desc": "唵嘛呢叭咪吽，观音菩萨心咒。", "price": 30, "use_effect": "mantra"},
	"mantra_surangama": {"name": "楞严咒", "type": "consumable", "rarity": "rare", "effect": "purify_merit", "value": 150, "desc": "大佛顶首楞严神咒，咒中之王。", "price": 800, "use_effect": "great_mantra"},
	"mantra_medicine": {"name": "药师咒", "type": "consumable", "rarity": "uncommon", "effect": "heal_merit", "value": 80, "desc": "药师琉璃光如来灌顶真言，治病延寿。", "price": 200, "use_effect": "heal_mantra"},
	"mantra_great_compassion": {"name": "大悲咒", "type": "consumable", "rarity": "rare", "effect": "merit_purify", "value": 120, "desc": "千手千眼无碍大悲心陀罗尼。", "price": 600, "use_effect": "great_mantra"},
	
	# ========== 丹药 ==========
	"peace_pill": {"name": "定心丹", "type": "consumable", "rarity": "uncommon", "effect": "merit_heal", "value": 30, "desc": "定心安神，助益禅定，同时增长善业。", "price": 200, "use_effect": "peace_pill"},
	"precept_pill": {"name": "戒体丹", "type": "consumable", "rarity": "rare", "effect": "strengthen_precept", "value": 50, "desc": "坚固戒体，减少破戒之障。", "price": 800, "use_effect": "precept_pill"},
	"incense_pill": {"name": "香积丸", "type": "consumable", "rarity": "common", "effect": "merit", "value": 15, "desc": "以香花和合成丸，供佛食之增善根。", "price": 50, "use_effect": "offer_pill"},
	"enlightenment_pill": {"name": "悟道丹", "type": "consumable", "rarity": "legendary", "effect": "supreme_merit", "value": 500, "desc": "古德所炼，服之能明心见性。", "price": 8000, "use_effect": "enlightenment_pill"},
	"liberation_pill": {"name": "解脱丹", "type": "consumable", "rarity": "legendary", "effect": "purify_all_sin", "value": 500, "desc": "消除一切业障，种下解脱之因。", "price": 10000, "use_effect": "liberation_pill"},
	
	# ========== 供品 ==========
	"incense_stick": {"name": "檀香", "type": "consumable", "rarity": "common", "effect": "offer_merit", "value": 10, "desc": "供佛之香，燃烧时香气上达诸天。", "price": 20, "use_effect": "offer_incense"},
	"lotus_flower": {"name": "莲花", "type": "consumable", "rarity": "common", "effect": "offer_merit", "value": 15, "desc": "以清净莲花供佛，表出淤泥而不染。", "price": 30, "use_effect": "offer_flower"},
	"pure_water": {"name": "净水", "type": "consumable", "rarity": "common", "effect": "offer_merit", "value": 5, "desc": "清净之水供佛，表身口意三业清净。", "price": 10, "use_effect": "offer_water"},
	"fruit_offering": {"name": "鲜果供", "type": "consumable", "rarity": "common", "effect": "offer_merit", "value": 12, "desc": "新鲜水果供佛，表善果成熟。", "price": 25, "use_effect": "offer_fruit"},
	"lamp_offering": {"name": "酥油灯", "type": "consumable", "rarity": "uncommon", "effect": "offer_merit", "value": 25, "desc": "供灯一盏，光明智慧，破除无明。", "price": 60, "use_effect": "offer_lamp"},
	"food_offering": {"name": "斋菜供", "type": "consumable", "rarity": "uncommon", "effect": "offer_merit", "value": 20, "desc": "清净斋食供佛供僧，增长福报。", "price": 80, "use_effect": "offer_food"},
	
	# ========== 材料 ==========
	"bodhi_seed": {"name": "菩提子", "type": "material", "rarity": "common", "desc": "制作念珠的珍贵材料。", "price": 80},
	"sandalwood_log": {"name": "檀香木", "type": "material", "rarity": "uncommon", "desc": "名贵檀香，用于制香与念珠。", "price": 200},
	"incense_ash": {"name": "香灰", "type": "material", "rarity": "common", "desc": "供佛之后的香灰，可入药。", "price": 15},
	"relic_fragment": {"name": "舍利碎片", "type": "material", "rarity": "epic", "desc": "稀有舍利碎片，加持力甚大。", "price": 3000},
	"lotus_root": {"name": "莲藕", "type": "material", "rarity": "common", "desc": "莲花之根，可入药可食用。", "price": 20},
	"herb_medicine": {"name": "药草", "type": "material", "rarity": "common", "desc": "山中草药，炼制丹药之材料。", "price": 30},
	# ========== 炼丹材料 ==========
	"sandalwood_powder": {"name": "檀香粉", "type": "material", "rarity": "common", "desc": "研磨细碎的檀香粉，炼丹基础材料。", "price": 25},
	"wisdom_grass": {"name": "慧草", "type": "material", "rarity": "uncommon", "desc": "生于灵山之慧草，能开启智慧。", "price": 60},
	"sutra_fragment": {"name": "经文残片", "type": "material", "rarity": "uncommon", "desc": "残破经卷的片段，蕴藏佛法之力。", "price": 80},
	"honey": {"name": "蜂蜜", "type": "material", "rarity": "common", "desc": "清净花蜜，炼丹辅料。", "price": 15},
	"lotus_petal": {"name": "莲瓣", "type": "material", "rarity": "common", "desc": "清净莲花之瓣，象征慈悲。", "price": 20},
	"compassion_banner": {"name": "慈悲幡", "type": "material", "rarity": "rare", "desc": "信众所制慈悲幡旗，凝聚善愿。", "price": 150},
	"sacred_ash": {"name": "圣灰", "type": "material", "rarity": "uncommon", "desc": "供佛香火所凝之圣灰，具净化力。", "price": 50},
	"incense_powder": {"name": "香粉", "type": "material", "rarity": "common", "desc": "多种香料研磨而成，用于炼丹。", "price": 30},
	"longevity_herb": {"name": "长生草", "type": "material", "rarity": "rare", "desc": "罕见灵草，服之能延年益寿。", "price": 200},
	"golden_flower": {"name": "金莲花", "type": "material", "rarity": "rare", "desc": "金色莲花，诸佛加持之瑞相。", "price": 180}
}

# 当前分类
var current_category = "all"
# 当前搜索关键词
var search_text = ""
# 排序方式
var sort_mode = "name"  # name, rarity, type
# 耐久度字典 {slot_index: durability}
var durability = {}

# 扩容费用表
var expand_cost = 10  # 每扩展1格需要10金币

func _ready():
	print("[Inventory] _ready() called")
	add_to_group("inventory")
	print("[Inventory] Added to group 'inventory'")
	setup_ui()
	print("[Inventory] setup_ui() done")
	init_inventory()
	print("[Inventory] init_inventory() done")
	update_display()
	print("[Inventory] update_display() done")


func setup_ui():
	if back_button:
		back_button.connect("pressed", _on_back)
	if expand_button:
		expand_button.connect("pressed", _on_expand)
	if sort_button:
		sort_button.connect("pressed", _on_sort)
	
	if category_buttons:
		var categories = ["all", "weapon", "armor", "accessory", "consumable", "material"]
		for cat in categories:
			var btn = Button.new()
			btn.text = get_category_name(cat)
			btn.connect("pressed", func(): _on_category_selected(cat))
			category_buttons.add_child(btn)
	
	if search_box:
		search_box.connect("text_changed", _on_search_changed)


func init_inventory():
	# 初始化背包
	inventory.resize(max_slots)
	inventory.fill(null)
	durability.clear()
	
	# 添加初始物品 - 佛教修行起步装备
	add_item("wood_mala")         # 木念珠
	add_item("monk_robe")          # 缦衣
	add_item("sutra_heart")        # 心经
	add_item("incense_stick")      # 檀香
	add_item("pure_water")         # 净水
	add_item("lotus_flower")       # 莲花


func update_display():
	# 更新显示
	if grid_container == null:
		return
	
	var filtered_items = get_filtered_items()
	
	# 确保有足够的格子
	while grid_container.get_child_count() < max_slots:
		var slot = Button.new()
		slot.size = Vector2(60, 60)
		slot.text = ""
		slot.flat = false
		slot.mouse_filter = 2  # MOUSE_FILTER_STOP
		slot.add_theme_color_override("font_color", Color.WHITE)
		slot.add_theme_color_override("hover_font_color", Color.WHITE)
		slot.add_theme_color_override("pressed_font_color", Color.WHITE)
		var slot_idx = grid_container.get_child_count()
		slot.connect("pressed", func(): _on_slot_click(slot_idx))
		grid_container.add_child(slot)
	
	for i in range(max_slots):
		var slot = grid_container.get_child(i)
		if i < filtered_items.size() and filtered_items[i] != null:
			var item = filtered_items[i]
			var color = get_rarity_color(item.rarity)
			var icon = get_item_icon(item.type)
			slot.text = icon
			slot.modulate = color
			slot.disabled = false
			var bg_color = Color(0.1, 0.1, 0.1, 0.8)
			slot.add_theme_color_override("bg_color", bg_color)
			slot.add_theme_color_override("hover_bg_color", Color(0.2, 0.2, 0.2, 0.8))
		else:
			slot.text = ""
			slot.modulate = Color.WHITE
			slot.disabled = false
			var bg_color = Color(0.05, 0.05, 0.05, 0.5)
			slot.add_theme_color_override("bg_color", bg_color)
			slot.add_theme_color_override("hover_bg_color", Color(0.1, 0.1, 0.1, 0.5))
	
	# 更新金币显示
	if gold_label:
		var shop = get_shop()
		gold_label.text = "金币: " + str(shop.get_player_gold() if shop else 0)
	
	# 更新扩容按钮
	if expand_button:
		expand_button.text = "扩容 (" + str(expand_cost) + "金币)"


func get_filtered_items() -> Array:
	# 过滤和搜索物品
	var filtered = []
	for item in inventory:
		if item == null:
			continue
		
		# 分类过滤
		if current_category != "all" and item.type != current_category:
			continue
		
		# 搜索过滤
		if search_text != "" and item.name.find(search_text) == -1:
			continue
		
		filtered.append(item)
	
	# 排序
	match sort_mode:
		"name":
			filtered.sort_custom(func(a, b): return a.name < b.name)
		"rarity":
			var rarity_order = {"common": 0, "uncommon": 1, "rare": 2, "epic": 3, "legendary": 4}
			filtered.sort_custom(func(a, b): return rarity_order.get(a.rarity, 0) < rarity_order.get(b.rarity, 0))
		"type":
			filtered.sort_custom(func(a, b): return a.type < b.type)
	
	# 填充空位
	while filtered.size() < max_slots:
		filtered.append(null)
	
	return filtered


func get_items() -> Array:
	var items = []
	for item in inventory:
		if item != null:
			items.append(item)
	return items


func add_item(item_id: String, quantity: int = 1) -> bool:
	var item_data = item_database.get(item_id, {})
	if item_data.is_empty():
		return false

	var item_type = item_data.get("type", "")
	var stackable = not (item_type in ["weapon", "armor", "accessory"])

	if stackable:
		# 可堆叠物品：优先合并到已有格子
		var existing_slot = find_item(item_id)
		if existing_slot != -1:
			inventory[existing_slot]["quantity"] = inventory[existing_slot].get("quantity", 1) + quantity
			update_display()
			return true
		# 无已有堆叠，需要 1 个空位
		var empty_slot = find_empty_slot()
		if empty_slot == -1:
			print("背包已满！")
			return false
		inventory[empty_slot] = item_data.duplicate(true)
		inventory[empty_slot]["id"] = item_id
		inventory[empty_slot]["quantity"] = quantity
		inventory[empty_slot]["slot"] = empty_slot
		update_display()
		return true
	else:
		# 不可堆叠（武器/防具/饰品）：每件占用 1 格，需要连续放入
		var placed = 0
		for q in range(quantity):
			var empty_slot = find_empty_slot()
			if empty_slot == -1:
				if placed == 0:
					print("背包已满！")
					return false
				break
			inventory[empty_slot] = item_data.duplicate(true)
			inventory[empty_slot]["id"] = item_id
			inventory[empty_slot]["quantity"] = 1
			inventory[empty_slot]["slot"] = empty_slot
			durability[empty_slot] = 100
			placed += 1
		update_display()
		return placed > 0


func get_item_database() -> Dictionary:
	return item_database


func remove_item(slot_index: int, _quantity: int = 1) -> bool:
	if slot_index < 0 or slot_index >= max_slots or inventory[slot_index] == null:
		return false
	
	inventory[slot_index] = null
	durability.erase(slot_index)
	update_display()
	return true


func find_empty_slot() -> int:
	for i in range(max_slots):
		if inventory[i] == null:
			return i
	return -1


func find_item(item_id: String) -> int:
	for i in range(max_slots):
		if inventory[i] != null and inventory[i].get("id", "") == item_id:
			return i
	return -1


func get_empty_slot_count() -> int:
	var count = 0
	for i in range(max_slots):
		if inventory[i] == null:
			count += 1
	return count


func can_hold_items(item_id: String, quantity: int) -> bool:
	# 判断能容纳 quantity 个 item_id
	var item_data = item_database.get(item_id, {})
	if item_data.is_empty():
		return false
	var stackable = not (item_data.get("type", "") in ["weapon", "armor", "accessory"])
	if stackable:
		# 可堆叠：先看已有堆叠
		var existing_slot = find_item(item_id)
		if existing_slot != -1:
			return true  # 堆叠已有格子，无需新格
		# 无已有堆叠则需要 1 个空位
		return get_empty_slot_count() >= 1
	else:
		# 不可堆叠（装备类）：需要 quantity 个空位
		return get_empty_slot_count() >= quantity


func get_item_count(item_id: String) -> int:
	var count = 0
	for item in inventory:
		if item != null and item.get("id", "") == item_id:
			count += item.get("quantity", 1)
	return count


func _on_slot_click(index):
	var filtered_items = get_filtered_items()
	if index >= filtered_items.size() or filtered_items[index] == null:
		if description_label:
			description_label.text = "空槽位"
		return
	
	var item = filtered_items[index]
	show_item_details(item, index)


func show_item_details(item: Dictionary, slot_index: int):
	if not description_label:
		return
	
	description_label.text = item.name + "\n\n" + \
		"类型: " + get_type_name(item.type) + "\n" + \
		"稀有度: " + get_rarity_name(item.rarity) + "\n" + \
		"描述: " + item.desc + "\n"
	
	if item.has("attack"):
		description_label.text += "攻击: +" + str(item.attack) + "\n"
	if item.has("defense"):
		description_label.text += "防御: +" + str(item.defense) + "\n"
	if item.has("health"):
		description_label.text += "生命: +" + str(item.health) + "\n"
	if item.has("quantity"):
		description_label.text += "数量: " + str(item.quantity) + "\n"
	
	# 耐久度显示
	if durability.has(slot_index):
		description_label.text += "耐久度: " + str(durability[slot_index]) + "/100\n"
	
	# 价格显示
	if item.has("price"):
		description_label.text += "售价: " + str(int(item.price * 0.3)) + " 金币\n"
	
	# 操作提示
	description_label.text += "\n[左键] 使用/装备  [右键] 出售"


func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			handle_left_click()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			handle_right_click()


func handle_left_click():
	if not grid_container:
		return
	
	var pos = grid_container.get_global_mouse_position()
	var slot_index = get_slot_index_at_position(pos)
	if slot_index == -1:
		return
	
	var filtered_items = get_filtered_items()
	if slot_index >= filtered_items.size() or filtered_items[slot_index] == null:
		return
	
	var item = filtered_items[slot_index]
	
	match item.type:
		"consumable":
			use_item(slot_index)
		"weapon", "armor", "accessory":
			equip_item(slot_index)
		"material":
			print("材料物品，可用于炼器和炼丹")


func handle_right_click():
	if not grid_container:
		return
	
	var pos = grid_container.get_global_mouse_position()
	var slot_index = get_slot_index_at_position(pos)
	if slot_index == -1:
		return
	
	var filtered_items = get_filtered_items()
	if slot_index >= filtered_items.size() or filtered_items[slot_index] == null:
		return
	
	sell_item(slot_index)


func get_slot_index_at_position(pos: Vector2) -> int:
	if not grid_container:
		return -1
	
	for i in range(grid_container.get_child_count()):
		var slot = grid_container.get_child(i)
		if slot is Button:
			var rect = Rect2(slot.global_position, slot.size)
			if rect.has_point(pos):
				return i
	return -1


func use_item(slot_index: int):
	# 找到实际背包中的物品
	var actual_index = find_actual_slot_index(slot_index)
	if actual_index == -1:
		return
	
	var item = inventory[actual_index]
	if item == null or item.type != "consumable":
		return
	
	# 发送消息给玩家使用物品
	get_tree().call_group("player", "use_consumable", item)
	
	# 扣除数量
	var qty = item.get("quantity", 1) - 1
	if qty <= 0:
		inventory[actual_index] = null
	else:
		item["quantity"] = qty
	
	update_display()
	if description_label:
		description_label.text = "已使用: " + item.name


func equip_item(slot_index: int):
	var actual_index = find_actual_slot_index(slot_index)
	if actual_index == -1:
		return
	
	var item = inventory[actual_index]
	if item == null or item.type not in ["weapon", "armor", "accessory"]:
		return
	
	# 装备到玩家
	get_tree().call_group("player", "equip", item)
	if description_label:
		description_label.text = "已装备: " + item.name


func _on_slot_clicked(slot_index: int):
	var actual_index = find_actual_slot_index(slot_index)
	if actual_index == -1:
		return
	
	var item = inventory[actual_index]
	if item == null:
		if description_label:
			description_label.text = "空"
		return
	
	show_item_details(item, actual_index)


func sell_item(slot_index: int):
	var actual_index = find_actual_slot_index(slot_index)
	if actual_index == -1:
		return
	
	var item = inventory[actual_index]
	if item == null:
		return
	
	# 出售价格
	var sell_price = int(item.get("price", 0) * 0.3)
	var shop = get_shop()
	if shop:
		shop.add_gold(sell_price)
	
	if description_label:
		description_label.text = "已出售: " + item.name + "，获得 " + str(sell_price) + " 金币"
	inventory[actual_index] = null
	durability.erase(actual_index)
	update_display()


func find_actual_slot_index(display_index: int) -> int:
	var filtered_items = get_filtered_items()
	if display_index >= filtered_items.size() or filtered_items[display_index] == null:
		return -1
	
	var target_item = filtered_items[display_index]
	# 遍历实际背包找到对应物品
	for i in range(max_slots):
		if inventory[i] != null and inventory[i].get("id", "") == target_item.get("id", ""):
			return i
	return -1


func _on_category_selected(category: String):
	current_category = category
	update_display()


func _on_search_changed(text: String):
	search_text = text
	update_display()


func _on_sort():
	match sort_mode:
		"name": sort_mode = "rarity"
		"rarity": sort_mode = "type"
		"type": sort_mode = "name"
	update_display()


func _on_expand():
	var cost = expand_cost
	var shop = get_shop()
	
	if shop != null and shop.spend_gold(cost):
		max_slots += 5
		inventory.resize(max_slots)
		# 扩容费用递增
		expand_cost += 5
		# 创建新格子
		for i in range(5):
			var slot = Button.new()
			slot.size = Vector2(60, 60)
			slot.name = "Slot_" + str(max_slots - 5 + i)
			slot.flat = false
			slot.mouse_filter = 2
			var new_idx = max_slots - 5 + i
			slot.connect("pressed", func(): _on_slot_click(new_idx))
			grid_container.add_child(slot)
		
		description_label.text = "背包扩容成功！当前容量: " + str(max_slots)
		update_display()
	else:
		description_label.text = "金币不足！需要 " + str(cost) + " 金币"


func _on_back():
	var parent = get_parent()
	if parent != null and parent.has_method("close_current_panel"):
		parent.close_current_panel()
	else:
		queue_free()


func get_category_name(category: String) -> String:
	match category:
		"all": return "全部"
		"weapon": return "武器"
		"armor": return "防具"
		"accessory": return "饰品"
		"consumable": return "消耗品"
		"material": return "材料"
	return category


func get_type_name(type: String) -> String:
	match type:
		"weapon": return "武器"
		"armor": return "防具"
		"accessory": return "饰品"
		"consumable": return "消耗品"
		"material": return "材料"
	return "未知"


func get_rarity_name(rarity: String) -> String:
	match rarity:
		"common": return "普通"
		"uncommon": return "优秀"
		"rare": return "稀有"
		"epic": return "史诗"
		"legendary": return "传说"
	return "未知"


func get_rarity_color(rarity: String) -> Color:
	match rarity:
		"common": return Color.WHITE
		"uncommon": return Color.GREEN
		"rare": return Color.BLUE
		"epic": return Color.PURPLE
		"legendary": return Color.ORANGE
	return Color.WHITE


func get_item_icon(item_type: String) -> String:
	match item_type:
		"weapon": return "⚔"
		"armor": return "🛡"
		"accessory": return "💍"
		"consumable": return "🧪"
		"material": return "📦"
	return "❓"


func get_shop():
	var shop = get_tree().get_first_node_in_group("shop")
	if shop == null:
		# 尝试获取其他已存在的 shop 节点
		var shops = get_tree().get_nodes_in_group("shop")
		if shops.size() > 0:
			shop = shops[0]
	return shop


func get_save_data() -> Dictionary:
	return {
		"max_slots": max_slots,
		"base_max_slots": base_max_slots,
		"inventory": inventory,
		"durability": durability,
		"expand_cost": expand_cost
	}


func load_save_data(data: Dictionary):
	if data.has("max_slots"):
		max_slots = data["max_slots"]
	if data.has("base_max_slots"):
		base_max_slots = data["base_max_slots"]
	if data.has("inventory"):
		inventory = data["inventory"]
	if data.has("durability"):
		durability = data["durability"]
	if data.has("expand_cost"):
		expand_cost = data["expand_cost"]
