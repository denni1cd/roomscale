extends RefCounted
const G := preload("res://scripts/visuals/visual_geometry.gd")

static func build(parent: Node3D, object: Dictionary, recipe: Dictionary) -> bool:
	var kind := String(recipe.archetype)
	if kind not in ["desk", "table", "workbench", "chair", "bookcase", "wardrobe", "cabinet", "box"]:
		return false
	var dimensions: Array = object.dimensions
	var d := Vector3(float(dimensions[0]), float(dimensions[1]), float(dimensions[2]))
	var appearance: Dictionary = recipe.appearance
	var wood := Color(String(appearance.get("base_color", object.get("color", "71503b"))))
	var dark := wood.darkened(0.24)
	var brass := Color("b99451")
	match kind:
		"desk", "table", "workbench":
			var t := clampf(d.y * 0.06, 0.8, 2.0)
			G.box(parent, "BeveledTop", Vector3(d.x, t, d.z), Vector3(0, d.y - t * 0.5, 0), "wood", wood, t * 0.2)
			G.box(parent, "TopMolding", Vector3(d.x * 0.97, t * 0.3, d.z * 0.97), Vector3(0, d.y - t * 1.1, 0), "wood", dark, 0.1)
			for x in [-1, 1]:
				for z in [-1, 1]:
					G.box(parent, "TaperedLeg_%d_%d" % [x, z], Vector3(d.x * 0.04, d.y - t, d.z * 0.07), Vector3(x * d.x * 0.44, (d.y - t) * 0.5, z * d.z * 0.41), "wood", dark, 0.2)
					G.box(parent, "LegCollar%d_%d" % [x, z], Vector3(d.x * 0.048, 0.55, d.z * 0.085), Vector3(x * d.x * 0.44, d.y * 0.16, z * d.z * 0.41), "wood", wood, 0.12)
			for x in [-1, 1]:
				G.box(parent, "Apron%d" % x, Vector3(d.x * 0.88, d.y * 0.1, 0.7), Vector3(0, d.y - t - d.y * 0.05, x * d.z * 0.41), "wood", dark, 0.15)
			if d.x > d.y * 1.5:
				for row in range(3):
					var y := d.y * (0.42 + row * 0.15)
					G.box(parent, "Drawer%d" % row, Vector3(d.x * 0.22, d.y * 0.14, d.z * 0.66), Vector3(d.x * 0.31, y, 0), "wood", wood, 0.25)
					G.box(parent, "DrawerInset%d" % row, Vector3(d.x * 0.19, d.y * 0.09, 0.35), Vector3(d.x * 0.31, y, d.z * 0.34), "wood", dark, 0.08)
					G.box(parent, "BrassPull%d" % row, Vector3(d.x * 0.065, 0.4, 0.55), Vector3(d.x * 0.31, y, d.z * 0.35), "brass", brass, 0.14)
		"chair":
			var seat := d.y * 0.53
			G.box(parent, "SeatFrame", Vector3(d.x, d.y * 0.09, d.z * 0.82), Vector3(0, seat, 0), "wood", dark, 0.35)
			G.box(parent, "LeatherCushion", Vector3(d.x * 0.89, d.y * 0.1, d.z * 0.74), Vector3(0, seat + d.y * 0.065, 0), "leather", wood, 0.65)
			for x in [-1, 1]:
				for z in [-1, 1]:
					G.box(parent, "ChairLeg%d_%d" % [x, z], Vector3(d.x * 0.07, seat, d.z * 0.08), Vector3(x * d.x * 0.4, seat * 0.5, z * d.z * 0.32), "wood", dark, 0.18)
			for x in [-1, 1]:
				G.box(parent, "BackPost%d" % x, Vector3(d.x * 0.08, d.y * 0.45, d.z * 0.08), Vector3(x * d.x * 0.43, d.y * 0.76, -d.z * 0.37), "wood", dark, 0.16)
			G.box(parent, "UpholsteredBack", Vector3(d.x * 0.81, d.y * 0.33, d.z * 0.13), Vector3(0, d.y * 0.79, -d.z * 0.37), "leather", wood, 0.65)
			for x in [-1, 1]:
				G.box(parent, "SideStretcher%d" % x, Vector3(d.x * 0.05, d.y * 0.035, d.z * 0.67), Vector3(x * d.x * 0.4, seat * 0.35, 0), "wood", dark, 0.12)
				for y in [0.73, 0.86]:
					G.cylinder(parent, "UpholsteryButton", 0.18, 0.1, Vector3(x * d.x * 0.2, d.y * y, -d.z * 0.29), "leather", dark).rotation.x = PI * 0.5
		_:
			G.box(parent, "BackPanel", Vector3(d.x, d.y, d.z * 0.06), Vector3(0, d.y * 0.5, -d.z * 0.46), "wood", dark, 0.15)
			for x in [-1, 1]:
				G.box(parent, "Side%d" % x, Vector3(d.x * 0.06, d.y, d.z), Vector3(x * d.x * 0.47, d.y * 0.5, 0), "wood", wood, 0.22)
				G.box(parent, "FaceStile%d" % x, Vector3(d.x * 0.085, d.y * 0.96, 0.65), Vector3(x * d.x * 0.45, d.y * 0.5, d.z * 0.46), "wood", dark, 0.16)
			G.box(parent, "Cornice", Vector3(d.x, d.y * 0.045, d.z), Vector3(0, d.y * 0.976, 0), "wood", dark, 0.2)
			G.box(parent, "Plinth", Vector3(d.x, d.y * 0.055, d.z), Vector3(0, d.y * 0.0275, 0), "wood", dark, 0.2)
			for row in range(5):
				var y := d.y * (0.025 + row * 0.238)
				G.box(parent, "Shelf%d" % row, Vector3(d.x * 0.95, d.y * 0.025, d.z), Vector3(0, y, 0), "wood", wood, 0.16)
				if row < 4:
					for book in range(7):
						var colors := [Color("33525a"), Color("964c3d"), Color("b89d67"), Color("596344")]
						G.box(parent, "Book%d_%d" % [row, book], Vector3(d.x * 0.08, d.y * (0.14 + book % 3 * 0.013), d.z * 0.65), Vector3(-d.x * 0.36 + book * d.x * 0.115, y + d.y * 0.096, d.z * 0.02), "canvas", colors[(row + book) % 4], 0.12)
	return true
