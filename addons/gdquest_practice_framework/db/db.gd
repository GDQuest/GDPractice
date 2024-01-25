const Progress := preload("progress.gd")
const Metadata := preload("../metadata/metadata.gd")
const Paths := preload("../paths.gd")

var progress: Progress = null


func _init() -> void:
	var metadata_list := load(Paths.SOLUTIONS_PATH.path_join("metadata_list.tres"))
	if not ResourceLoader.exists(Progress.PATH):
		progress = Progress.new()
		for metadata: Metadata in metadata_list.metadatas:
			progress.state[metadata.id] = {completion = 0, tries = 0}
		save()
	reload()


func reload() -> void:
	progress = ResourceLoader.load(Progress.PATH, "", ResourceLoader.CACHE_MODE_IGNORE)


func save() -> void:
	ResourceSaver.save(progress)


func update(dict: Dictionary) -> void:
	for id in dict:
		for key in dict[id]:
			if key == "completion" and progress.state[id].completion == 1:
				continue
			progress.state[id][key] = dict[id][key]
	progress.emit_changed()
