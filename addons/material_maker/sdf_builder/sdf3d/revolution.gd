extends "res://addons/material_maker/sdf_builder/sdf2d/union.gd"

func _ready():
	pass # Replace with function body.

func get_children_types():
	return [ "SDF2D", "SDF3D_COLOR" ]

func get_parameter_defs():
	return [
		{ label="Position.x", name="position_x", type="float", min=-1.0, max=1.0, step=0.01, default=0.0 },
		{ label="Position.y", name="position_y", type="float", min=-1.0, max=1.0, step=0.01, default=0.0 },
		{ label="Position.z", name="position_z", type="float", min=-1.0, max=1.0, step=0.01, default=0.0 },
		{ label="Rotation.x", name="angle_x", type="float", min=-180.0, max=180.0, step=0.01, default=0.0 },
		{ label="Rotation.y", name="angle_y", type="float", min=-180.0, max=180.0, step=0.01, default=0.0 },
		{ label="Rotation.z", name="angle_z", type="float", min=-180.0, max=180.0, step=0.01, default=0.0 },
		{ label="Scale", name="scale", type="float", min=-1.0, max=1.0, step=0.01, default=1.0 },
		{ label="Offset", name="offset", type="float", min=0.0, max=1.0, step=0.01, default=0.5 }
	]

func get_includes():
	return [ "sdf3d_rotate" ]

func shape_code(scene : Dictionary, uv : String = "$uv") -> String:
	return "1000000.0"

func scene_to_shader_model(scene : Dictionary, uv : String = "$uv", editor : bool = false) -> Dictionary:
	var output_name = "$(name_uv)_n%d" % scene.index
	var data : Dictionary = { parameters=[], outputs=[ { sdf3d=output_name, type="sdf3d" } ] }
	mm_sdf_builder.add_parameters(scene, data, get_parameter_defs())
	data.code = "vec3 %s_p = %s;\n" % [ output_name, uv ]
	if editor or mm_sdf_builder.check_non_zero_param(scene, "position_x") or mm_sdf_builder.check_non_zero_param(scene, "position_y") or mm_sdf_builder.check_non_zero_param(scene, "position_z"):
		data.code += "%s_p -= vec3($position_x, $position_y, $position_z);\n" % output_name
	data.code += mm_sdf_builder.generate_rotate_3d("%s_p" % output_name, scene, editor)
	if editor or mm_sdf_builder.check_non_zero_param(scene, "scale", 1.0):
		data.code += "%s_p /= $scale;\n" % [ output_name ]
	data.code += "vec2 %s_q = vec2(length(%s_p.xz)-$offset, %s_p.y);\n" % [ output_name, output_name, output_name ]
	shape_and_children_code(scene, data, "%s_q" % output_name, editor)
	if editor or mm_sdf_builder.check_non_zero_param(scene, "scale", 1.0):
		data.code += "%s *= $scale;\n" % output_name
	if editor:
		data.code += "if (index == %d) return %s;\n" % [ scene.index, output_name ]
	return data

func get_color_code(scene : Dictionary, ctxt : Dictionary = { uv="$uv" }, editor : bool = false) -> String:
	var ctxt2 : Dictionary = ctxt.duplicate()
	ctxt2.local_uv = "$(name_uv)_n%d_q" % scene.index
	ctxt2.uv = "$(name_uv)_n%d_q" % scene.index
	ctxt2.check = false
	var color_code : String = .get_color_code(scene, ctxt2, editor)
	if ctxt.has("check") and !ctxt.check:
		return "{\n%s}\n" % [ color_code ]
	else:
		return "if (_n%d < 0.001) {\n%s}\n" % [ scene.index, color_code ]
