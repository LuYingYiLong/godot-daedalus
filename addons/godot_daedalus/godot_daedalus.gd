@tool
extends EditorPlugin

const DOCK_ICON: Texture2D = preload("uid://cyodif1e2iey7")
const MAIN_SCENE: PackedScene = preload("uid://qf05xb4jnata")

var dock: EditorDock


func _enter_tree() -> void:
	dock = EditorDock.new()
	dock.title = "Daedalus"
	dock.dock_icon = DOCK_ICON
	dock.default_slot = EditorDock.DOCK_SLOT_RIGHT_UL
	var dock_content: Node = MAIN_SCENE.instantiate()
	dock.add_child(dock_content)
	add_dock(dock)


func _exit_tree() -> void:
	remove_dock(dock)
	dock.queue_free()
	dock = null
