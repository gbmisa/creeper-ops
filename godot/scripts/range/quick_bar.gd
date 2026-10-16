class_name QuickBar
extends PanelContainer
## Quick-use bar, bottom centre: the main game's build-menu panel and BuildCards, one card per ItemDefs.QUICK
## item with its key (t_slot_4 + n), how many you carry and what it does. Greyed when you carry none;
## the card stays pressed while that item is being used. A click on a card uses it (inventory open).

var quick: QuickUse
var _cards: Array[BuildCard] = []


func setup(q: QuickUse) -> void:
	quick = q
	add_theme_stylebox_override("panel", UiKit.style(UiKit.BG, UiKit.EDGE, 1, 8))
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 1.0
	anchor_bottom = 1.0
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	offset_bottom = -10
	UiKit.brackets(self)
	var row := UiKit.hbox(6)
	add_child(row)
	for n in ItemDefs.QUICK.size():
		var id: String = ItemDefs.QUICK[n]
		var c := BuildCard.new(id, n, str(ItemDefs.of(id)["glyph"]))
		c.pressed.connect(func(): quick.request(id))
		row.add_child(c)
		_cards.append(c)


func _process(_delta: float) -> void:
	if quick == null:
		return
	for n in _cards.size():
		var c := _cards[n]
		var d := ItemDefs.of(c.item)
		var have := quick.count(c.item)
		var line := "x%d %ds %s" % [have, int(d["use"]), "+%d%%" % int(float(d["heal"]) * 100.0) if d.has("heal") else "bleed"]
		if quick.using == c.item:
			line = "USING  %d%%" % int(quick.progress() * 100.0)
		c.show_info(Keybinds.short("t_slot_%d" % (n + 4)), str(d["short"]), line, "", false)
		c.disabled = have == 0 and quick.using != c.item
		c.set_pressed_no_signal(quick.using == c.item)
