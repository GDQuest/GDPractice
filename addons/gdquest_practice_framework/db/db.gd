const Progress := preload("progress.gd")
const Metadata := preload("../metadata.gd")

const MetadataList := preload("../metadata_list.gd")

var progress: Progress = null


func _init() -> void:
	if not ResourceLoader.exists(Progress.PATH):
		progress = Progress.new()
		for metadata_path: String in MetadataList.METADATA_PATHS:
			var metadata: Metadata = load(metadata_path)
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
