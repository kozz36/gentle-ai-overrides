# gentle-ai overrides overlay

`gentle-ai` (2.1.0) embeds every prompt asset inside its Go binary and **regenerates
the host agent-config files from those templates on every `sync`, `upgrade` and
`install`**. Any hand-made customization in those files is wiped.

This overlay stores those customizations outside gentle-ai's reach and re-applies
them on demand.

```
after every `gentle-ai sync|upgrade|install`  ->  run  ~/gentle-ai-overrides/apply.sh
```

`apply.sh` **never** invokes `gentle-ai` itself, and it never touches
`~/.gentle-ai/state.json`.

## Usage

```sh
~/gentle-ai-overrides/apply.sh          # apply the overlay (idempotent)
~/gentle-ai-overrides/apply.sh --check  # report only, write nothing
```

Exit codes:

| Code | Meaning |
| --- | --- |
| `0` | Overlay applied, or already applied (no-op). |
| `1` | An anchor was not found: gentle-ai changed its template. **The overlay needs review** before it can be trusted again. |
| `2` | `--check` only: work is pending. |

Every file is copied to `backups/<timestamp>/<path-relative-to-$HOME>` before the
first write of a run. A run that changes nothing creates no backup directory.

## What is in the overlay

### 1. `persona/persona-block.md` — the customized persona

Single source of truth for the persona. Contains the nine sections gentle-ai
renders into every "old-shape" host (`## Rules`, `## Personality`,
`## Persona Scope`, `## Language`, `## Tone`, `## Philosophy`, `## Expertise`,
`## Behavior`, `## Contextual Skill Loading`), with these customizations relative
to the stock `neutral` persona:

- **Rules** — adds the `pkexec` rule for privileged commands in non-interactive
  sessions; rewrites the response-length contract (name the concept/pattern so it
  can be researched independently); replaces the one-question-at-a-time rule with
  "ask directly, or proceed on a stated assumption"; allows option menus when there
  is a real fork; drops "if unsure, choose the shorter response"; adds the
  per-layer architectural-decision rule for complex refactors.
- **Personality / Philosophy / Persona Scope** — demanding but strictly
  professional and non-condescending; no "frustration/CARING" framing.
- **Tone** — "Direct, rigorous, and highly technical", replacing the stock
  "Passionate ... from a place of CARING ... Use CAPS for emphasis".
- **Expertise** — Clean/Hexagonal/Screaming Architecture, DDD, System Design, API
  architecture, AI agent orchestration, testing, LazyVim, Tmux, Zellij (replaces
  "atomic design, container-presentational pattern").
- **Behavior** — drops the construction-analogy bullet and adds three rules: never
  use analogies/metaphors, Context-Aware Idiomatic Code, and the 3-line risk
  breakdown (trigger / impact / fix).

Because the persona body gentle-ai renders is **byte-identical across all old-shape
hosts**, the overlay ships one canonical block and stamps it into each of them.
This is a whole-block replacement, not a bullet-by-bullet merge.

### 2. `deltas/rubric-tdd.md` — the RUBRIC TDD condition

The rubric condition tells the orchestrator that when a project's `sdd-init` defines
a per-work-type test rubric, it must classify the change by its diff signature and
forward the matching rubric row into the sub-agent prompt — including when
`strict_tdd` is `false`, since a rubric row can demand test-first independently of
the binary flag.

**It is item 4 of the MANDATORY numbered list**, not a paragraph after it:

```
#### Strict TDD Forwarding (MANDATORY)

1. Search for testing capabilities: ...
2. If the result contains `strict_tdd: true`: ...
3. If the search fails or `strict_tdd` is not found, ...
4. **Additional condition — per-work-type rubric (project-generated, ...).**
   If the init defines a per-work-type test rubric, classify the change ...
```

Why the shape matters: a loose paragraph trailing the list can be read as optional
commentary, whereas item 4 of a list whose heading says **(MANDATORY)** inherits that
force. The overlay originally injected the loose-paragraph form; `apply.sh` now
**migrates** it to the numbered form wherever it finds it.

The delta file carries three blocks, each fenced by `<!-- shape:NAME -->` markers:

| Block | Used for |
| --- | --- |
| `list-item` | the canonical item 4 — every host that has the numbered list |
| `prose` | the condensed paragraph — the one host that has no list (see below) |
| `cache-sentence` | the richer "resolves the rubric + `strict_tdd` ONCE per session … re-classifying each apply slice by its diff signature" sentence, which replaces the weaker "resolves TDD status ONCE per session" wherever that sentence exists |

The canonical wording of `list-item` and `cache-sentence` comes from
`~/.claude/claude-bk-03-07.md` (the "Strict TDD Forwarding (MANDATORY)" section),
which is the source of truth.

### 3. `deltas/pi-model-agnostic.md` — pi's Model Assignments, made host-agnostic

gentle-ai renders the SDD **Model Assignments** table with *Claude* aliases —
`opus` / `sonnet` / `haiku` — into every host, pi included, together with the prose
*"If you lack access to the assigned model, substitute `sonnet` and continue."*

That is wrong for pi. pi has its own authoritative phase routing in
`~/.pi/gentle-ai/models.json`, which maps every phase (`sdd-*`, `jd-*`, `review-*`,
`gentle-ai-worker`) to a concrete `openai-codex/gpt-5.6-{luna,terra,sol}` model plus a
thinking level. **pi cannot resolve `opus`/`sonnet`/`haiku` at all** — so the rendered
table tells pi's orchestrator to pass aliases that do not exist there, contradicting
pi's own routing.

The delta rewrites pi's block so that:

- every `Default Model` cell reads `inherit`;
- the prose defers to `models.json` and states the orchestrator MUST NOT pass an
  explicit model alias — phases inherit;
