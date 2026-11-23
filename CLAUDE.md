# AGENTS.md

## Core Behavior

- Think before coding
- Read existing files before editing
- Never assume APIs/functions exist
- Ask for clarification if ambiguous
- Keep edits minimal and surgical
- Do not refactor unrelated code
- Preserve existing architecture
- Prefer simple solutions first

## Workflow

1. Analyze request
2. Inspect relevant files
3. Plan changes
4. Implement minimally
5. Verify syntax/errors
6. Summarize changes

## Coding Rules

- Avoid unnecessary abstractions
- Avoid duplicate code
- Keep functions focused
- Use existing utilities before creating new ones
- Maintain naming consistency

## Safety Rules

- Never overwrite unrelated logic
- Never delete code unless necessary
- Warn before major structural changes

## Lua Rules

- Keep variables local when possible
- Avoid memory leaks from loops/events
- Use clear naming
- Avoid unnecessary nested logic
- Prefer readable code over compact code

## Critical Project Constraints (Zero FPS Impact & GIF Integrity)

- **NOT EFFECT FPS**:
  - Never add heavy synchronous computations, loops, or disk I/O (`readfile`, `writefile`, `getasset`) inside `RenderStepped`, `Heartbeat`, `Stepped`, or tight animation loops.
  - All file saves/loads for custom configs or emotes must be event-driven (e.g. only on button click or one-time initialization).
  - Clean up unused instances, connections, and textures properly to prevent memory leaks and garbage collector stutter.

- **FZ GIF SPLASH INTRO INTEGRITY**:
  - Never break or bypass `play_splash_intro` in `uisimbl/NVL.lua`.
  - Always preserve pre-cached asset tables (`frame_assets`) and 0.6s input debounce (`os.clock() - intro_start_time < 0.6`) so execute/focus clicks do not accidentally cancel the intro.
  - The splash screen must play all 112 frames smoothly before revealing the main cheat GUI and executing autoloaded configs.

## ⛔ CRITICAL — Anti-Waste Rules (DO NOT VIOLATE)

- **NEVER recreate deleted files**. If a file was deleted by the user, it stays deleted.
- **NEVER create new .lua files** unless the user EXPLICITLY says "create new file".
- **Silent Mode = Config approach** (`Silentmode.cfg`), NOT a separate .lua file. `NVL-Silentmode.lua` is FORBIDDEN.
- **ALWAYS verify workspace state** (`git status`, `ls`) before ANY file creation.
- **ALWAYS ask** when uncertain — 1 question costs less than 35 minutes of wasted work.
- **Read `.agents/rules/constitution.md`** for the full rulebook before starting any task.
## Luau & Clean Architecture Rules (Inherited from Skills)

- **Strict Type Checking**: Luau files should start with `--!strict` and use typed annotations.
- **Memory Management**: Store all `RBXScriptConnection` and explicitly `:Disconnect()` on destroy/cleanup. Clear lookup tables (`table.clear`).
- **No Side-Effects / Immutability**: Avoid mutating state in-place across shared listeners.
- **Zero FPS Impact**:
  - No synchronous disk I/O (`readfile`, `writefile`, `getasset`) in `RenderStepped`, `Heartbeat`, `Stepped`, or animation loops.
- **Server Authoritative**: Always validate client payload on server (types, ranges, cooldowns).
- **Reject Anti-Patterns**:
  - Do NOT use `_G` or `shared`.
  - Use `task.wait()`, `task.spawn()`, `task.delay()` instead of deprecated `wait()`, `spawn()`, `delay()`.
  - Flatten nested callbacks with guard clauses / early returns.

## 🛑 STRICT UI & DESIGN RULES (LEARNED FROM CRITICAL MISTAKES)

1. **PROJECT BRANDING IS SACROSANCT**:
   - Reference images / mockups are ONLY for visual style, layout mechanics, widget ergonomics, and feature flow.
   - **NEVER** rebrand the project, overwrite its name ("Memory"), change its watermark ("NEVERLOSE"), or swap its signature glowing Crown Logo based on arbitrary text/logos in a reference image.

2. **COMPREHENSIVE TABS & TOPBAR SUB-TABS**:
   - When the user asks for tabs based on a reference image, replicate the FULL category and tab hierarchy (e.g. `AIMBOT` -> `General`, `Aimbot`, `Others`; `VISUALS` -> `Players`, `World`, `View`; `MISCELLANEOUS` -> `Movement`, `Exploits`, `Config`).
   - Implement functional TopBar Sub-Tabs (`Thread`, `Enemy`, `Other`, `Team`) with interactive pill buttons and instant card filtering.

3. **REALISTIC, DYNAMIC SPECTATORS LIST**:
   - A Spectator list must NEVER be a flat list of plain hardcoded text names.
   - It MUST track real in-game players via `game:GetService("Players")`, render circular avatar thumbnails (`rbxthumb://type=AvatarHeadShot&id=...`), DisplayName, `@Username`, and live spectate mode tags (`[1st Person]`, `[3rd Person]`, `[Watching]`), with empty state ("No spectators") when idle.

4. **GEAR BUTTON SUB-SETTINGS (NO 'X' BUTTON)**:
   - The sub-settings popout modal must be toggled (opened and closed) by clicking the gear icon (⚙) itself (or clicking outside).
   - **DO NOT** add an 'X' close button to the sub-settings header.

5. **DYNAMIC GAME / PLACE NAME UNDER LOGO**:
   - Never show generic or meaningless text like "Roblox" under the "Memory" logo.
   - Dynamically fetch and display the real game/place name via `MarketplaceService:GetProductInfo(game.PlaceId).Name` (fallback to `game.Name`).

6. **ZERO TAB OVERLAP ANIMATIONS**:
   - Never allow two tab canvases to be visible at the same time during transitions.
   - The old canvas MUST be hidden (`Visible = false`) before or simultaneously with the new canvas smoothly sliding/fading in, preventing any visual clashing or text bleeding.
