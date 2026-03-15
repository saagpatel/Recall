# Recall — Gamified Memory Palace Builder

## Project Overview
Recall is a first-person 3D memory palace builder in Godot 4.4 (GDScript strict mode). Players select pre-built room templates, place them in a connected palace via a 2D minimap grid, and populate pedestal slots with memory objects (typed term + definition pairs). Spaced repetition (SM-2) governs decay: unrehearsed rooms visually deteriorate through shader-driven desaturation, fog, cracks, and darkness, while reviewed rooms stay bright and vibrant. The player walks through in first-person, interacts with objects to review, and maintains their palace against entropy. Zero combat, zero enemies. Desktop-only, single-player, fully offline.

## Tech Stack
- Godot 4.4 stable (verify latest stable before starting)
- GDScript strict mode (all scripts use `class_name`, typed variables, typed function signatures)
- No C#, no GDExtensions, no third-party addons
- JSON for save data (`user://recall_save_a.json`, `user://recall_save_b.json`)
- Custom `.gdshader` files for decay visuals
- Godot built-in NavigationServer3D, AudioStreamPlayer3D
- Target: macOS (primary), Windows, Linux

## Architecture
```
[Player (CharacterBody3D)]
    ├── Camera3D + RayCast3D (interaction detection, 3m range)
    ├── InteractionManager.gd (E-key routing)
    └── HUD (CanvasLayer: crosshair, minimap, due counter, room name)

[Palace (Node3D)]
    ├── Atrium (always loaded, hub room)
    ├── Room instances (Study/Gallery/Workshop/Garden/Vault templates)
    │   └── Pedestal slots → MemoryObject (procedural mesh + Label3D + decay shader)
    └── Hallway connectors (auto-generated between adjacent rooms)

[Autoloads]
    ├── SRSEngine      — Pure data: SM-2 algorithm, intervals, decay calculation
    ├── DecayManager    — Reads SRSEngine, updates shaders/lights/fog/audio per room
    ├── SaveManager     — JSON serialize/deserialize, alternating autosave
    └── PalaceManager   — Grid-based room placement, instancing, hallway connections
```

## Folder Structure
```
res://
├── scenes/
│   ├── main.tscn                 # Root scene
│   ├── player/
│   │   ├── player.tscn
│   │   └── player.gd
│   ├── rooms/
│   │   ├── study.tscn
│   │   ├── gallery.tscn
│   │   ├── workshop.tscn
│   │   ├── garden.tscn
│   │   ├── vault.tscn
│   │   └── atrium.tscn
│   ├── hallway/
│   │   └── hallway.tscn
│   ├── objects/
│   │   ├── memory_object.tscn
│   │   └── memory_object.gd
│   └── ui/
│       ├── creation_panel.tscn   # SubViewport UI for creating memories
│       ├── review_panel.tscn     # SubViewport UI for reviewing
│       ├── minimap.tscn
│       ├── settings_menu.tscn
│       └── hud.tscn
├── scripts/
│   ├── autoloads/
│   │   ├── srs_engine.gd
│   │   ├── decay_manager.gd
│   │   ├── save_manager.gd
│   │   └── palace_manager.gd
│   └── interaction/
│       └── interaction_manager.gd
├── shaders/
│   ├── room_decay.gdshader
│   └── object_decay.gdshader
├── audio/
│   ├── ambient/
│   ├── footsteps/
│   ├── ui/
│   └── restoration/
├── resources/
│   └── textures/
│       ├── crack_overlay.png
│       └── noise.png
└── test/
    └── test_srs.gd
```

## Development Conventions
- **Strict mode everywhere:** Every `.gd` file starts with `class_name ClassName`. All variables typed. All function params and returns typed.
- **Signal naming:** Past tense verb: `object_reviewed`, `room_placed`, `panel_closed`
- **Node naming:** PascalCase for scene nodes (`MemoryObject`, `CreationPanel`). snake_case for script files (`memory_object.gd`).
- **No magic numbers:** Constants at top of file or in a `constants.gd` autoload.
- **Git:** Commit after each task completion. Branch per phase (`phase-0-foundation`, `phase-1-objects`, etc.). Main branch always runnable.
- **Comments:** Document WHY, not WHAT. Skip obvious comments. Document shader uniforms and their expected ranges.

## Current Phase
**Phase 0: Foundation** — COMPLETE
- [x] Project scaffold with folder structure
- [x] Player scene: CharacterBody3D, Camera3D, WASD + mouse look, walk/sprint, head bob
- [x] Test room: 6m×6m×3m CSGBox3D, OmniLight3D, one pedestal
- [x] Autoload stubs: SRSEngine, DecayManager, SaveManager, PalaceManager
- [x] RayCast3D + InteractionManager detecting pedestal collision

**Phase 1: First Object + Review** — COMPLETE
*Session 2: SRS Engine + SubViewport UI*
- [x] SRSEngine: SM-2 algorithm with create_object(), review(), get_decay(), get_due_objects()
- [x] Unit test scene (test/test_srs.tscn): 10 tests covering SM-2 logic — run to verify
- [x] SubViewport panel prototype: tested — SubViewport text input had focus issues (push_input keyboard events not routed to TextEdit). Switched to CanvasLayer fallback per spec.
- [x] CanvasLayer panel prototype: screen-space 512×384 panel, text input works, Esc closes
- [x] InteractionManager: E-key opens panel at pedestal, Esc closes, player input disabled while panel open

