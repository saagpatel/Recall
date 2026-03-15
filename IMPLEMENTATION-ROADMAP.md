# Recall — Implementation Roadmap

## Session Strategy
8 Claude Code sessions mapped to 4 phases. Each session is ~3–4 hours of focused work. Sessions are designed to produce a playable build at the end of each phase. M3 (end of Session 4) is the critical validation gate — if the decay/restoration loop doesn't feel compelling, pause and iterate before investing in Phase 3+.

Total estimated build time: 6–8 weeks at 10–15 hrs/week.

---

## Phase 0: Foundation (Week 1)

### Session 1: Project Scaffold + FPS Controller (~3 hours)
**Scope:**
1. Create Godot 4.4 project with full folder structure (see CLAUDE.md)
2. Configure GDScript strict mode in project settings
3. Build Player scene: CharacterBody3D → Camera3D → RayCast3D
   - WASD movement: 4.0 m/s walk, 6.5 m/s sprint (Shift)
   - Mouse look: sensitivity 0.002, invert-Y support
   - Head bob: sinusoidal Y-axis, amplitude 0.03m, frequency matched to step speed, toggleable
   - No jump. Gravity + floor snapping.
4. Build test room: 6m×6m×3m using CSGBox3D for walls/floor/ceiling
   - OmniLight3D (warm, 4500K)
   - One StaticBody3D pedestal (CylinderMesh, 0.5m radius, 1m height)
5. Create autoload stubs: `srs_engine.gd`, `decay_manager.gd`, `save_manager.gd`, `palace_manager.gd`
   - Register all 4 in Project Settings → Autoload
   - Each prints initialization confirmation in `_ready()`
6. Wire RayCast3D (3m forward from camera) + InteractionManager.gd
   - `_physics_process()`: check `raycast.is_colliding()`, print collider name

**Deliverables:**
- Runnable project with smooth FPS movement in a lit room
- RayCast detects pedestal on approach

**Verification:**
- Walk speed feels appropriate (not too fast, not sluggish)
- Mouse look is responsive with no drift
- Head bob is subtle (disable and compare — it should enhance, not nauseate)
- Can't walk through walls
- Console prints pedestal name on approach

**Context files for this session:**
- CLAUDE.md (full)
- This section of IMPLEMENTATION-ROADMAP.md

---

## Phase 1: First Object + Review (Weeks 2–3)

### Session 2: SRS Engine + SubViewport UI (~3 hours)
**Scope:**
1. Implement `srs_engine.gd` fully:
   - Data: Dictionary[String, MemoryObjectData] keyed by object ID
   - `create_object(id: String, front: String, back: String, category: String) → Dictionary`
   - `review(id: String, remembered: bool) → void`
   - `get_decay(id: String) → float` (returns 0.0–1.0)
   - `get_due_objects() → Array[String]`
   - SM-2 logic: correct → interval progression (1d → 6d → interval × ease). Incorrect → reset to 1d, ease -= 0.2 (min 1.3)
2. Build SRS unit test scene (`res://test/test_srs.tscn`):
   - Create 10 objects programmatically
   - Review with known inputs (mix of remembered/forgot)
   - Assert expected intervals and decay values
   - Print PASS/FAIL to console
3. Build SubViewport-based 3D panel prototype:
   - SubViewport (512×384) with Control scene: VBoxContainer → Label + TextEdit + Button
   - Render via ViewportTexture on QuadMesh (MeshInstance3D)
   - Position 0.5m above pedestal, billboard mode
   - Test keyboard capture: can type in TextEdit while panel is open
   - Test readability at 1m, 1.5m, 2m distances

**Deliverables:**
- SRSEngine autoload with working SM-2 and passing unit tests
- Visible 3D panel that captures text input

**Verification:**
- Unit test prints all PASS
- Panel text is readable at interaction range (1.5m)
- Keyboard input goes to panel, not player movement, when panel is open

