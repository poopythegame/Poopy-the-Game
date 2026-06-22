extends Camera2D

var player: Player
var left_boundary: Node2D
var right_boundary: Node2D

func _ready() -> void:
    var candidates := get_tree().get_nodes_in_group("cam_boundary")
    print(len(candidates))
    for node in candidates:
        if node.flip:
            if right_boundary:
                push_error("Cannot have more than one camera left-boundary.")
            right_boundary = node
        else:
            print("madeit")
            if left_boundary:
                push_error("Cannot have more than one camera left-boundary.")
            left_boundary = node
    player = get_tree().get_first_node_in_group("Player")

func get_rect() -> Rect2:
    var pos := global_position
    var viewport_size := get_viewport_rect().size
    var world_size := viewport_size / zoom
    var top_left := pos - (world_size / 2.)
    return Rect2(top_left, world_size)

func _process(_delta: float) -> void:
    global_position = player.global_position
    var rect := get_rect()
    var left_x := rect.position.x
    var right_x := left_x + rect.size.x
    var shift_amount := 0.
    if left_boundary:
        if left_boundary.global_position.x > left_x:
            shift_amount = left_boundary.global_position.x - left_x
    if right_boundary:
        if right_boundary.global_position.x < right_x:
            shift_amount = right_boundary.global_position.x - right_x
    global_position.x += shift_amount