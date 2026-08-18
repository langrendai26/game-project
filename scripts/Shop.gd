extends Node

# 商店系统 - 三界模拟器
# 佛教用品商店：法物流通处、经书坊、丹药房、稀有法宝

signal shop_purchased(item_id: String, quantity: int)
signal shop_sold(item_id: String, quantity: int)
signal discount_updated()

enum ShopType { GENERAL, EQUIPMENT, CONSUMABLE, SECRET, LIMITED }

# 商店数据
var shop_database = {
	ShopType.GENERAL: {
		"name": "法物流通处",
		"desc": "出售日常供佛用品与法器",
		"items": {
			"incense_stick": {"price": 20, "stock": -1, "desc": "供佛之香，增功德10"},
			"pure_water": {"price": 10, "stock": -1, "desc": "清净之水供佛，增功德5"},
			"lotus_flower": {"price": 30, "stock": -1, "desc": "莲花供佛，增功德15"},
			"fruit_offering": {"price": 25, "stock": -1, "desc": "鲜果供佛，增功德12"},
			"lamp_offering": {"price": 60, "stock": 20, "desc": "酥油灯供佛，增功德25"},
			"food_offering": {"price": 80, "stock": 15, "desc": "斋菜供佛僧，增功德20"},
			"sandalwood_powder": {"price": 25, "stock": -1, "desc": "檀香粉，炼丹基础材料"},
			"wisdom_grass": {"price": 60, "stock": -1, "desc": "慧草，能开启智慧"},
			"sutra_fragment": {"price": 80, "stock": -1, "desc": "经文残片，蕴藏佛法之力"},
			"honey": {"price": 15, "stock": -1, "desc": "清净花蜜，炼丹辅料"},
			"lotus_petal": {"price": 20, "stock": -1, "desc": "莲瓣，象征慈悲"},
			"compassion_banner": {"price": 150, "stock": 10, "desc": "慈悲幡，凝聚善愿"},
			"sacred_ash": {"price": 50, "stock": -1, "desc": "圣灰，具净化力"},
			"incense_powder": {"price": 30, "stock": -1, "desc": "香粉，用于炼丹"},
			"longevity_herb": {"price": 200, "stock": 5, "desc": "长生草，延年益寿"},
			"golden_flower": {"price": 180, "stock": 5, "desc": "金莲花，诸佛加持之瑞相"}
		}
	},
	ShopType.EQUIPMENT: {
		"name": "法器铺",
		"desc": "出售佛珠、法器、僧衣",
		"items": {
			"wood_mala": {"price": 50, "stock": -1, "desc": "木念珠，功德加成+2%"},
			"bodhi_mala": {"price": 200, "stock": -1, "desc": "菩提子念珠，功德加成+5%"},
			"sandalwood_mala": {"price": 800, "stock": 5, "desc": "檀香念珠，功德加成+10%"},
			"crystal_mala": {"price": 600, "stock": 5, "desc": "水晶念珠，功德加成+8%"},
			"monk_robe": {"price": 100, "stock": -1, "desc": "缦衣，功德加成+2%"},
			"kashaya_robe": {"price": 400, "stock": -1, "desc": "袈裟，功德加成+5%"},
			"lotus_pendant": {"price": 300, "stock": 10, "desc": "莲花坠，功德加成+3%"},
			"om_pendant": {"price": 900, "stock": 5, "desc": "嗡字坠，功德加成+7%"}
		}
	},
	ShopType.CONSUMABLE: {
		"name": "经咒坊",
		"desc": "出售佛经、咒语、丹药",
		"items": {
			"sutra_heart": {"price": 50, "stock": -1, "desc": "心经，诵之增功德50"},
			"sutra_diamond": {"price": 150, "stock": -1, "desc": "金刚经，诵之增功德100"},
			"sutra_amitabha": {"price": 200, "stock": 10, "desc": "阿弥陀经，增功德120"},
			"mantra_om_mani": {"price": 30, "stock": -1, "desc": "六字真言，增功德30"},
			"mantra_medicine": {"price": 200, "stock": 10, "desc": "药师咒，治病延寿"},
			"peace_pill": {"price": 200, "stock": 20, "desc": "定心丹，助益禅定"},
			"incense_pill": {"price": 50, "stock": -1, "desc": "香积丸，供佛增善根"}
		}
	},
	ShopType.SECRET: {
		"name": "稀有法宝",
		"desc": "珍贵法宝，需大量功德方可请购",
		"items": {
			"gold_mala": {"price": 3000, "stock": 2, "desc": "金念珠，功德加成+15%"},
			"vajra_pendant": {"price": 2500, "stock": 2, "desc": "金刚杵坠，功德加成+12%"},
			"elder_robe": {"price": 1500, "stock": 3, "desc": "长老衣，功德加成+8%"},
			"sutra_lotus": {"price": 500, "stock": 5, "desc": "法华经，增功德200"},
			"sutra_medicine": {"price": 480, "stock": 5, "desc": "药师经，消灾延寿"},
			"mantra_great_compassion": {"price": 600, "stock": 5, "desc": "大悲咒，消业增福"},
			"precept_pill": {"price": 800, "stock": 10, "desc": "戒体丹，坚固戒体"}
		}
	},
	ShopType.LIMITED: {
		"name": "限时法布施",
		"desc": "限时特惠法宝",
		"items": {},
		"discount": 0.5,
		"end_time": ""
	}
}