**Context files:**
- CLAUDE.md
- `player.gd` (from Session 1)
- `srs_engine.gd` (building in this session)
- This section of IMPLEMENTATION-ROADMAP.md

### Session 3: Procedural Objects + Interaction Polish (~3 hours)
**Scope:**
1. Build `memory_object.tscn` scene:
   - Node3D root → MeshInstance3D (procedural shape) + Label3D (front text)
   - Mesh selection: `hash(front_text) % 5` maps to [SphereMesh, BoxMesh, PrismMesh, TorusMesh, CylinderMesh]
   - StandardMaterial3D: albedo_color from category color, emission_enabled with energy 0.3
2. Build `creation_panel.tscn`:
   - SubViewport UI: Front (TextEdit, max 100 chars), Back (TextEdit, max 500 chars), Category (LineEdit, max 30 chars), Category Color (preset color buttons), Create (Button), Cancel (Button)
   - On Create: call `SRSEngine.create_object()`, instance `memory_object.tscn` at pedestal position, close panel
3. Build `review_panel.tscn`:
   - SubViewport UI: Front label (large text), "Reveal" button / E key, Back label (hidden until reveal), "Remembered" (1 key / green button), "Forgot" (2 key / red button)
   - On grade: call `SRSEngine.review()`, close panel
4. Wire full interaction flow in InteractionManager:
   - E on empty pedestal → open creation panel
   - E on populated pedestal → open review panel
   - Mouse look disabled while panel open
   - Esc closes any panel
5. Label3D: billboard mode, font size 24, opacity scales with distance (1.0 at <3m, 0.0 at >8m via `_process()`)
6. Crosshair: small dot default, changes to ring when RayCast hits interactable

**Deliverables:**
- Can create memory objects on pedestals via in-world UI
- Can review objects with full front→reveal→grade flow
- Objects are visually distinct by category and term

