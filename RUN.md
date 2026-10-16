# How to run Tactical Ops

Run these from the project folder (`tactical ops/`).

```
godot --path godot          # title screen: Firing Range / Skirmish
godot -e --path godot       # open the Godot editor
godot --path godot res://scenes/firing_range.tscn   # Firing Range directly
godot --path godot res://scenes/skirmish.tscn       # Skirmish directly (or deploy from the range truck)
```

No in-game Controls menu yet: rebinding lived in the creeper game's F10 menu. This project has its own `user://`
folder ("Tactical Ops"), so rebinds made in the old combined Creeper Ops build don't carry over.