# 当前金币
var player_gold = 1000

# 限时商店刷新时间（秒）
var limited_shop_duration = 3600  # 1小时
var limited_shop_end_time = 0

# 折扣配置
var current_discount = 1.0  # 1.0 = 无折扣


func _ready():
	# 添加到 shop 组
	add_to_group("shop")
	# 初始化限时商店
	init_limited_shop()


# 获取商店信息
func get_shop_info(shop_type: ShopType) -> Dictionary:
	return shop_database.get(shop_type, {})


# 获取商店物品列表
func get_shop_items(shop_type: ShopType) -> Array:
	var shop = shop_database.get(shop_type, {})
	if shop.is_empty():
		return []
	
	var items = []
	for item_id in shop.get("items", {}):
		var item_data = shop["items"][item_id]
		# 检查库存
		if item_data["stock"] == 0:
			continue
		
		var final_price = int(item_data["price"] * current_discount)
		
		items.append({
			"id": item_id,
			"name": get_item_name(item_id),
			"price": final_price,
			"original_price": item_data["price"],
			"stock": item_data["stock"],
			"desc": item_data["desc"],
			"on_sale": current_discount < 1.0
		})
	
	return items


# 购买物品
func purchase_item(shop_type: ShopType, item_id: String, quantity: int = 1, inventory = null) -> bool:
	var shop = shop_database.get(shop_type, {})
	if shop.is_empty():
		return false

	var items = shop.get("items", {})
	if not items.has(item_id):
		return false

	var item_data = items[item_id]

	# 检查库存
	if item_data["stock"] >= 0 and item_data["stock"] < quantity:
		print("库存不足！")
		return false

	# 计算价格
	var total_price = int(item_data["price"] * current_discount * quantity)

	# 检查金币
	if player_gold < total_price:
		print("金币不足！需要 " + str(total_price) + "，拥有 " + str(player_gold))
		return false

	# [购买前校验] 如果传入了 inventory，先确认背包能装下
	if inventory != null:
		# 优先调用 can_hold_items，没有则退化为直接尝试 add_item
		if inventory.has_method("can_hold_items"):
			if not inventory.can_hold_items(item_id, quantity):
				print("背包空间不足，无法购买 %s × %d" % [item_id, quantity])
				return false

	# 扣除金币
	player_gold -= total_price

	# 扣除库存
	if item_data["stock"] > 0:
		item_data["stock"] -= quantity

	# 如果传了 inventory，则自动把物品加入背包（原子操作）
	if inventory != null:
		var added = inventory.add_item(item_id, quantity) if inventory.has_method("add_item") else false
		if not added:
			# 极端保护：加入失败时回滚金币与库存
			player_gold += total_price
			if item_data["stock"] > 0:
				item_data["stock"] += quantity
			print("背包已满，已回滚购买（金币退还）：%s × %d" % [item_id, quantity])
			return false

	# 触发购买事件（可用于任务系统）
	shop_purchased.emit(item_id, quantity)

	# 如果是限时商店买的，触发每日任务
	if shop_type == ShopType.LIMITED:
		var quest = get_tree().get_first_node_in_group("quest_system")
		if quest:
			quest.update_quest_progress("shop_trade", "", 1)

	print("购买成功: " + get_item_name(item_id) + " x" + str(quantity) + "，花费 " + str(total_price) + " 金币")
	return true


