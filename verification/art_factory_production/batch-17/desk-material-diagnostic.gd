extends SceneTree

const CASES := {
    "desk-v007": "res://art/desk/iterations/v007/generated/desk.tscn",
    "desk-v061": "res://art/desk/iterations/v061/generated/desk.tscn",
    "desk-v061-no-probe": "res://art/desk/iterations/v061/generated/desk-no-probe.tscn",
}
const OUTPUT := "res://verification/art_factory_production/batch-17/desk-material-effective-values.json"

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var results: Dictionary = {}
    for candidate_id in CASES:
        var packed := load(CASES[candidate_id]) as PackedScene
        if packed == null:
            push_error("Could not load %s" % CASES[candidate_id])
            quit(1)
            return
        var instance := packed.instantiate()
        root.add_child(instance)
        await process_frame
        var meshes: Array[Dictionary] = []
        var probes: Array[String] = []
        for probe in instance.find_children("*", "ReflectionProbe3D", true, false):
            probes.append(String(instance.get_path_to(probe)))
        if probes.is_empty():
            for probe in instance.find_children("*", "ReflectionProbe", true, false):
                probes.append(String(instance.get_path_to(probe)))
        for item in instance.find_children("*", "MeshInstance3D", true, false):
            var mesh_instance := item as MeshInstance3D
            if mesh_instance.mesh == null:
                continue
            var surfaces: Array[Dictionary] = []
            for surface in range(mesh_instance.mesh.get_surface_count()):
                surfaces.append({
                    "index": surface,
                    "imported_surface_material": _material_record(mesh_instance.mesh.surface_get_material(surface)),
                    "surface_override": _material_record(mesh_instance.get_surface_override_material(surface)),
                    "material_override": _material_record(mesh_instance.material_override),
                    "effective_material": _material_record(mesh_instance.get_active_material(surface)),
                })
            meshes.append({
                "node_path": String(instance.get_path_to(mesh_instance)),
                "node_name": mesh_instance.name,
                "mesh_name": mesh_instance.mesh.resource_name,
                "layers": mesh_instance.layers,
                "surface_count": mesh_instance.mesh.get_surface_count(),
                "surfaces": surfaces,
            })
        results[candidate_id] = {
            "scene": CASES[candidate_id],
            "reflection_probes": probes,
            "mesh_instance_count": meshes.size(),
            "meshes": meshes,
        }
        instance.queue_free()
        await process_frame
    var document := {
        "engine": Engine.get_version_info(),
        "renderer": RenderingServer.get_current_rendering_method(),
        "review_room": "verification/poc2/candidates/primary/attempt-7/room_photo_luna.json",
        "candidates": results,
    }
    var file := FileAccess.open(OUTPUT, FileAccess.WRITE)
    if file == null:
        push_error("Could not write effective material report: %s" % OUTPUT)
        quit(1)
        return
    file.store_string(JSON.stringify(document, "\t"))
    file.close()
    print("ROOMSCALE_DESK_MATERIAL_DIAGNOSTIC_PASS output=%s" % OUTPUT)
    quit()

func _material_record(material: Material) -> Variant:
    if material == null:
        return null
    var result: Dictionary = {
        "class": material.get_class(),
        "resource_name": material.resource_name,
    }
    if material is StandardMaterial3D:
        var standard := material as StandardMaterial3D
        var color := standard.albedo_color
        result.merge({
            "albedo_rgba": [color.r, color.g, color.b, color.a],
            "transparency": standard.transparency,
            "metallic": standard.metallic,
            "roughness": standard.roughness,
            "rim_enabled": standard.rim_enabled,
            "rim": standard.rim,
            "rim_tint": standard.rim_tint,
            "clearcoat_enabled": standard.clearcoat_enabled,
            "clearcoat": standard.clearcoat,
            "clearcoat_roughness": standard.clearcoat_roughness,
        }, true)
    return result
