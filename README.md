# Gentle AI Overrides

An anchor-based overlay that reapplies personal prompt and orchestration changes
after [Gentle AI](https://github.com/Gentleman-Programming/gentle-ai) regenerates
its managed agent configuration.

This is an unofficial, community-maintained project. It is not affiliated with,
endorsed by, or supported by Gentleman Programming. Gentle AI and its original
prompt assets are licensed separately; see [Third-Party Notices](THIRD_PARTY_NOTICES.md).

Validated with Gentle AI `2.2.0` on Linux and macOS.

## Install

Requirements: Bash 3.2 or newer and standard POSIX command-line tools. `jq` is
required when OpenCode is installed.

```sh
git clone https://github.com/kozz36/gentle-ai-overrides.git ~/gentle-ai-overrides
cd ~/gentle-ai-overrides
./apply.sh --check
./apply.sh
```

Run the overlay after every `gentle-ai sync`, `gentle-ai upgrade`, or
`gentle-ai install`. Gentle AI regenerates host configuration from embedded
templates during those operations, replacing manual edits.

## Usage

```sh
~/gentle-ai-overrides/apply.sh          # apply the overlay (idempotent)
~/gentle-ai-overrides/apply.sh --check  # report only, write nothing
```

Exit codes:

| Code | Meaning |
| --- | --- |
| `0` | Overlay applied, or already applied (no-op). |
| `1` | Safety failure: missing/ambiguous anchor, unsafe target, failed backup/write, or concurrent target change. |
| `2` | `--check` only: work is pending. |

`apply.sh` never invokes Gentle AI and never modifies
`~/.gentle-ai/state.json`. Before each first write, it copies the original file
to `backups/<timestamp>/<path-relative-to-$HOME>`. It refuses symbolic links,
non-regular targets, missing or ambiguous anchors, failed backups, and targets
that change during transformation. A no-op or `--check` run creates no backup.

## Compatibility

The transforms intentionally fail closed when an upstream template no longer
matches a known structure. After upgrading Gentle AI:

1. Run `./apply.sh --check`.
2. Review any `ANCHOR-NOT-FOUND` result against the new upstream template.
3. Update and test the matching transform before applying it.

The regression suite runs on Ubuntu and macOS:

```sh
bash -n apply.sh tests/run.sh tests/init-rubric-contract.sh
bash tests/init-rubric-contract.sh
bash tests/run.sh
```

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
  use analogies/metaphors, Context-Aware Idiomatic Code, and severity-aware risk
  communication that preserves condition / consequence / mitigation without
  forcing routine caveats into a rigid template.

Because the persona body gentle-ai renders is **byte-identical across all old-shape
hosts**, the overlay ships one canonical block and stamps it into each of them.
This is a whole-block replacement, not a bullet-by-bullet merge.

### 2. Claude Code split-persona files

Claude Code uses a split persona instead of the nine-section inline block:

- `persona/claude-split-rules.md` replaces only `## Rules` inside the marked
  persona block in `~/.claude/CLAUDE.md`.
- `persona/claude-split-expertise.md` replaces only `## Expertise` in that same
  block.
- `persona/neutral-style.md` is the canonical complete
  `~/.claude/output-styles/neutral.md` file.

`## Contextual Skill Loading` and `## Persona Voice` remain installer-managed
and are preserved byte-for-byte. Missing persona markers or either targeted
heading fail the preflight before any file is written.

### 3. `deltas/rubric-tdd.md` — the RUBRIC TDD condition

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

The canonical wording of `list-item` and `cache-sentence` is maintained in
`deltas/rubric-tdd.md`, which is the overlay's source of truth.

### 4. `deltas/sdd-init-rubric.md` — the TDD policy producer

This isolated spike keeps `sdd-init` as the sole project-policy writer. It makes
a minimal consumer wording alignment in `deltas/rubric-tdd.md` so active rubrics
resolve all applicable rows consistently; the consumer remains read-only. The
managed sections detect a closed set of satisfiable evidence methods, preserve
binary `strict_tdd` when sufficient, and block on an explicit `strict|rubric`
choice when project-specific, scope-aware rules are necessary. The standalone
contract suite validates these static policy and delta-shape guarantees without
loading `apply.sh`; `tests/run.sh` covers the cross-host transform behavior.

The contract requires project-derived signatures, a `strict_tdd`-derived default
row, strictest-wins matching with unioned obligations, equivalent mode-specific
persistence, and confirmation-gated re-init drift maintenance. `apply.sh`
installs it before the exact 2.2.0 anchors `## Decision Gates`, `## Output
Templates`, and Pi's `## Memory Contract`; incomplete or ambiguous managed
markers/anchors fail closed.

For OpenCode, `SKILL.md` and `references/` remain support/manual surfaces. The
hidden `sdd-init` agent executes the prompt resolved from
`.agent["sdd-init"].prompt` in `opencode.json`; the mapped
`prompts/sdd/sdd-init.md` receives the same marker-bounded `skill` contract.

### 5. `deltas/pi-model-agnostic.md` — pi's Model Assignments, made host-agnostic

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

### 6. OpenCode Engram injection — idempotent fallback

OpenCode already receives the full Engram protocol from `AGENTS.md`. Its Engram
plugin still needs a fallback for configurations where that block is absent, but
must not append a second protocol on every message when it is present. The overlay
rewrites only the `experimental.chat.system.transform` prefix so it checks for the
managed marker or protocol heading before appending `MEMORY_INSTRUCTIONS`; the
dynamic save nudge and the rest of the plugin remain installer-managed.

Pi's concrete proposal phase is named `sdd-proposal`. The Pi model-assignment
transform normalizes stale `sdd-propose` references in `APPEND_SYSTEM.md` to that
real agent identifier while preserving host-owned model routing.

## Host -> file -> shape map

| Host | File | Persona | RUBRIC TDD |
| --- | --- | --- | --- |
| `claude-code` | `~/.claude/CLAUDE.md`, `~/.claude/output-styles/neutral.md` | split shape — Rules + Expertise are heading-bounded; neutral style is replaced wholesale | — |
| `claude-code` | `~/.claude/skills/_shared/sdd-orchestrator-workflow.md` | — | **prose** — this surface has no numbered list |
| `pi` | `~/.pi/agent/APPEND_SYSTEM.md` | marker block | item 4 (same file) |
| `opencode` | `~/.config/opencode/AGENTS.md` | marker block | — |
| `opencode` | `~/.config/opencode/opencode.json` | — | item 4, via `jq` into `.agent["gentle-orchestrator"].prompt` |
| `opencode` | `~/.config/opencode/skills/sdd-init/SKILL.md`, `~/.config/opencode/skills/sdd-init/references/init-details.md` | support/manual surfaces for `sdd-init` | — |
| `opencode` | `~/.config/opencode/prompts/sdd/sdd-init.md` | executable `sdd-init` entrypoint from `.agent["sdd-init"].prompt`; managed before `## Decision Gates` | — |
| `codex` | `~/.codex/AGENTS.md` | heading-bounded | **n/a** — template has no strict-TDD section |
| `cursor` | `~/.cursor/rules/gentle-ai.mdc` | heading-bounded | item 4 (same file) |
| `vscode-copilot` | `~/.config/Code/User/prompts/gentle-ai.instructions.md` | heading-bounded | item 4 (same file) |
| `gemini-cli`, `antigravity` | `~/.gemini/GEMINI.md` | marker block | item 4 (shared file) |

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
  Skill Loading + Persona Voice, while Tone / Behavior / Language live in
  `output-styles/neutral.md`. The overlay replaces only Rules and Expertise in
  `CLAUDE.md`, preserves the other two sections, and installs the canonical
  `neutral.md` file.

## Anchors, not line numbers

Generated files shift between gentle-ai versions, so nothing here is a line-number
patch. Anchors are structural: HTML comment markers, section headings, and exact
sentence prefixes. `apply.sh` additionally refuses to overwrite a full-inline
persona region that does not contain exactly nine `##` sections; the split shape
requires its persona markers plus `## Rules` and `## Expertise`. These guards stop
a template reshuffle from silently consuming unrelated content.

Before writing, `apply.sh` runs a global `--check` preflight. If gentle-ai changes a
template, the matching anchor disappears, preflight reports `ANCHOR-NOT-FOUND` and
the apply run exits `1` without modifying any host file.

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
