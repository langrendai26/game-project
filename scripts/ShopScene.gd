extends Control

# 商店系统界面

@onready var back_button = $CanvasLayer/BackButton
@onready var shop_name_label = $CanvasLayer/ShopNameLabel
@onready var item_list = $CanvasLayer/ItemList
@onready var item_details = $CanvasLayer/ItemDetails
@onready var gold_label = $CanvasLayer/GoldLabel
@onready var shop_tabs = $CanvasLayer/ShopTabs

var shop_system: Node
var current_shop_type = 0


func _ready():
	back_button.connect("pressed", _on_back)
	setup_shop_tabs()
	
	var buy_button = $CanvasLayer/BuyButton
	if buy_button:
		buy_button.connect("pressed", _on_buy_button_pressed)
	
	var refresh_button = $CanvasLayer/RefreshButton
	if refresh_button:
		refresh_button.connect("pressed", _on_refresh_button_pressed)
	
	var item_list_node = $CanvasLayer/ItemList
	if item_list_node:
		item_list_node.connect("item_selected", _on_item_list_item_selected)
	
	# 获取商店系统（确保只创建一个实例）
	shop_system = get_tree().get_first_node_in_group("shop")
	if shop_system == null:
		# 检查是否已有 Shop 节点在场景树中
		var existing_shop = get_tree().get_nodes_in_group("shop")
		if existing_shop.size() > 0:
			shop_system = existing_shop[0]
		else:
			shop_system = load("res://scripts/Shop.gd").new()
			get_tree().root.add_child(shop_system)  # 添加到根节点
			shop_system.add_to_group("shop")
	
	# 连接信号
	shop_system.shop_purchased.connect(_on_purchased)
	shop_system.shop_sold.connect(_on_sold)
	shop_system.discount_updated.connect(_on_discount_updated)
	
	update_display()


func setup_shop_tabs():
	shop_tabs.add_item("杂货铺")
	shop_tabs.add_item("装备铺")
	shop_tabs.add_item("丹药铺")
	shop_tabs.add_item("神秘商人")
	shop_tabs.add_item("限时折扣")
	shop_tabs.connect("tab_changed", _on_shop_changed)


func _on_shop_changed(tab: int):
	current_shop_type = tab
	update_display()


func update_display():
	var shop_types = [shop_system.ShopType.GENERAL, shop_system.ShopType.EQUIPMENT, shop_system.ShopType.CONSUMABLE, shop_system.ShopType.SECRET, shop_system.ShopType.LIMITED]
	var shop_type = shop_types[current_shop_type]
	
	var shop_info = shop_system.get_shop_info(shop_type)
	shop_name_label.text = shop_info.get("name", "商店")
	shop_name_label.text += "\n" + shop_info.get("desc", "")
	
	# 显示限时折扣剩余时间
	if shop_type == shop_system.ShopType.LIMITED:
		var remaining = shop_system.get_limited_shop_remaining_time()
		var minutes = remaining / 60
		var seconds = remaining % 60
		shop_name_label.text += "\n剩余时间: %d:%02d" % [minutes, seconds]
	
	# 更新物品列表
	item_list.clear()
	var items = shop_system.get_shop_items(shop_type)
	for item in items:
		var item_text = "%s - %d 金币" % [item["name"], item["price"]]
		if item["on_sale"]:
			item_text += " [折扣!]"
		if item["stock"] > 0:
			item_text += " [库存:%d]" % item["stock"]
		item_list.add_item(item_text)
	
	# 更新金币显示
	gold_label.text = "金币: %d" % shop_system.get_player_gold()


func _on_item_list_item_selected(index: int):
	var shop_types = [shop_system.ShopType.GENERAL, shop_system.ShopType.EQUIPMENT, shop_system.ShopType.CONSUMABLE, shop_system.ShopType.SECRET, shop_system.ShopType.LIMITED]
	var shop_type = shop_types[current_shop_type]
	
	var items = shop_system.get_shop_items(shop_type)
	if index >= 0 and index < items.size():
		var item = items[index]
		
		item_details.text = "【%s】\n\n" % item["name"]
		item_details.text += "描述: %s\n\n" % item["desc"]
		
		if item["on_sale"]:
			item_details.text += "原价: %d 金币\n" % item["original_price"]
			item_details.text += "现价: %d 金币 [5折!]\n\n" % item["price"]
		else:
			item_details.text += "价格: %d 金币\n\n" % item["price"]
		
		if item["stock"] > 0:
			item_details.text += "库存: %d\n" % item["stock"]
		else:
			item_details.text += "库存: 无限\n"
		
		item_details.text += "\n点击购买 | 右键快速出售"


func _on_purchased(item_id: String, quantity: int):
	print("购买成功: " + item_id + " x" + str(quantity))
	update_display()


func _on_sold(item_id: String, quantity: int):
	print("出售成功: " + item_id + " x" + str(quantity))
	update_display()


func _on_discount_updated():
	update_display()


func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			handle_click(false)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			handle_click(true)


func handle_click(is_right_click: bool):
	var pos = item_list.get_global_mouse_position()
	var item_index = item_list.get_item_at_position(pos, true)
	
	if item_index < 0:
		return
	
	var shop_types = [shop_system.ShopType.GENERAL, shop_system.ShopType.EQUIPMENT, shop_system.ShopType.CONSUMABLE, shop_system.ShopType.SECRET, shop_system.ShopType.LIMITED]
	var shop_type = shop_types[current_shop_type]
	var items = shop_system.get_shop_items(shop_type)
	
	if item_index >= items.size():
		return
	
	var item = items[item_index]
	
	if is_right_click:
		# 快速出售（如果背包有该物品）
		var inventory = get_tree().get_first_node_in_group("inventory")
		if inventory:
			var slot = inventory.find_item(item["id"])
			if slot >= 0:
				inventory.sell_item(slot)
				item_details.text = "已出售: " + item["name"] + "!"
				update_display()
	else:
		# 购买
		if shop_system.purchase_item(shop_type, item["id"], 1):
			item_details.text = "购买成功: " + item["name"] + "!\n花费: " + str(item["price"]) + " 金币"
		else:
			item_details.text = "购买失败!\n金币不足或库存不足"


func _on_buy_button_pressed():
	var pos = item_list.get_global_mouse_position()
	var item_index = item_list.get_item_at_position(pos, true)
	
	if item_index < 0:
		return
	
	var shop_types = [shop_system.ShopType.GENERAL, shop_system.ShopType.EQUIPMENT, shop_system.ShopType.CONSUMABLE, shop_system.ShopType.SECRET, shop_system.ShopType.LIMITED]
	var shop_type = shop_types[current_shop_type]
	var items = shop_system.get_shop_items(shop_type)
	
	if item_index < items.size():
		var item = items[item_index]
		if shop_system.purchase_item(shop_type, item["id"], 1):
			item_details.text = "购买成功: " + item["name"]
		else:
			item_details.text = "购买失败!"


func _on_refresh_button_pressed():
	if current_shop_type == 4:  # 限时商店
		shop_system.refresh_limited_shop()
		item_details.text = "限时商店已刷新!"


func _on_back():
	# 通知父节点清理面板引用
	var parent = get_parent()
	if parent != null and parent.has_method("close_current_panel"):
		parent.close_current_panel()
	else:
		queue_free()  # 销毁自身
