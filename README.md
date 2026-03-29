# Recall

[![Status](https://img.shields.io/badge/status-early_development-orange?style=flat-square)](#)

> A first-person 3D memory palace builder — walk through your knowledge, watch neglected rooms decay.

Recall implements the method of loci in Godot 4.6. Build a palace of connected rooms, place memory objects in them, then walk through and review. Rooms you neglect visually deteriorate through shader-driven decay; rooms you review stay vibrant.

## Planned Features

- First-person exploration with WASD movement and head bob
- Five room templates (Study, Gallery, Workshop, Garden, Vault) with different slot counts
- Grid-based palace layout with auto-generated hallways between adjacent rooms
- SM-2 spaced repetition tracking per memory object
- 5-tier visual decay driven by custom GLSL shaders
- In-world review panels — approach a pedestal, press E to create or review
- Fast travel via minimap click
- Offline, no accounts — all data saved locally as JSON

## License

MIT