class_name CombatLog
extends PanelContainer

@onready var entries: RichTextLabel = %Entries


func clear_entries() -> void:
	entries.clear()


func append_entry(message: String, color: Color = Color("d8dee9")) -> void:
	entries.push_color(color)
	entries.add_text(message)
	entries.pop()
	entries.newline()
	entries.scroll_to_line(maxi(entries.get_line_count() - 1, 0))
