# Graph Game — Architecture Document

## Engine & Platform
- **Godot 4.7**, GL Compatibility renderer (required for web export).
- Target: mobile browser, landscape orientation.
- Export: GitHub Pages via `gh-pages` branch.

---

## Project Structure

```
graph-game/
├── project.godot
├── export_presets.cfg
├── root.tscn              # main scene (entry point)
├── scenes/
│   ├── Node.tscn          # game node prefab (circle + icon + inventory)
│   ├── Edge.tscn          # directed edge prefab (arrow line)
│   ├── ContextMenu.tscn   # floating button row above a node
│   ├── NodeMenu.tscn      # bottom collapsible panel
│   ├── TimeControls.tscn  # right collapsible panel
│   └── ResourcePicker.tscn # edge resource type picker
├── scripts/
│   ├── game_state.gd      # singleton: node/edge data, tick logic
│   ├── node_view.gd       # script for Node.tscn
│   ├── edge_view.gd       # script for Edge.tscn
│   ├── context_menu.gd
│   ├── node_menu.gd
│   ├── time_controls.gd
│   └── resource_picker.gd
├── assets/
│   └── icons/             # emoji PNGs (transparent background)
│       ├── labor.png
│       └── fish.png
```

---

## Key Technical Decisions

### Scene Hierarchy (root.tscn)
```
Control (root)
├── GameWorld (Node2D + Camera2D) — map area, nodes/edges live here
├── ContextMenuLayer (CanvasLayer) — floats above the world
├── UILayer (CanvasLayer)
│   ├── NodeMenu (bottom panel)
│   └── TimeControls (right panel)
└── ResourcePicker (modal overlay, hidden by default)
```

### Game State Singleton (`game_state.gd`)
- Autoloaded as `GameState`.
- Owns the canonical list of nodes and edges (data only, no visuals).
- Runs the tick timer; emits `tick` signal each game hour.
- Node/edge views listen to `tick` and update visuals.

### Node Placement (drag from menu)
- `NodeMenu` instantiates a ghost `Node.tscn` on drag start.
- On drag release over `GameWorld`, a real node is added to `GameState` and a view is spawned.

### Edge Drawing
- `Edge.tscn` uses a `Line2D` + `Polygon2D` arrowhead.
- Redrawn each frame by reading source/target node positions from `GameState`.

### Icons
- Emoji rendered to PNG at ~64×64 on transparent background (done once, stored in `assets/icons/`).
- Displayed via `TextureRect` inside node and inventory views.

### Inventory Display
- A horizontal `HBoxContainer` below each node circle.
- Each slot: `TextureRect` (icon) + `Label` (count).

### Collapsible Panels
- Animated via `Tween` on panel size/position.
- Toggle button always visible at panel edge.

---

## Build & Deploy
- Export: `Godot_v4.7-stable_linux.x86_64 --headless --export-release "Web" ...`
- Deploy: force-push build output to `gh-pages` branch.
- COOP/COEP headers required — delivered via `_headers` file in build root.