# 出售物品给商店
func sell_item(item_id: String, quantity: int = 1, inventory = null, karma_system = null) -> bool:
	# [SELL] 入口日志：记录调用参数与上下文
	print("[SELL] 调用 sell_item | item_id=%s | quantity=%d | has_inventory=%s | has_karma=%s" % [
		item_id, quantity, str(inventory != null), str(karma_system != null)
	])
	print("[SELL] 当前金币: %d" % player_gold)

	# 查找物品的回收价格（通常为原价的30%）
	var sell_price = get_item_sell_price(item_id)
	print("[SELL] get_item_sell_price 返回: %d" % sell_price)

	if sell_price <= 0:
		# [SELL] 拦截日志：详细列出拦截原因，便于排查负数/零价格物品
		var orig_price = _get_item_original_price(item_id)
		var item_name = get_item_name(item_id)
		print("[SELL][拦截] 出售被拒绝！sell_price=%d (<=0)" % sell_price)
		print("[SELL][拦截] 物品详情 | id=%s | name=%s | 背包库原价=%d" % [item_id, item_name, orig_price])
		print("[SELL][拦截] 拦截位置: sell_item() 中的 sell_price<=0 检查")
		print("[SELL][拦截] 后续影响: 背包/金币/功德/罪孽 均不会变化")
		# 兼容旧日志
		print("该物品不可出售")
		return false
	
	# 检查并从背包中移除物品（支持堆叠扣减）
	var removed = false
	if inventory:
		# 先统计总持有数量（考虑堆叠 quantity 字段）
		var total_owned = 0
		for i in range(len(inventory)):
			if inventory[i] != null and inventory[i].get("id", "") == item_id:
				total_owned += inventory[i].get("quantity", 1)

		if total_owned < quantity:
			print("背包中没有足够的物品！需要 %d，只有 %d" % [quantity, total_owned])
			return false

		# 从格子中逐个扣减（支持跨格扣减和部分扣减）
		var remaining = quantity
		for i in range(len(inventory)):
			if remaining <= 0:
				break
			if inventory[i] != null and inventory[i].get("id", "") == item_id:
				var slot_qty = inventory[i].get("quantity", 1)
				if slot_qty <= remaining:
					# 整格清空
					inventory[i] = null
					remaining -= slot_qty
				else:
					# 部分扣减（堆叠数量减少）
					inventory[i]["quantity"] = slot_qty - remaining
					remaining = 0
		removed = true
	
	var total_price = sell_price * quantity
	player_gold += total_price
	
	# 业力联动：出售佛教物品影响功德
	if karma_system:
		var _item_type = _get_item_type(item_id)
		var original_price = _get_item_original_price(item_id)
		if original_price > 0:
			var price_ratio = float(total_price) / float(original_price * quantity)
			if price_ratio <= 0.5:
				var merit_gain = int(original_price * quantity * 0.05)
				karma_system.add_merit(merit_gain, "出售%s（法布施心态）" % get_item_name(item_id))
	
	shop_sold.emit(item_id, quantity)
	print("出售成功: " + get_item_name(item_id) + " x" + str(quantity) + "，获得 " + str(total_price) + " 金币")
	return removed

# 获取物品类型
func _get_item_type(item_id: String) -> String:
	var item_db = load("res://scripts/Inventory.gd").new().item_database
	if item_db.has(item_id):
		return item_db[item_id].get("type", "")
	return ""

# 获取物品原价
func _get_item_original_price(item_id: String) -> int:
	var item_db = load("res://scripts/Inventory.gd").new().item_database
	if item_db.has(item_id):
		var price = item_db[item_id].get("price", 0)
		# 防御：确保价格为正数
		if price > 0:
			return price
	return 0


# 获取物品回收价格
func get_item_sell_price(item_id: String) -> int:
	var all_shops = shop_database
	for shop_type in all_shops:
		var items = all_shops[shop_type].get("items", {})
		if items.has(item_id):
			var raw_price = items[item_id]["price"]
			# 防御：确保价格为正数
			if raw_price <= 0:
				# [SELL] 拦截日志：定位到具体商店和原始价格，便于排查数据配置错误
				var shop_name = all_shops[shop_type].get("name", str(shop_type))
				print("[SELL][拦截] get_item_sell_price 命中负价/零价物品！")
				print("[SELL][拦截] 物品 id=%s | 商店=%s(shop_type=%s) | 原价=%d" % [
					item_id, shop_name, str(shop_type), raw_price
				])
				print("[SELL][拦截] 拦截位置: get_item_sell_price() 中的 raw_price<=0 检查")
				print("[SELL][拦截] 返回 0，sell_item 将拒绝出售")
				return 0
			var final_price = int(raw_price * 0.3)
			print("[SELL] 物品 id=%s | 商店原价=%d | 回收价=%d (原价×0.3)" % [item_id, raw_price, final_price])
			return final_price
	# 物品在所有商店中都找不到
	print("[SELL][拦截] 物品 id=%s 未在任何商店数据库中找到，返回 0" % item_id)
	return 0


