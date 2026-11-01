extends Node3D

func _ready() -> void:
	for item in find_children("*", "MeshInstance3D", true, false):
		(item as MeshInstance3D).layers = 2