**Verification:**
- Create 10 objects across 3 categories. Visual variety is apparent.
- Review cycle takes < 10 seconds
- Labels readable at interaction range, invisible from far away
- No input conflicts (movement doesn't happen during panel typing)

**Context files:**
- CLAUDE.md
- `player.gd`, `interaction_manager.gd`, `srs_engine.gd`
- This section of IMPLEMENTATION-ROADMAP.md

---

## Phase 2: Decay System (Weeks 3–4)

### Session 4: Decay Shaders + Restoration (~4 hours — largest session)
**Scope:**
1. Write `room_decay.gdshader`:
   - Uniform: `decay_amount` (float, 0.0–1.0)
   - Uniforms: `base_albedo` (sampler2D), `crack_overlay` (sampler2D), `dust_color` (vec4)
   - Effect: lerp albedo toward desaturated version (gray-blue) by `decay_amount * 0.8`
   - Effect: blend crack_overlay alpha when `decay_amount > 0.3`
   - Effect: reduce emission energy inversely with decay
   - Apply to all room meshes via shared ShaderMaterial
2. Write `object_decay.gdshader`:
   - Same desaturation + crack base as room shader
   - Add dissolve: noise texture threshold mask, pixels below `(1.0 - decay_amount)` become transparent
   - Add vertex displacement: `VERTEX += NORMAL * noise * decay_amount * 0.05`
   - Add emission pulse at low decay: `sin(TIME * 2.0) * 0.2` modulation
3. Implement `decay_manager.gd`:
   - Every 1.0 second (Timer): iterate all loaded rooms
   - Per room: average decay of objects via `SRSEngine.get_decay()`
   - Set room shader `decay_amount` parameter
   - Set OmniLight3D energy: `1.0 - (decay * 0.9)` (min 0.1)
   - Set FogVolume density: `decay * 0.15`
   - Note: per-room FogVolume instances (not global fog)
4. Restoration animation (on successful review):
   - Tween: object `decay_amount` from current → 0.0 over 2.5 seconds
   - GPUParticles3D: 30 particles, gold color (#FFD700), 1.5s lifetime, burst on review
   - Room shader `decay_amount` recalculates (instant, since average changed)
   - AudioStreamPlayer3D: restoration chime, pitch = `0.6 + (pre_decay * 0.6)` (more overdue = lower start pitch sweeping up = more dramatic)
5. Debug time accelerator:
   - F5 toggles time scale between 1× and 100×
   - HUD label shows "TIME ×100" when active
6. Source placeholder textures:
   - `crack_overlay.png`: any CC0 crack texture (will be replaced later)
   - `noise.png`: Godot's built-in NoiseTexture2D exported to PNG, or generate in shader

**Deliverables:**
- Rooms and objects visually decay along a continuous 0–100 spectrum
- Restoration animation plays on successful review with particle + audio feedback
- F5 time acceleration for rapid testing

**Verification:**
- F5 → watch room go from pristine to ruined in ~30 seconds. All 5 states visually distinct.
- Review a heavily decayed object → dramatic restoration with golden particles and chime
- Review a barely-decayed object → subtle confirmation
- 60 FPS with 1 room, 16 objects, all shaders active

**Context files:**
- CLAUDE.md
- `srs_engine.gd`, `decay_manager.gd`, `memory_object.gd`
- `room_decay.gdshader`, `object_decay.gdshader` (creating in this session)
- This section of IMPLEMENTATION-ROADMAP.md

**⚠️ VALIDATION GATE:** After this session, playtest the single-room experience for 15 minutes with real study content. If the decay→restoration loop doesn't feel compelling, STOP and iterate on shader quality / animation timing / audio design before proceeding to Phase 3. Do not build more rooms until this feels right.

---

## Phase 3: Multi-Room Palace (Weeks 5–6)

### Session 5: Palace Manager + Room Templates + Hallways (~4 hours)
**Scope:**
1. Implement `palace_manager.gd`:
   - Grid: Dictionary[Vector2i, String] mapping grid positions to room IDs
   - `place_room(template: String, name: String, grid_pos: Vector2i) → String` (returns room ID)
   - `remove_room(id: String) → void`
   - `get_adjacent_positions(grid_pos: Vector2i) → Array[Vector2i]` (returns empty adjacent cells)
   - `get_room_at(grid_pos: Vector2i) → Dictionary` (room data or null)
   - Atrium always at (0, 0), cannot be removed
   - New rooms only placeable adjacent to existing rooms
2. Build 5 room template scenes:
   - Study (8 pedestals): warm wood tones, desk lamp OmniLights, bookshelves (CSGBox)
   - Gallery (12 pedestals): white walls, SpotLight3D per pedestal, open layout
   - Workshop (10 pedestals): metal shelves (CSGBox), workbench, warm overhead light
   - Garden (6 pedestals): open courtyard feel, stone textures, planters (CSGBox), bright ambient
   - Vault (16 pedestals): metal walls, dim blue OmniLight3D, dense grid layout
   - Each: NavigationRegion3D with baked NavMesh, Area3D doorway triggers on consistent positions (centered on one wall)
3. Build `hallway.tscn`:
   - Straight corridor: 2m wide × 3m tall × 6m long
   - Collision on all surfaces
   - Door Area3D triggers on each end
   - When player enters doorway trigger, signal to load/ensure connected room
4. Wire room instancing: PalaceManager.place_room() → instance the PackedScene → position at grid_pos × room_spacing (e.g., grid_pos × Vector3(12, 0, 12)) → generate hallway between connected rooms

**Deliverables:**
- 5 room templates, each with correct pedestal counts and distinct visual identity
- Rooms instance at grid positions with hallway connectors
- Can walk from atrium through hallway into another room

**Verification:**
- Place all 5 room types via code. Walk through each. Pedestal counts correct.
- Walk from atrium → hallway → room seamlessly. No collision gaps.
- Place 3 rooms in an L-shape. Hallways connect correctly.

**Context files:**
- CLAUDE.md
- `palace_manager.gd` (building), `player.gd`, `decay_manager.gd`
- This section of IMPLEMENTATION-ROADMAP.md

### Session 6: Minimap + Fast Travel + Room Loading (~3 hours)
**Scope:**
1. Build `minimap.tscn` (CanvasLayer):
   - Toggle with M key
   - Top-down grid view of palace layout
   - Room icons (rectangles) colored by average decay (green→yellow→red gradient)
   - Room names displayed on icons
   - Empty adjacent cells show "+" button for room placement
   - Click "+" → template selection dropdown → name TextEdit → confirm button
   - Click existing room → fast travel to that room
2. Fast travel:
   - Click room on minimap → 0.5s AnimationPlayer fade to black → teleport Player to room entrance position → 0.5s fade in
   - Disable fast travel while review/creation panels are open
3. Room loading optimization:
   - Track current room (player is inside) and adjacent rooms (connected via hallways)
   - Only keep current + adjacent rooms instanced in scene tree
   - On room transition: load new adjacent rooms, free rooms that are now 2+ steps away
   - Store freed room state in PalaceManager (pedestal occupancy persists via SRSEngine, only visual instances are freed/re-created)
4. Test with 10 rooms:
   - Place 10 rooms via minimap
   - Fast travel to each
   - Walk between adjacent rooms
   - Profile FPS

**Deliverables:**
- Functional minimap with room placement and fast travel
- Room loading/unloading keeps performance stable at 10+ rooms

**Verification:**
- Place 10 rooms via minimap UI (no code). Layout makes spatial sense.
- Fast travel to any room in < 1.5 seconds. No clipping on arrival.
- Walk through 3 connected rooms. No visible pop-in or loading hitch.
- 60 FPS maintained with 10 rooms placed, 3 loaded, ~80 objects

**Context files:**
- CLAUDE.md
- `palace_manager.gd`, `player.gd`, all room template scenes
- This section of IMPLEMENTATION-ROADMAP.md

---

## Phase 4: Audio + Polish (Weeks 7–8)

### Session 7: Audio + Save/Load + Settings (~3 hours)
**Scope:**
1. Audio implementation:
   - 5 ambient AudioStreamPlayer3D tracks (one per room template mood). Cross-fade on room transition (1.0s linear fade)
   - Footsteps: AudioStreamPlayer3D on Player. 3 surface types (wood, stone, metal) × 4 random variations = 12 samples. Random pitch ±10%, volume ±10%. Trigger on step (time-based, matched to walk speed)
   - UI sounds: panel_open, panel_close, button_hover, button_click, object_materialize (5 samples)
   - Restoration chime: 1 sample, pitch-shifted by pre-review decay
   - Ambient volume scales with decay: full at decay 0, -12dB at decay 100
   - Source all audio from freesound.org (CC0 license)
2. Implement `save_manager.gd`:
   - `save_game() → bool`: serialize PalaceData (all rooms, objects, SRS state, layout) to JSON. Write to `user://recall_save_a.json` (alternating a/b on each save)
   - `load_game() → PalaceData`: read most recent valid save file, validate JSON keys, re-instance rooms, re-create objects, restore SRS state
   - Autosave triggers: on object creation, on review, on room placement, every 300 seconds (Timer)
   - Error handling: if both save files are corrupt, start fresh with Atrium only
3. Settings menu (`settings_menu.tscn`):
   - Esc → pause (get_tree().paused = true) → settings overlay
   - Sliders: mouse sensitivity (0.0005–0.01), FOV (60–90), master volume (0.0–1.0)
   - Toggles: head bob (bool), invert-Y (bool)
   - Save to `user://recall_settings.json` on change
   - Load on startup

**Deliverables:**
- Immersive audio that responds to room state
- Reliable save/load with corruption protection
- Settings menu with persistent preferences

**Verification:**
- Walk between rooms. Ambient cross-fades smoothly. Footsteps match surface.
- Create palace with 3 rooms, 15 objects. Save. Quit. Reload. Verify all data matches.
- Change all settings. Quit. Relaunch. Settings persisted.

**Context files:**
- CLAUDE.md
- `save_manager.gd` (building), `palace_manager.gd`, `srs_engine.gd`
- This section of IMPLEMENTATION-ROADMAP.md

### Session 8: HUD + Performance + Playtest (~3 hours)
**Scope:**
1. HUD finalization (`hud.tscn`):
   - Crosshair: 4px white dot center screen. Changes to 12px ring when RayCast hits interactable.
   - Room name: top-center label, fades in on room entry (0.3s), holds 3 seconds, fades out (0.5s)
   - Due counter: bottom-right, "{N} due" text, updates on review and every 60 seconds
   - Minimap toggle hint: bottom-left, "[M] Map" text, subtle
2. Performance optimization:
   - Run Godot profiler with 20 rooms placed, 200 objects total, 3 rooms loaded
   - Targets: 60 FPS, <100ms frame spikes, <500MB RAM
   - Optimization levers if needed:
     - Shader complexity reduction (remove vertex displacement, simplify noise)
     - LOD: reduce object mesh detail at >10m (lower subdivision or switch to billboard)
     - Reduce fog particle count
     - Reduce audio streams (pool to max 8 simultaneous)
3. Bug fix pass: Walk the full palace. Test every interaction. Verify edge cases:
   - Create object → immediately review it (decay should be 0)
   - Fill all 16 slots in Vault → try to create 17th (should be rejected)
   - Fast travel during creation panel (should be blocked)
   - Save with 0 objects, 0 rooms (beyond atrium). Load.
   - Rapid-fire reviews (review 10 objects in <30 seconds)
4. Real content playtest:
   - Add 50+ vocabulary items across 3 categories ("Spanish Vocab", "Network+", "GDScript")
   - Play for 30 minutes: build rooms, place objects, wait for some decay (use F5 accelerator), review
   - Note any friction, confusion, or missing feedback
   - Document remaining issues in CLAUDE.md

**Deliverables:**
- Polished HUD that provides info without cluttering the view
- 60 FPS performance at full MVP scale
- Bug-free 30-minute playtest session

**Verification:**
- All HUD elements visible, readable, non-overlapping
- Profiler shows consistent 60 FPS at 20-room / 200-object scale
- 30-minute session completes without crashes
- All edge cases handled gracefully

**Context files:**
- CLAUDE.md (update Current Phase to reflect completion)
- `hud.gd`, `player.gd`, `decay_manager.gd`
- This section of IMPLEMENTATION-ROADMAP.md

---

## Context Management

**Per-session rule:** Include CLAUDE.md + the specific session section from this roadmap + max 5 relevant source files. Do NOT dump the entire project into context.

**Key files by session:**

| Session | Must Include | May Include |
|---------|-------------|-------------|
| 1 | CLAUDE.md | — (nothing exists yet) |
| 2 | CLAUDE.md, player.gd | interaction_manager.gd |
| 3 | CLAUDE.md, srs_engine.gd, player.gd | interaction_manager.gd, memory_object.gd |
| 4 | CLAUDE.md, srs_engine.gd, memory_object.gd | decay_manager.gd, room scene file |
| 5 | CLAUDE.md, palace_manager.gd, player.gd | decay_manager.gd |
| 6 | CLAUDE.md, palace_manager.gd | minimap.gd, player.gd |
| 7 | CLAUDE.md, save_manager.gd, srs_engine.gd | palace_manager.gd |
| 8 | CLAUDE.md, hud.gd | player.gd, decay_manager.gd |

**After each session:** Update the `Current Phase` section in CLAUDE.md with completed tasks and next steps. This is the primary recovery mechanism if context is lost.
