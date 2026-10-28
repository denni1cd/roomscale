extends Node3D
## Drives MPFB's standard game-engine rig from RoomScale's existing four limb pivots.

@onready var _skeleton: Skeleton3D = _find_skeleton()
const BONES := {
	"LeftArm": "upperarm_l",
	"RightArm": "upperarm_r",
	"LeftLeg": "thigh_l",
	"RightLeg": "thigh_r",
}
const VISUAL_GAINS := {
	"LeftArm": 1.0,
	"RightArm": 1.0,
	"LeftLeg": 0.35,
	"RightLeg": 0.35,
}


func _ready() -> void:
	set_process(_skeleton != null)
	if _skeleton == null:
		push_error("ROOMSCALE_MPFB_CITIZEN_V076_BRIDGE_FAIL: imported Skeleton3D is missing")
		return
	for bone_name in BONES.values():
		if _skeleton.find_bone(String(bone_name)) < 0:
			push_error("ROOMSCALE_MPFB_CITIZEN_V076_BRIDGE_FAIL: expected game_engine bone is missing: " + String(bone_name))
			set_process(false)
			return
	var high_detail_meshes := 0
	var distance_lod_meshes := 0
	for child in find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		if String(mesh_instance.name).ends_with("_LOD1"):
			mesh_instance.visibility_range_begin = 5.0
			mesh_instance.visibility_range_end = 0.0
			distance_lod_meshes += 1
		else:
			mesh_instance.visibility_range_begin = 0.0
			mesh_instance.visibility_range_end = 5.0
			high_detail_meshes += 1
	if high_detail_meshes != 8 or distance_lod_meshes != 8:
		push_error("ROOMSCALE_MPFB_CITIZEN_V076_BRIDGE_FAIL: expected 8 high-detail and 8 distance LOD meshes; got %d and %d" % [high_detail_meshes, distance_lod_meshes])
		set_process(false)
		return
	print("ROOMSCALE_MPFB_CITIZEN_V076_BRIDGE_PASS bones=", _skeleton.get_bone_count(), " pivots=5 high_detail_meshes=", high_detail_meshes, " distance_lod_meshes=", distance_lod_meshes, " switch_inches=5 rig=game_engine axis=bone_local visual_gains=", VISUAL_GAINS)


func _process(_delta: float) -> void:
	for pivot_name in BONES:
		_apply_pivot(pivot_name, String(BONES[pivot_name]))


func _find_skeleton() -> Skeleton3D:
	var rig := get_node_or_null("Body/MPFBGeneratedRig")
	return rig.find_child("Skeleton3D", true, false) as Skeleton3D if rig != null else null


func _apply_pivot(pivot_name: String, bone_name: String) -> void:
	var pivot := get_node_or_null(NodePath(pivot_name)) as Node3D
	var bone_index := _skeleton.find_bone(bone_name) if _skeleton != null else -1
	if pivot == null or bone_index < 0:
		return
	var angle := pivot.rotation.x * float(VISUAL_GAINS.get(pivot_name, 1.0))
	var target_global_pose := _skeleton.get_bone_global_rest(bone_index)
	var bone_local_delta := Basis(Vector3.RIGHT, angle)
	target_global_pose.basis = target_global_pose.basis * bone_local_delta
	_skeleton.set_bone_global_pose(bone_index, target_global_pose)
