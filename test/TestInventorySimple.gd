extends Control

@onready var test_panel = $TestPanel
@onready var title_label = $TestPanel/TitleLabel
@onready var log_label = $TestPanel/LogLabel
@onready var click_button = $TestPanel/ClickButton
@onready var clear_button = $TestPanel/ClearButton

var inventory: Node = null
var shop: Node = null

func _ready():
	title_label.text = "🎒 背包点击测试"
	log_label.text = "点击下方按钮开始测试背包点击响应\n"
	
	click_button.pressed.connect(_test_click)
	clear_button.pressed.connect(_clear_log)
	
	_init_systems()

func _init_systems():
	add_log("=== 初始化测试系统 ===")
	
	shop = load("res://scripts/Shop.gd").new()
	shop.name = "TestShop"
	add_child(shop)
	shop.add_to_group("shop")
	add_log("✓ 商店系统已创建")
	
	var inventory_script = load("res://scripts/Inventory.gd")
	if inventory_script:
		inventory = inventory_script.new()
		inventory.name = "TestInventory"
		add_child(inventory)
		inventory.add_to_group("inventory")
		add_log("✓ 背包脚本已创建")
		
		add_log("\n--- 添加测试物品 ---")
		var test_items = [
			{"id": "wood_mala", "name": "木念珠"},
			{"id": "monk_robe", "name": "缦衣"},
			{"id": "lotus_pendant", "name": "莲花坠"},
			{"id": "sutra_heart", "name": "心经"},
			{"id": "incense_stick", "name": "檀香"},
		]
		
		for item in test_items:
			if inventory.add_item(item["id"]):
				add_log("  ✓ 添加: %s" % item["name"])
			else:
				add_log("  ✗ 添加失败: %s" % item["name"])
		
		add_log("\n背包物品总数: %d" % inventory.get_items().size())
	else:
		add_log("✗ 无法加载背包脚本")
	
	add_log("\n=== 初始化完成 ===")

func _test_click():
	if not inventory:
		add_log("✗ 背包系统未初始化")
		return
	
	add_log("\n--- 开始测试背包点击 ---")
	
	var filtered_items = inventory.get_filtered_items()
	var click_count = 0
	
	for i in range(filtered_items.size()):
		if click_count >= 5:
			break
		var item = filtered_items[i]
		if item != null:
			add_log("  点击格子 %d → %s (%s)" % [i, item.name, item.type])
			
			if inventory.has_method("_on_slot_click"):
				inventory._on_slot_click(i)
				add_log("    ✓ _on_slot_click 调用成功")
			else:
				add_log("    ✗ _on_slot_click 方法不存在")
			
			if inventory.has_method("show_item_details"):
				inventory.show_item_details(item, i)
				add_log("    ✓ show_item_details 调用成功")
			else:
				add_log("    ✗ show_item_details 方法不存在")
			
			click_count += 1
	
	add_log("\n✓ 测试完成！成功点击 %d 个物品" % click_count)

func _clear_log():
	log_label.text = "日志已清空\n点击下方按钮开始测试背包点击响应\n"

func add_log(message: String):
	log_label.text += "\n" + message
	log_label.scroll_following = true
	print("[Test] " + message)