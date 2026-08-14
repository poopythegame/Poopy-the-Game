extends Resource
class_name LevelDesc

@export var title: String
@export var thumbnail: Texture2D
@export var jingle: AudioStream
@export var title_card: Texture2D
@export var title_card_delegate: Script
@export var music: AudioStream
@export var music_intro: AudioStream
@export var music_loop: AudioStream
@export var scene: PackedScene
@export var rankings: Array[RankDef]