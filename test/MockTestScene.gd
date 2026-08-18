extends Control

@onready var test_panel = $TestPanelCanvas/TestPanel
@onready var test_title = $TestPanelCanvas/TestPanel/TestTitle
@onready var result_label = $TestPanelCanvas/TestPanel/ResultLabel
@onready var run_all_button = $TestPanelCanvas/TestPanel/ActionButtons/RunAllButton
@onready var test_inventory_button = $TestPanelCanvas/TestPanel/ActionButtons/TestInventoryButton
@onready var test_shop_button = $TestPanelCanvas/TestPanel/ActionButtons/TestShopButton
@onready var clear_log_button = $TestPanelCanvas/TestPanel/ActionButtons/ClearLogButton

var shop_system: Node = null
var inventory_script: Node = null
var inventory_ui: Node = null
var shop_ui: Node = null
var is_testing = false

func _ready():
	test_title.text = "🎮 Mock数据综合测试"
	result_label.text = "点击按钮开始测试...\n\n测试内容:\n• 背包点击响应\n• 商店购买功能\n• 金币系统联动"
	
	run_all_button.pressed.connect(_run_all_tests)
	test_inventory_button.pressed.connect(_test_inventory_click)
	test_shop_button.pressed.connect(_test_shop_purchase)
	clear_log_button.pressed.connect(_clear_log)
	
	get_tree().create_timer(0.5).timeout.connect(_on_delayed_init)

func _on_delayed_init():
	_init_systems()

func _init_systems():
	add_log("=== 初始化测试环境 ===")
	
	shop_system = load("res://scripts/Shop.gd").new()
	shop_system.name = "TestShop"
	add_child(shop_system)
	shop_system.add_to_group("shop")
	add_log("✓ 商店系统已创建 (初始金币: %d)" % shop_system.get_player_gold())
	
	var inventory_script_class = load("res://scripts/Inventory.gd")
	if inventory_script_class:
		inventory_script = inventory_script_class.new()
		inventory_script.name = "TestInventory"
		add_child(inventory_script)
		inventory_script.add_to_group("inventory")
		add_log("✓ 背包脚本已创建")
	else:
		add_log("✗ 无法加载背包脚本")
	
	get_tree().create_timer(0.3).timeout.connect(_on_systems_ready)

func _on_systems_ready():
	if inventory_script and inventory_script.has_method("add_item"):
		add_log("✓ 背包脚本方法可用")
		_add_mock_items()
	else:
		add_log("✗ 背包脚本方法不可用")
	
	$InventoryHolder.visible = true
	var inventory_scene = load("res://scripts/InventoryScene.tscn")
	if inventory_scene:
		inventory_ui = inventory_scene.instantiate()
		inventory_ui.name = "InventoryUI"
		$InventoryHolder.add_child(inventory_ui)
		add_log("✓ 背包UI场景已加载")
	else:
		add_log("✗ 无法加载背包场景")
	
	$ShopHolder.visible = true
	var shop_scene = load("res://scripts/ShopScene.tscn")
	if shop_scene:
		shop_ui = shop_scene.instantiate()
		shop_ui.name = "ShopUI"
		$ShopHolder.add_child(shop_ui)
		add_log("✓ 商店UI场景已加载")
	else:
		add_log("✗ 无法加载商店场景")
	
	$InventoryHolder.visible = false
	$ShopHolder.visible = false
	add_log("=== 测试环境初始化完成 ===")

