---
title: wiki conventions
last-updated: 2026-06-30
---

# code wiki conventions

These conventions apply to agent-maintained maintenance topics in `.code-wiki/`. The public player, mission-maker, Zeus, server-admin, Reference, Developer, Systems, and Examples pages remain in `wiki/` and keep their own documentation style.

## purpose

Use code-wiki topics for knowledge that is hard to recover from code alone:

- Why a subsystem is shaped the way it is.
- Cross-component data flow.
- Multiplayer/locality gotchas.
- Public API contracts and compatibility risks.
- Known fragile behavior that future edits must preserve.

Do not duplicate plain code listings. Link to files and summarize the behavior that matters.

## topic frontmatter

Use this frontmatter for maintenance topics:

```markdown
---
title: short topic title
last-updated: YYYY-MM-DD
status: draft | verified | stale
code-paths:
  - addons/component/functions/
  - addons/component/CfgVehicles.hpp
related-docs:
  - wiki/Reference/Some-API.md
---
```

Field meanings:

| Field | Meaning |
| --- | --- |
| `title` | Human-readable topic title. |
| `last-updated` | Last date an agent or maintainer checked the topic against code. |
| `status` | `draft` for inferred notes, `verified` after human/code review, `stale` when code changed and the topic needs re-checking. |
| `code-paths` | Code paths that should trigger re-verification. |
| `related-docs` | Existing user-facing or reference docs connected to the topic. |

## topic body

Use this structure unless the topic clearly needs something else:

```markdown
# Topic Title

## current behavior

What the code does today.

## rationale

Why the behavior appears to exist. Mark inferred rationale clearly.

## gotchas

Things future edits can break.

## re-verify when

Code paths, configs, or public docs that should trigger a check.

## sources

- [file.sqf](/absolute/path/file.sqf:12)
```

## trigger paths

Re-verify topics when changes overlap these Arma mod paths:

| Area | Trigger paths |
| --- | --- |
| Component behavior | `addons/<component>/functions/`, `addons/<component>/XEH_PREP.hpp`, `addons/<component>/XEH_preInit.sqf`, `addons/<component>/XEH_postInit.sqf` |
| Config behavior | `addons/<component>/config.cpp`, `addons/<component>/Cfg*.hpp` |
| Eden/Zeus behavior | `addons/main/Cfg3DEN.hpp`, `addons/*/CfgVehicles.hpp`, `addons/*/functions/fnc_module_*.sqf`, `addons/*/functions/fnc_zeus_*.sqf` |
| GUI/Desktop behavior | `addons/desktop/`, `addons/desktop/ui/`, `addons/desktop/functions/` |
| Terminal/TUI behavior | `addons/armaos/`, `addons/armaos/functions/fnc_os_*.sqf`, `addons/armaos/CfgOsFunctions.hpp` |
| Filesystem/flash drives | `addons/filesystem/`, `addons/flashdrive/` |
| Network/power | `addons/network/`, `addons/power/` |
| Public documentation | `README.md`, `README_steam.md`, `wiki/` |

Ignore generated or read-only folders unless the user explicitly asks otherwise.

## writing rules

- Write in plain technical prose.
- State what is known from code.
- Mark inferred rationale with `Inferred:`.
- Do not invent history, issue references, or intent.
- Keep examples short and runnable when they are script examples.
- Link to existing Reference or Developer docs instead of duplicating long API material.
- Update [log.md](log.md) when creating, updating, verifying, archiving, or linting maintenance topics.

## freshness

A topic is stale when:

- Any `code-paths` entry changed.
- A public API or config class it describes changed.
- The related public docs changed in a way that conflicts with the topic.
- A validation run exposes behavior that contradicts the topic.

When re-verifying, read the code first, update the topic, set `last-updated`, and add a log entry.
