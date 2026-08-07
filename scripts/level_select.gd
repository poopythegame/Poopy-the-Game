@tool
extends MultiselectScreen
class_name LevelSelect

@onready var levels := Global.levels.levels
@onready var option_preview_prefab: PackedScene = load("uid://d4iv7vg2lnmus")

func _ready() -> void:
	super._ready()
	option_selected.connect(_on_option_selected)

func _add_options() -> void:
	for level in levels:
		var option := OptionDef.new()
		option.title = level.title
		option.portrait = level.thumbnail
		options.append(option)

func _preview_option(option: OptionDef, option_index: int) -> Control:
	var preview := option_preview_prefab.instantiate()
	var title_label: Label = preview.get_node("%LevelName")
	var rank_texture_rect: TextureRect = preview.get_node("%RankIcon")
	var rank_null: TextureRect = preview.get_node("%RankNull")
	var best_time_label: Label = preview.get_node("%BestTime")
	var best_time_null: VBoxContainer = preview.get_node("%TimeNull")
	title_label.text = levels[option_index].title
	var rank := Global.save_data.ranks[option_index]
	rank_texture_rect.texture = levels[option_index].rankings[rank].small_icon
	var best_time := Global.get_best_time(option_index)
	if best_time >= INF:
		rank_null.show()
		rank_texture_rect.hide()
		best_time_null.show()
		best_time_label.hide()
	else:
		best_time_label.text = "Best: %02d:%02d.%03d" % [best_time / 60, fmod(best_time, 60), fmod(best_time * 1000, 1000)]
	return preview

func _on_option_selected(index: int):
	Global.begin_level_title_card(index)