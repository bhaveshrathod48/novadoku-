# novadoku development rules

- The [ten-phase development roadmap](docs/MASTER_PROMPT.md) is locked. Keep its order and scope. Never proceed beyond the phase requested by the user.
- The [approved screenshots](docs/reference/novadoku-ui.jpg) are the visual source of truth. Follow their copy, type hierarchy, colors, layout, proportions, component placement, and Nova artwork. Never redesign the application without permission.
- Preserve completed functionality and avoid unrelated features or changes.
- Never introduce fake gameplay, fake controls, or a substitute for the original Nova character.
- Keep puzzle rules and generation independent from presentation, settings, persistence, and effects. Always verify puzzle correctness, including uniqueness, before a puzzle ships.
- Maintain production-quality code. Use compatible dependencies with a demonstrated purpose and keep assets offline-capable and licensed.
- Always run relevant tests after implementation. Distinguish verified results from open work or environment blockers.

Read [game design](docs/GAME_DESIGN.md), [UI specification](docs/UI_SPECIFICATION.md), [engine scope](docs/GAME_ENGINE.md), and [animation specification](docs/ANIMATION_SPEC.md) before working in those areas.
