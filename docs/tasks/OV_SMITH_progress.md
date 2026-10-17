# OV-SMITH progress (F141, F143), branch feat/f141-gunsmith
- P1 done (c6f3f14): range_station_props.gd (workbench, ammo bench, armor rack, truck extras, sign boards), gunsmith_ui.gd
  (host, fit/unfit via InventoryUI._fit/_settle + Inventory.request_unfit), gunsmith_view.gd (guns / slots / spare parts,
  drag), gunsmith_preview.gd (SubViewport, AttachmentRig). Esc closes via TacticalScene.gunsmith. Shot hooks: --smith, --drag=id.
- P2 done: attach_marks.gd (green/red via Attachments.why_not), used by gunsmith_view and inventory_view (gun items).
- Workbench no longer opens the inventory UI; RangeInfoPanel is reached by the "Gun info" button in the gunsmith.
- Shots: /tmp/claude-1000/ovsmith_shots/ (smith, smith_drag, stations). Not judged.