*Session 3: Procedural Objects + Interaction Polish*
- [x] memory_object.tscn: procedural mesh (5 shapes) + Label3D with distance-based opacity fade
- [x] creation_panel.tscn: CanvasLayer UI for creating memories (front/back/category/color)
- [x] review_panel.tscn: CanvasLayer UI for reviewing (front → reveal → grade, keyboard shortcuts 1/2)
- [x] Full interaction flow: E on empty pedestal → create, E on populated → review
- [x] Label3D: billboard (FIXED_Y), distance-based opacity fade (3m–8m)
- [x] Crosshair: dot default, ring on interactable (custom _draw() arc)

**Phase 2: Decay Shaders + Restoration** — COMPLETE
*Session 4: Visual Decay System*
- [x] room_decay.gdshader: spatial shader with desaturation, crack overlay, emission dimming
- [x] object_decay.gdshader: vertex warp, desaturation, dissolve edges, alpha dissolve, pulsing emission
- [x] crack_overlay.png: procedural crack texture (256x256)
- [x] DecayManager: full rewrite — timer-based shader/light/fog updates, room/object registration
- [x] Restoration animation: tween decay→0 over 2.5s + gold GPUParticles3D burst
- [x] SRSEngine: virtual time offset (get_time(), advance_debug_time()) for T accelerator
- [x] memory_object.gd: removed StandardMaterial3D, DecayManager applies ShaderMaterial
- [x] interaction_manager.gd: registers objects with DecayManager, multi-pedestal support
- [x] player.gd: T debug time toggle, HUD "TIME ACCEL" label
- [x] test_room.tscn: 4 pedestals (was 1), FogVolume via DecayManager
- [x] main.tscn: volumetric fog enabled, main.gd registers rooms with DecayManager
- [x] project.godot: debug_time input action (T)

## Key Decisions Made
| Decision | Choice | Rationale |
|----------|--------|-----------|
| Room building model | Pre-built templates with pedestal slots | Room editor is scope creep. Templates prove the core loop. |
| Room placement | Grid-based 2D minimap | Free-form 3D placement is a UX nightmare. Grid is simple. |
| Hallway generation | Pre-built straight connectors, fixed length | Procedural hallways with turns = scope creep. |
| Object visuals | Abstract geometric (5 base meshes + category color) | No asset pipeline needed. Procedural and cohesive. |
| Object labels | Label3D with distance-based opacity fade | Simpler than per-object SubViewport. Billboard mode. |
| Review UI | CanvasLayer HUD (SubViewport tested, failed — text input focus broken) | SubViewport push_input() doesn't route keyboard to TextEdit. CanvasLayer is reliable. |
| Decay timing | Perceptual (proportional to interval progress) | Always shows meaningful decay, even for long-interval items. |
| Audio | Godot built-in AudioStreamPlayer3D | No middleware. Sufficient for ambient + footsteps + UI. |
| Fast travel | Minimap click → 0.5s fade → teleport | No pathfinding cutscene. Instant with brief transition. |
| Save format | JSON (alternating files for corruption protection) | Human-readable, debuggable, portable. |
| SRS algorithm | Simplified SM-2 | Battle-tested, simple to implement. Visual decay papers over scheduling imprecision. |
| Time acceleration | Virtual offset in SRSEngine, not Engine.time_scale | System time unaffected by time_scale. Offset is simpler and controllable. |
| Room shader on CSG | ShaderMaterial per CSGBox3D surface | CSGBox3D supports material property. Each surface gets own instance sharing decay_amount. |
| Noise texture | Programmatic NoiseTexture2D (FastNoiseLite) | No external asset needed. Godot generates at runtime. |
| Object material swap | DecayManager replaces StandardMaterial3D with ShaderMaterial | Centralizes all shader management in one place. |
| Restoration feedback | Tween + GPUParticles3D burst (gold, 30 particles) | Satisfying visual payoff. Particles auto-cleanup after lifetime. |
| Pedestal naming | begins_with("Pedestal") check | Supports multiple pedestals per room (Pedestal, Pedestal2, etc.). |

## Do NOT
- Do NOT build a room editor or level editor. Templates only.
- Do NOT add import/export (Anki, CSV). Manual text entry only for MVP.
- Do NOT add networking, multiplayer, or any online features.
- Do NOT add jumping. There's nothing to jump over and it complicates collision.
- Do NOT use C#, GDExtensions, or third-party addons.
- Do NOT store multiple save slots. Single palace, single save.
- Do NOT optimize prematurely. Profile first, optimize in Phase 4 only.
- Do NOT create more than 5 room templates for MVP.
- Do NOT add image/audio attachments to memory objects.
- Do NOT use CanvasLayer for review/creation panels unless SubViewport approach fails (try SubViewport first).