# 获取物品名称
func get_item_name(item_id: String) -> String:
	var names = {
		"incense_stick": "檀香",
		"pure_water": "净水",
		"lotus_flower": "莲花",
		"fruit_offering": "鲜果供",
		"lamp_offering": "酥油灯",
		"food_offering": "斋菜供",
		"wood_mala": "木念珠",
		"bodhi_mala": "菩提子念珠",
		"sandalwood_mala": "檀香念珠",
		"crystal_mala": "水晶念珠",
		"gold_mala": "金念珠",
		"relic_mala": "舍利念珠",
		"monk_robe": "缦衣",
		"kashaya_robe": "袈裟",
		"elder_robe": "长老衣",
		"patriarch_robe": "祖师衣",
		"lotus_pendant": "莲花坠",
		"vajra_pendant": "金刚杵坠",
		"om_pendant": "嗡字坠",
		"dharma_ring": "法轮戒",
		"sutra_heart": "心经",
		"sutra_diamond": "金刚经",
		"sutra_lotus": "法华经",
		"sutra_earth_store": "地藏经",
		"sutra_medicine": "药师经",
		"sutra_amitabha": "阿弥陀经",
		"sutra_surangama": "楞严经",
		"sutra_huayan": "华严经",
		"mantra_om_mani": "六字真言",
		"mantra_surangama": "楞严咒",
		"mantra_medicine": "药师咒",
		"mantra_great_compassion": "大悲咒",
		"peace_pill": "定心丹",
		"precept_pill": "戒体丹",
		"incense_pill": "香积丸",
		"enlightenment_pill": "悟道丹",
		"liberation_pill": "解脱丹",
		"bodhi_seed": "菩提子",
		"sandalwood_log": "檀香木",
		"incense_ash": "香灰",
		"relic_fragment": "舍利碎片",
		"lotus_root": "莲藕",
		"herb_medicine": "药草"
	}
	return names.get(item_id, item_id)


# 初始化限时商店
func init_limited_shop():
	# 设置限时折扣物品
	var limited_shop = shop_database[ShopType.LIMITED]
	limited_shop["items"] = {
		"sandalwood_mala": {"price": 400, "stock": 1, "desc": "檀香念珠，功德加成+10%（限时5折）"},
		"elder_robe": {"price": 750, "stock": 1, "desc": "长老衣，功德加成+8%（限时5折）"},
		"sutra_lotus": {"price": 250, "stock": 3, "desc": "法华经，增功德200（限时5折）"}
	}
	limited_shop["discount"] = 0.5
	limited_shop_end_time = int(float(Time.get_ticks_msec()) / 1000.0) + limited_shop_duration
	
	discount_updated.emit()


# 检查限时商店是否过期
func check_limited_shop():
	if int(float(Time.get_ticks_msec()) / 1000.0) >= limited_shop_end_time:
		init_limited_shop()


# 获取限时商店剩余时间
func get_limited_shop_remaining_time() -> int:
	var remaining = limited_shop_end_time - int(float(Time.get_ticks_msec()) / 1000.0)
	return max(0, remaining)


# 刷新限时商店
func refresh_limited_shop():
	init_limited_shop()


# 获取玩家金币
func get_player_gold() -> int:
	return player_gold


# 设置玩家金币
func set_player_gold(amount: int):
	player_gold = max(0, amount)


# 添加金币
func add_gold(amount: int):
	player_gold += amount
	print("获得 " + str(amount) + " 金币")


# 花费金币
func spend_gold(amount: int) -> bool:
	if player_gold >= amount:
		player_gold -= amount
		return true
	return false


# 商店类型名称
func get_shop_type_name(shop_type: ShopType) -> String:
	match shop_type:
		ShopType.GENERAL: return "杂货铺"
		ShopType.EQUIPMENT: return "装备铺"
		ShopType.CONSUMABLE: return "丹药铺"
		ShopType.SECRET: return "神秘商人"
		ShopType.LIMITED: return "限时折扣"
	return "未知商店"


# 存档数据
func get_save_data() -> Dictionary:
	return {
		"player_gold": player_gold,
		"limited_shop_end_time": limited_shop_end_time,
		"shop_stock": get_stock_data()
	}


# 获取库存数据
func get_stock_data() -> Dictionary:
	var stock = {}
	for shop_type in shop_database:
		stock[shop_type] = {}
		for item_id in shop_database[shop_type].get("items", {}):
			stock[shop_type][item_id] = shop_database[shop_type]["items"][item_id]["stock"]
	return stock


# 加载存档数据
func load_save_data(data: Dictionary):
	if data.has("player_gold"):
		player_gold = data["player_gold"]
	if data.has("limited_shop_end_time"):
		limited_shop_end_time = data["limited_shop_end_time"]
	if data.has("shop_stock"):
		var stock = data["shop_stock"]
		for shop_type in stock:
			for item_id in stock[shop_type]:
				if shop_database.has(shop_type) and shop_database[shop_type]["items"].has(item_id):
					shop_database[shop_type]["items"][item_id]["stock"] = stock[shop_type][item_id]
