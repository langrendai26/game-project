extends Control

@onready var back_button = $CanvasLayer/BackButton
@onready var weapon_slot = $CanvasLayer/WeaponSlot
@onready var armor_slot = $CanvasLayer/ArmorSlot
@onready var accessory_slot = $CanvasLayer/AccessorySlot
@onready var description_label = $CanvasLayer/DescriptionLabel

# 当前选中的装备类型
var selected_type = ""

func _ready():
	# 连接信号
	back_button.connect("pressed", _on_back)
	weapon_slot.connect("pressed", _on_weapon_slot_click)
	armor_slot.connect("pressed", _on_armor_slot_click)
	accessory_slot.connect("pressed", _on_accessory_slot_click)
	
	# 设置初始显示
	weapon_slot.text = "武器槽"
	armor_slot.text = "防具槽"
	accessory_slot.text = "饰品槽"
	description_label.text = "点击装备槽来装备物品"

func _on_weapon_slot_click():
	# 模拟装备武器
	weapon_slot.text = "铁剑"
	description_label.text = "已装备: 铁剑\n攻击 +5\n一把普通的铁剑"

func _on_armor_slot_click():
	# 模拟装备防具
	armor_slot.text = "铁甲"
	description_label.text = "已装备: 铁甲\n防御 +8\n生命 +20\n坚固的铁甲"

func _on_accessory_slot_click():
	# 模拟装备饰品
	accessory_slot.text = "玉佩"
	description_label.text = "已装备: 玉佩\n攻击 +2\n防御 +2\n灵力 +10\n温润的玉佩"

func _on_back():
	var parent = get_parent()
	if parent != null and parent.has_method("close_current_panel"):
		parent.close_current_panel()
	else:
		queue_free()
