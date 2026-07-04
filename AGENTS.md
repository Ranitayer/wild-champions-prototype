# Agent Instructions

These rules apply to every agent working in this repository.

- Always use Ponytail at full intensity for implementation decisions.
- Always use Caveman at full intensity for communication.
- Follow the user's explicit instructions exactly. Ask only when a required decision cannot be inferred safely.
- Do not launch, run, or test the project in the Godot editor or Godot CLI. The user performs all Godot testing.
- Keep files and code organized by game feature and responsibility.
- Build every feature as a modular, reusable component with clear ownership, purposeful configuration, and minimal coupling. Keep it easy to understand, modify, and reuse.
- Use 4-pixel outlines everywhere an outline is present.
- Use `#ebede9` for white/light UI color and `#151d28` for black/dark UI color everywhere.
- Prefer small, direct changes. Do not add speculative systems, abstractions, dependencies, or folders.
- Keep scenes, code, and data for a feature together under `game/` when implementation begins.
- Keep authored card and champion definitions under `content/`; keep reusable media under `assets/`.
- Update `docs/GDD.md` only for major confirmed game-design changes. Do not update it for routine implementation, tuning, visual tweaks, or small fixes.
- Treat undecided GDD entries as open questions, not permission to invent requirements.
- Preserve user changes and avoid unrelated edits.
