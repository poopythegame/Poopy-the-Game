extends CollisionShape2D

# We use groups to find these easily. 
# In the Node tab, add this node to a group called "GrapplePoints"
func get_point_position() -> Vector2:
	return global_position