- the `substitute sonnet` fallback is gone;
- the Phase and Reason columns, the heading, and the
  `<!-- gentle-ai:sdd-model-assignments -->` markers are preserved intact.

One sentence *outside* the block also had to change. gentle-ai emits:

> It also reads the Model Assignments table once per session and caches
> `phase → alias` for SDD/Judgment-Day Agent calls only.

That is the only directive actually telling pi to pass aliases, so the delta replaces
it with the inherit-based wording. (There is **no** literal "Agent tool calls … MUST
include `model`" gate in pi's file; this sentence is the real gate.)

**pi only.** See the scope note below.

## Host -> file -> shape map

| Host | File | Persona | RUBRIC TDD |
| --- | --- | --- | --- |
| `claude-code` | `~/.claude/CLAUDE.md`, `~/.claude/output-styles/neutral.md` | split shape, user-managed — **not touched** | — |
| `claude-code` | `~/.claude/skills/_shared/sdd-orchestrator-workflow.md` | — | **prose** — this surface has no numbered list |
| `pi` | `~/.pi/agent/APPEND_SYSTEM.md` | marker block | item 4 (same file) |
| `opencode` | `~/.config/opencode/AGENTS.md` | marker block | — |
| `opencode` | `~/.config/opencode/opencode.json` | — | item 4, via `jq` into `.agent["gentle-orchestrator"].prompt` |
| `codex` | `~/.codex/AGENTS.md` | heading-bounded | **n/a** — template has no strict-TDD section |
| `cursor` | `~/.cursor/rules/gentle-ai.mdc` | heading-bounded | item 4 (same file) |
| `vscode-copilot` | `~/.config/Code/User/prompts/gentle-ai.instructions.md` | heading-bounded | item 4 (same file) |
| `antigravity` | `~/.gemini/GEMINI.md` | marker block | item 4 (same file) |

### Why claude-code keeps the prose shape

`sdd-orchestrator-workflow.md` is a *condensed* surface: its Strict TDD Forwarding
section is a single sentence of prose, with no numbered list to be item 4 *of*.
Promoting the rubric there would mean inventing a list that gentle-ai does not emit.
The loose-paragraph shape is the only one that fits, so that host is deliberately
left in prose form and `apply.sh` reports it as `already-applied`.

Two persona shapes exist in the wild:

- **Old / full-inline shape** (pi, opencode, codex, cursor, vscode-copilot,
  antigravity): the whole persona is inlined into the host file. Some hosts wrap it
  in `<!-- gentle-ai:persona -->` markers, some do not — the overlay locates the
  block by markers where they exist and by heading range (`## Rules` up to the first
  `<!-- gentle-ai:` section marker) where they do not.
- **New / split shape** (claude-code only): `CLAUDE.md` keeps Rules + Expertise +
  Skill Loading, while Tone / Behavior / Language live in
  `output-styles/neutral.md`. These are maintained by hand and are already correct,
  so the overlay reports them as *already-applied* and never rewrites them.

## Anchors, not line numbers

Generated files shift between gentle-ai versions, so nothing here is a line-number
patch. Anchors are structural: HTML comment markers, section headings, and exact
sentence prefixes. `apply.sh` additionally refuses to overwrite a persona region
that does not contain exactly nine `##` sections — a guard against a template
reshuffle silently eating unrelated content.

If gentle-ai changes a template, the matching anchor disappears, `apply.sh` reports
`ANCHOR-NOT-FOUND` and exits `1` instead of guessing.

## Model-assignments scope: which hosts are touched, and why

The overlay rewrites the model-assignments block **for `pi` only**. State of every host:

| Host | Model-assignments block | Overlay action |
| --- | --- | --- |
| `pi` | Claude aliases, but pi routes via `~/.pi/gentle-ai/models.json` — **contradiction** | **rewritten to `inherit`** |
| `claude-code` | Claude aliases, rendered from `claude_phase_assignments` in `~/.gentle-ai/state.json` — **correct**, they are real aliases the user chose | untouched |
| `opencode` | **already host-appropriate**: gentle-ai emits a block deferring to `agent.<phase>.model` in `opencode.json` (which routes to `ollama/*`). No aliases. | untouched |
| `cursor` | Claude aliases | untouched — reported only |
| `vscode-copilot` | Claude aliases | untouched — reported only |
| `antigravity` | Claude aliases | untouched — reported only |
| `codex` | no block | — |

cursor / vscode-copilot / antigravity carry the same Claude-alias table as pi did. They
have **no competing model-routing config of their own**, so there is no contradiction of
pi's kind to resolve — the aliases are simply meaningless on a non-Claude host. Left
alone deliberately; revisit only if those hosts gain their own routing.

## Deliberately NOT in this overlay

- **The SDD model-assignments table** in hosts other than `pi` — see the scope table
  above. For `claude-code` it is rendered from `claude_phase_assignments` in
  `~/.gentle-ai/state.json` and is correct; edit it through gentle-ai, not here.
- **The CodeGraph guidance block** (`<!-- gentle-ai:codegraph-guidance -->`) is
  emitted by the `codegraph` community-tool component. Also installer-managed.

## Notes

- `~/.pi/agent/gentle-ai/managed-assets.json` tracks a sha256 per managed asset, but
  **`APPEND_SYSTEM.md` is not among them** (only `chains/*.chain.md` and
  `gentle-ai/support/*.md` are). Rewriting it therefore does not create hash drift,
  and `gentle-ai doctor` has no checksum to complain about for that file.
- Rewriting `opencode.json` through `jq` reformats the document (jq's canonical
  2-space form). The content is semantically identical and validated with
  `jq empty` before installation; gentle-ai regenerates the file wholesale on the
  next sync anyway.
