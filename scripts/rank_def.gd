extends Resource
class_name RankDef

@export var letter: String
@export_range(.001, 60 * 60, .001, "suffix:s") var time: float