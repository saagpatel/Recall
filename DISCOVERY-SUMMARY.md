# Recall — Discovery Summary

## Problem Statement
Traditional flashcard apps (Anki, Quizlet) are effective for spaced repetition but tedious to use. The memory palace technique — associating knowledge with spatial locations in an imagined building — is well-validated in cognitive science but requires significant mental effort to construct and maintain purely in imagination. There is no tool that combines spatial memory palaces with spaced repetition in an interactive, visual format that makes study review feel like exploration rather than homework.

## Target User
Students, language learners, certification studiers, and knowledge workers who already use flashcard systems but find them disengaging. They value aesthetics and spatial thinking. They would engage more with a beautiful 3D environment than a 2D card interface. Secondary audience: anyone curious about the memory palace technique who wants a guided, visual way to practice it.

## Success Metrics
1. Create a memory object (type front + back, place on pedestal) in < 30 seconds
2. Review an object (approach, reveal, grade) in < 10 seconds
3. Decay visual difference between 0% and 100% is immediately obvious from 5m+ away without inspecting individual objects
4. Full palace (20 rooms, 200 objects) loads in < 3 seconds on M4 Pro
5. Save file round-trips perfectly: save → quit → load → all positions, SRS state, and decay values identical

## Scope Boundaries

**In scope (MVP v1.0):**
- First-person controller (WASD + mouse, walk/sprint, head bob, no jump)
- 5 pre-built room templates: Study (8 slots), Gallery (12), Workshop (10), Garden (6), Vault (16)
- Grid-based palace layout via 2D minimap, max 20 rooms
- Manual text entry for memory objects (front/back/category), max 320 objects
- SM-2 spaced repetition algorithm per object
- 5-tier visual decay system (desaturation, fog, cracks, lighting, audio) via custom shaders
- Restoration animation on successful review (2.5s, golden particle burst, chime)
- In-world 3D review/creation panels (SubViewport on mesh)
- Procedural abstract geometric objects (5 base meshes × category color)
- Label3D with distance-based opacity
- Hallway connectors (straight, fixed-length, auto-generated)
- Save/load to JSON (alternating autosave)
- Fast travel via minimap click-to-teleport
- Settings menu (sensitivity, FOV, head bob, invert-Y, volume)
- HUD (crosshair, due counter, room name, minimap toggle)

**Out of scope (deferred to post-MVP):**
- Room editor / modular room building
- Anki/CSV import/export
- Image or audio on memory objects
- Multiple palaces / save slots
- Statistics dashboard / retention graphs
- Procedural room generation
- Multiplayer / palace sharing
- AI-generated object suggestions
- Mobile or web port
- Guided review mode with waypoint markers

**Deferred design questions:**
- Object visual language: pure abstract vs. thematic hints (book shape for vocab, gear for engineering)
- Hallway customization: functional connectors vs. display spaces with banners/signs
- Decay speed for very long intervals (180+ days): literal vs. perceptual
- Review mode toggle for dense study sessions
- Accessibility mode for fog-heavy decay states (colorblind/low-vision alternatives)

## Technical Constraints
- Godot 4.4, GDScript strict mode only (no C#, no GDExtensions, no addons)
- Fully offline, zero network calls
- Desktop-only: macOS (primary), Windows, Linux
- Single save slot, JSON format
- Performance target: 60 FPS with 20 rooms (3 loaded simultaneously), 200 objects, decay shaders active
- Custom spatial shaders for decay (room_decay.gdshader, object_decay.gdshader)
- CSGBox3D for room prototyping (replace with imported meshes later if needed)
- Max 320 objects (20 rooms × 16 max slots per room)

## Key Integrations
None. This project is fully offline with no external API dependencies.

| Service | API | Auth | Rate Limits | Purpose |
|---------|-----|------|-------------|---------|
| N/A | — | — | — | Fully offline application |

## Data Model
Palace data serialized as JSON to `user://recall_save_a.json` (alternating with `_b.json` for corruption protection). Settings stored separately in `user://recall_settings.json`.

Core entities: PalaceData → RoomData[] → MemoryObjectData[] → SRSData. Layout stored as grid positions + connection pairs. No relational database — flat JSON with nested objects.

## Design Pillars
1. **Exploration First** — Walking through the palace must feel good moment-to-moment
2. **Visible Knowledge State** — The palace's visual state IS your study state. No menus needed.
3. **Gentle Motivation** — Decay nudges, never punishes. All progress is recoverable.
4. **Zero Friction Entry** — Creating a memory should take < 30 seconds. Lower overhead than Anki.
