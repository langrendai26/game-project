extends Control

# 任务系统界面

@onready var back_button = $CanvasLayer/BackButton
@onready var quest_list = $CanvasLayer/QuestList
@onready var quest_details = $CanvasLayer/QuestDetails
@onready var category_tabs = $CanvasLayer/CategoryTabs

var quest_system: Node
var current_category = 0  # 0=主线, 1=支线, 2=每日

func _ready():
	back_button.connect("pressed", _on_back)
	setup_category_tabs()
	
	# 获取任务系统（确保只创建一个实例）
	quest_system = get_tree().get_first_node_in_group("quest")
	if quest_system == null:
		var existing_quests = get_tree().get_nodes_in_group("quest")
		if existing_quests.size() > 0:
			quest_system = existing_quests[0]
		else:
			quest_system = load("res://scripts/Quest.gd").new()
			get_tree().root.add_child(quest_system)
			quest_system.add_to_group("quest")
	
	# 连接信号
	quest_system.quest_updated.connect(_on_quest_updated)
	quest_system.quest_completed.connect(_on_quest_completed)
	
	update_quest_list()


func setup_category_tabs():
	category_tabs.add_item("主线")
	category_tabs.add_item("支线")
	category_tabs.add_item("每日")
	category_tabs.connect("tab_changed", _on_category_changed)


func _on_category_changed(tab: int):
	current_category = tab
	update_quest_list()


func update_quest_list():
	quest_list.clear()
	
	var quest_type
	match current_category:
		0: quest_type = quest_system.QuestType.MAIN
		1: quest_type = quest_system.QuestType.SIDE
		2: quest_type = quest_system.QuestType.DAILY
	
	# 显示进行中的任务
	var active = quest_system.get_active_quests(quest_type)
	for quest_id in active:
		var quest = quest_system.get_quest(quest_id)
		var status = quest_system.get_quest_status(quest_id)
		var progress = quest_system.get_quest_progress(quest_id)
		var target_count = quest["target"]["count"]
		
		var status_text = ""
		match status:
			quest_system.QuestStatus.ACCEPTED: status_text = "进行中"
			quest_system.QuestStatus.COMPLETED: status_text = "可领取"
		
		var item_text = "%s [%s] (%d/%d)" % [quest["name"], status_text, progress, target_count]
		quest_list.add_item(item_text)
	
	# 显示可接取的任务
	var available = quest_system.get_available_quests(quest_type)
	for quest_id in available:
		var quest = quest_system.get_quest(quest_id)
		quest_list.add_item("[可接] " + quest["name"])


func _on_quest_list_item_selected(index: int):
	var quest_type
	match current_category:
		0: quest_type = quest_system.QuestType.MAIN
		1: quest_type = quest_system.QuestType.SIDE
		2: quest_type = quest_system.QuestType.DAILY
	
	var active = quest_system.get_active_quests(quest_type)
	var available = quest_system.get_available_quests(quest_type)
	
	var quest_id = ""
	if index < active.size():
		quest_id = active[index]
		show_quest_details(quest_id, true)
	elif index >= active.size():
		var avail_index = index - active.size()
		if avail_index < available.size():
			quest_id = available[avail_index]
			show_quest_details(quest_id, false)


func show_quest_details(quest_id: String, has_accepted: bool):
	var quest = quest_system.get_quest(quest_id)
	if quest.is_empty():
		return
	
	var status = quest_system.get_quest_status(quest_id)
	var progress = quest_system.get_quest_progress(quest_id)
	var target_count = quest["target"]["count"]
	
	quest_details.text = "【%s】%s\n\n" % [quest_system.get_quest_type_name(quest["type"]), quest["name"]]
	quest_details.text += "描述: %s\n\n" % quest["desc"]
	quest_details.text += "进度: %d/%d\n\n" % [progress, target_count]
	quest_details.text += "奖励:\n"
	quest_details.text += "  经验: +%d\n" % quest["reward"]["exp"]
	quest_details.text += "  金币: +%d\n" % quest["reward"]["gold"]
	
	if quest["reward"]["items"].size() > 0:
		quest_details.text += "  物品: %s\n" % str(quest["reward"]["items"])
	
	quest_details.text += "\n状态: "
	match status:
		quest_system.QuestStatus.LOCKED: quest_details.text += "未解锁"
		quest_system.QuestStatus.AVAILABLE: quest_details.text += "可接取"
		quest_system.QuestStatus.ACCEPTED: quest_details.text += "进行中"
		quest_system.QuestStatus.COMPLETED: quest_details.text += "可领取奖励"
		quest_system.QuestStatus.REWARDED: quest_details.text += "已完成"
	
	# 操作按钮提示
	if has_accepted and status == quest_system.QuestStatus.COMPLETED:
		quest_details.text += "\n\n[点击'领取奖励'按钮领取]"
	elif not has_accepted and status == quest_system.QuestStatus.AVAILABLE:
		quest_details.text += "\n\n[点击'接取任务'按钮接取]"


func _on_quest_updated(_quest_id: String):
	update_quest_list()


func _on_quest_completed(_quest_id: String):
	update_quest_list()


func _on_back():
	# 通知父节点清理面板引用
	var parent = get_parent()
	if parent != null and parent.has_method("close_current_panel"):
		parent.close_current_panel()
	else:
		queue_free()  # 销毁自身


func _on_accept_quest():
	var quest_type
	match current_category:
		0: quest_type = quest_system.QuestType.MAIN
		1: quest_type = quest_system.QuestType.SIDE
		2: quest_type = quest_system.QuestType.DAILY
	
	var available = quest_system.get_available_quests(quest_type)
	if quest_list.selected >= 0:
		var index = quest_list.selected - quest_system.get_active_quests(quest_type).size()
		if index >= 0 and index < available.size():
			quest_system.accept_quest(available[index])
			update_quest_list()


func _on_claim_reward():
	var quest_type
	match current_category:
		0: quest_type = quest_system.QuestType.MAIN
		1: quest_type = quest_system.QuestType.SIDE
		2: quest_type = quest_system.QuestType.DAILY
	
	var active = quest_system.get_active_quests(quest_type)
	if quest_list.selected >= 0 and quest_list.selected < active.size():
		var quest_id = active[quest_list.selected]
		var reward = quest_system.claim_quest_reward(quest_id)
		if not reward.is_empty():
			quest_details.text = "奖励已领取!\n\n获得:\n  经验: +%d\n  金币: +%d" % [reward["exp"], reward["gold"]]
			update_quest_list()
