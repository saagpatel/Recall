![Godot 4.6](https://img.shields.io/badge/Godot-4.6-478CBF?logo=godotengine&logoColor=white)
![GDScript](https://img.shields.io/badge/GDScript-strict_mode-478CBF?logo=godotengine&logoColor=white)
![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Windows%20%7C%20Linux-lightgrey)
![License](https://img.shields.io/badge/license-MIT-green)

# Recall

A first-person 3D memory palace builder that combines the [method of loci](https://en.wikipedia.org/wiki/Method_of_loci) with spaced repetition. Build a palace of connected rooms, populate them with memory objects (term/definition pairs), then walk through and review — unrehearsed rooms visually deteriorate through shader-driven decay while reviewed rooms stay vibrant.

> No combat. No enemies. Just a palace that reflects the state of your memory.

---

## Screenshot

![Recall screenshot placeholder](docs/screenshot.png)

*Screenshot placeholder — replace with an in-game capture before publishing.*

---

## Features

- **First-person exploration** — WASD movement, mouse look, walk/sprint, head bob
- **Five room templates** — Study (8 slots), Gallery (12), Workshop (10), Garden (6), Vault (16)
- **Grid-based palace layout** — Place up to 20 rooms on a 2D minimap grid; hallways auto-generate between adjacent rooms
- **SM-2 spaced repetition** — Each memory object tracks its own review interval and ease factor
- **5-tier visual decay** — Desaturation, fog, crack overlays, lighting changes, and audio shifts driven by custom GLSL shaders as review intervals lapse
- **Restoration animation** — Successful review triggers a 2.5s tween back to full brightness plus a gold particle burst
- **In-world review panels** — Approach a pedestal, press E to create or review; keyboard shortcuts grade responses
- **Fast travel** — Click any room on the minimap for an instant fade-teleport
- **Offline, no accounts** — Zero network calls; all data saved locally as JSON

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Engine | Godot 4.6 (GDScript strict mode) |
| Scripting | GDScript only — no C#, no GDExtensions, no addons |
| Shaders | Custom `.gdshader` spatial shaders |
| Persistence | JSON (`user://recall_save_a.json` / `_b.json`, alternating for corruption protection) |
| Audio | Godot built-in `AudioStreamPlayer3D` |

## Prerequisites

- **Godot 4.6 stable** — download from [godotengine.org](https://godotengine.org/download)
- No additional dependencies, plugins, or build tools required

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/saagpatel/Recall.git
   cd Recall
   ```

2. Open Godot, click **Import**, and select the `project.godot` file in this directory.

3. Press **F5** (or the Play button) to run from `scenes/main.tscn`.

### Controls

| Key | Action |
|-----|--------|
| W / A / S / D | Move |
| Mouse | Look |
| Shift | Sprint |
| E | Interact with pedestal |
| 1 / 2 | Grade a review (Again / Good) |
| T | Toggle debug time acceleration |
| Esc | Close panel |

## Project Structure

```
res://
├── scenes/
│   ├── main.tscn               # Root scene
│   ├── player/                 # CharacterBody3D, Camera3D, interaction raycast
│   ├── rooms/                  # study, gallery, workshop, garden, vault, atrium
│   ├── hallway/                # Straight connector template
│   ├── objects/                # memory_object.tscn — procedural mesh + Label3D
│   └── ui/                     # HUD, minimap, creation panel, review panel, settings
├── scripts/
│   ├── autoloads/
│   │   ├── srs_engine.gd       # SM-2 algorithm — intervals, decay calculation
│   │   ├── decay_manager.gd    # Shader/light/fog updates per room and object
│   │   ├── save_manager.gd     # JSON serialize/deserialize, alternating autosave
│   │   └── palace_manager.gd   # Grid-based room placement and hallway connections
│   └── interaction/
│       └── interaction_manager.gd
├── shaders/
│   ├── room_decay.gdshader     # Desaturation, cracks, emission dimming
│   └── object_decay.gdshader  # Vertex warp, dissolve edges, pulsing emission
├── resources/
│   └── textures/               # Crack overlay and noise textures
└── test/
    └── test_srs.gd             # SM-2 unit tests
```

## License

MIT — see [LICENSE](LICENSE) for details.
