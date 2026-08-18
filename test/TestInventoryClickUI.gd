extends Control

# 背包点击测试 UI
# 直接在编辑器中运行此场景，可以看到点击效果

@onready var grid_container = $CanvasLayer/GridContainer
@onready var description_label = $CanvasLayer/DescriptionLabel
@onready var test_button = $CanvasLayer/TestButton
@onready var result_label = $CanvasLayer/ResultLabel

@export var inventory_script: Script = preload("res://scripts/Inventory.gd")

var inventory: Node
var max_slots = 20
var selected_slot = -1

func _ready():
	# 创建背包系统
	inventory = inventory_script.new()
	inventory.init_inventory()
	
	# 添加测试物品
	add_test_items()
	
	# 创建格子
	create_grid()
	
	# 连接测试按钮
	test_button.pressed.connect(_on_test_button_pressed)
	
	result_label.text = "点击任意格子测试响应\n选中格子会高亮显示"

func create_grid():
	# 清除现有格子
	for child in grid_container.get_children():
		child.queue_free()
	
	# 创建格子
	for i in range(max_slots):
		var slot = Button.new()
		slot.size = Vector2(60, 60)
		slot.text = ""
		slot.flat = false
		slot.mouse_filter = 2  # MOUSE_FILTER_STOP
		slot.add_theme_color_override("font_color", Color.WHITE)
		slot.add_theme_color_override("hover_font_color", Color.YELLOW)
		var slot_idx = i
		slot.connect("pressed", func(): _on_slot_clicked(slot_idx))
		grid_container.add_child(slot)
	
	update_display()

func add_test_items():
	inventory.add_item("wood_mala", 1)
	inventory.add_item("monk_robe", 1)
	inventory.add_item("sutra_heart", 5)
	inventory.add_item("mantra_om_mani", 3)
	inventory.add_item("incense_stick", 10)
	inventory.add_item("lotus_pendant", 1)
	inventory.add_item("bodhi_mala", 1)

func update_display():
	var filtered = inventory.get_filtered_items()
	
	for i in range(max_slots):
		var slot = grid_container.get_child(i)
		
		if i < filtered.size() and filtered[i] != null:
			var item = filtered[i]
			var icon = get_item_icon(item.get("type", "unknown"))
			var color = get_rarity_color(item.get("rarity", "common"))
			
			slot.text = icon
			slot.modulate = color
			slot.disabled = false
			
			var bg_color = Color(0.1, 0.1, 0.1, 0.8)
			slot.add_theme_color_override("bg_color", bg_color)
			slot.add_theme_color_override("hover_bg_color", Color(0.3, 0.3, 0.3, 0.8))
		else:
			slot.text = ""
			slot.modulate = Color.WHITE
			slot.disabled = false
			
			var bg_color = Color(0.05, 0.05, 0.05, 0.5)
			slot.add_theme_color_override("bg_color", bg_color)
			slot.add_theme_color_override("hover_bg_color", Color(0.1, 0.1, 0.1, 0.5))

func _on_slot_clicked(slot_index: int):
	selected_slot = slot_index
	
	# 获取物品数据
	var items = inventory.get_filtered_items()
	var item_data = {}
	if slot_index < items.size() and items[slot_index] != null:
		var item = items[slot_index]
		var db = inventory.get_item_database()
		var item_id = item.get("id", "")
		var db_item = db.get(item_id, {})
		item_data = {
			"name": item.get("name", "未知"),
			"type": item.get("type", "未知"),
			"rarity": item.get("rarity", "common"),
			"description": db_item.get("desc", "无描述"),
			"price": db_item.get("price", 0)
		}
	
	# 高亮选中的格子
	for i in range(max_slots):
		var slot = grid_container.get_child(i)
		if i == slot_index:
			slot.add_theme_color_override("bg_color", Color(0.4, 0.4, 0.0, 0.8))
		elif i < items.size() and items[i] != null:
			var bg_color = Color(0.1, 0.1, 0.1, 0.8)
			slot.add_theme_color_override("bg_color", bg_color)
		else:
			var bg_color = Color(0.05, 0.05, 0.05, 0.5)
			slot.add_theme_color_override("bg_color", bg_color)
	
	if item_data.size() > 0:
		var item_name = item_data.get("name", "未知")
		var type = item_data.get("type", "未知")
		var rarity = item_data.get("rarity", "common")
		var desc = item_data.get("description", "无描述")
		var price = item_data.get("price", 0)
		
		description_label.text = "【%s】%s\n类型: %s | 稀有度: %s\n价格: %d 金币\n\n%s" % [
			get_rarity_emoji(rarity), item_name, type, rarity, price, desc
		]
		result_label.text = "✓ 格子 %d 点击响应成功！" % slot_index
	else:
		description_label.text = "空格子"
		result_label.text = "✓ 格子 %d 点击响应成功！（空格子）" % slot_index

func _on_test_button_pressed():
	# 随机点击一个格子进行测试
	var items = inventory.get_filtered_items()
	if items.size() > 0:
		var random_slot = randi() % items.size()
		_on_slot_clicked(random_slot)
		result_label.text = "✓ 随机测试: 点击格子 %d" % random_slot
	else:
		result_label.text = "背包为空，无法测试"

func get_item_icon(type: String) -> String:
	match type:
		"weapon": return "⚔️"
		"armor": return "🛡️"
		"accessory": return "💍"
		"consumable": return "🧪"
		"material": return "📦"
	return "❓"

func get_rarity_color(rarity: String) -> Color:
	match rarity:
		"common": return Color.WHITE
		"uncommon": return Color.GREEN
		"rare": return Color.BLUE
		"epic": return Color.PURPLE
		"legendary": return Color.ORANGE
	return Color.WHITE

func get_rarity_emoji(rarity: String) -> String:
	match rarity:
		"common": return "⚪"
		"uncommon": return "🟢"
		"rare": return "🔵"
		"epic": return "🟣"
		"legendary": return "🟠"
	return "⚪"
