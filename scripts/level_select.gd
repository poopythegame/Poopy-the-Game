@tool
extends MultiselectScreen
class_name LevelSelect

@onready var levels := Global.levels.levels

func _ready() -> void:
    super._ready()
    option_selected.connect(_on_option_selected)

func _add_options() -> void:
    for level in levels:
        var option := OptionDef.new()
        option.title = level.title
        option.portrait = level.thumbnail
        options.append(option)

func _on_option_selected(index: int):
    Global.begin_level(index)