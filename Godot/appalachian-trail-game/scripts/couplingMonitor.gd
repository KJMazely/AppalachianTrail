@tool
extends EditorScript

func _run():	
	var scripts = _get_all_scripts("res://")
	var signal_usage = 0
	var hardcoded_usage = 0
	var export_node_usage = 0 # Another form of coupling
	
	for path in scripts:
		var file = FileAccess.open(path, FileAccess.READ)
		if not file: continue
		
		while not file.eof_reached():
			var line = file.get_line().strip_edges()
			
			# Ignore comments
			if line.begins_with("#"):
				continue
			
			# COUNT LOOSE COUPLING (Signals)
			if ".emit(" in line or "emit_signal(" in line or ".connect(" in line:
				signal_usage += 1
				
			# COUNT TIGHT COUPLING (Hard-coded paths & traversals)
			# Matches: $Node, %UniqueNode, get_node(), get_parent(), get_tree()
			if "$" in line or "%" in line or "get_node(" in line or "get_parent(" in line or "get_tree()." in line:
				hardcoded_usage += 1
				
			# COUNT EXPORTS (Medium coupling)
			if "@export" in line and ("NodePath" in line or "Node" in line):
				export_node_usage += 1

	print("Total Scripts Scanned: ", scripts.size())
	print("Loose Coupling (Signals/Connects): ", signal_usage)
	print("Tight Coupling (Hardcoded Paths): ", hardcoded_usage)
	print("Medium Coupling (Exported Nodes): ", export_node_usage)
	
	if hardcoded_usage > 0:
		var ratio = float(signal_usage) / float(hardcoded_usage)
		print("Coupling Ratio (Signals / Hardcoded): %.2f" % ratio)
		if ratio > 1.0:
			print("Result: GOOD More signals than hard-coded paths")
		else:
			print("Result: WARNING High tight-coupling detected")

# Recursive function to find all .gd files
func _get_all_scripts(path: String) -> Array[String]:
	var scripts: Array[String] = []
	var dir = DirAccess.open(path)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				if not file_name.begins_with("."): # Ignore hidden folders like .godot
					scripts.append_array(_get_all_scripts(path + file_name + "/"))
			else:
				if file_name.ends_with(".gd"):
					scripts.append(path + file_name)
			file_name = dir.get_next()
	return scripts