func _add_mock_items():
	add_log("\n--- 添加Mock物品 ---")
	
	var mock_items = [
		{"id": "wood_mala", "qty": 1, "name": "木念珠"},
		{"id": "monk_robe", "qty": 1, "name": "缦衣"},
		{"id": "lotus_pendant", "qty": 1, "name": "莲花坠"},
		{"id": "sutra_heart", "qty": 5, "name": "心经"},
		{"id": "mantra_om_mani", "qty": 3, "name": "六字真言"},
		{"id": "bodhi_mala", "qty": 1, "name": "菩提子念珠"},
		{"id": "kashaya_robe", "qty": 1, "name": "袈裟"},
		{"id": "incense_stick", "qty": 10, "name": "檀香"},
	]
	
	var success_count = 0
	for item in mock_items:
		if inventory_script.add_item(item["id"], item["qty"]):
			add_log("  ✓ 添加: %s x%d" % [item["name"], item["qty"]])
			success_count += 1
		else:
			add_log("  ✗ 添加失败: %s" % item["name"])
	
	add_log("  总计: 添加 %d/%d 种物品" % [success_count, mock_items.size()])

func _run_all_tests():
	if is_testing:
		return
	is_testing = true
	
	add_log("\n=== 开始运行全部测试 ===")
	
	get_tree().create_timer(0.5).timeout.connect(_run_inventory_test)

func _run_inventory_test():
	_test_inventory_click()
	get_tree().create_timer(1.5).timeout.connect(_run_shop_test)

func _run_shop_test():
	_test_shop_purchase()
	add_log("\n=== 全部测试完成 ===")
	is_testing = false

func _test_inventory_click():
	add_log("\n--- 测试1: 背包点击响应 ---")
	
	$InventoryHolder.visible = true
	$ShopHolder.visible = false
	
	var inventory = get_tree().get_first_node_in_group("inventory")
	if inventory == null:
		inventory = inventory_script
	
	if inventory == null or not inventory.has_method("get_filtered_items"):
		add_log("  ✗ 找不到背包系统")
		return
	
	var filtered_items = inventory.get_filtered_items()
	var actual_items = inventory.get_items()
	add_log("  背包中有 %d 个物品" % actual_items.size())
	
	var click_count = 0
	for i in range(min(20, filtered_items.size())):
		if click_count >= 5:
			break
		var item = filtered_items[i]
		if item != null:
			add_log("  点击格子 %d: %s (%s)" % [i, item.name, item.type])
			if inventory.has_method("_on_slot_click"):
				inventory._on_slot_click(i)
			click_count += 1
	
	add_log("  ✓ 成功点击 %d 个格子" % click_count)

func _test_shop_purchase():
	add_log("\n--- 测试2: 商店购买功能 ---")
	
	$ShopHolder.visible = true
	$InventoryHolder.visible = false
	
	if shop_system == null:
		add_log("  ✗ 找不到商店系统")
		return
	
	var shop_types = [shop_system.ShopType.GENERAL, shop_system.ShopType.EQUIPMENT]
	var purchase_success = 0
	var purchase_fail = 0
	
	for shop_type in shop_types:
		var shop_info = shop_system.get_shop_info(shop_type)
		add_log("\n  商店: %s" % shop_info.get("name", "未知"))
		
		var items = shop_system.get_shop_items(shop_type)
		if items.size() > 0:
			var item = items[0]
			var gold_before = shop_system.get_player_gold()
			add_log("    尝试购买: %s (价格: %d金币)" % [item["name"], item["price"]])
			
			if shop_system.purchase_item(shop_type, item["id"], 1):
				var gold_after = shop_system.get_player_gold()
				add_log("    ✓ 购买成功！金币: %d → %d" % [gold_before, gold_after])
				purchase_success += 1
			else:
				add_log("    ✗ 购买失败")
				purchase_fail += 1
		else:
			add_log("    该商店没有物品")
	
	add_log("\n  购买结果: 成功 %d 次, 失败 %d 次" % [purchase_success, purchase_fail])
	
	var inventory = get_tree().get_first_node_in_group("inventory")
	if inventory and inventory.has_method("get_items"):
		var total_items = inventory.get_items().size()
		add_log("  当前背包物品数: %d" % total_items)

func _clear_log():
	result_label.text = "日志已清空\n\n点击按钮开始测试..."

func add_log(message: String):
	result_label.text += "\n" + message
	result_label.scroll_following = true
	print("[MockTest] " + message)