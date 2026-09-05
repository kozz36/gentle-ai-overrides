# Gentle AI Overrides

An anchor-based overlay that reapplies personal prompt and orchestration changes
after [Gentle AI](https://github.com/Gentleman-Programming/gentle-ai) regenerates
its managed agent configuration.

This is an unofficial, community-maintained project. It is not affiliated with,
endorsed by, or supported by Gentleman Programming. Gentle AI and its original
prompt assets are licensed separately; see [Third-Party Notices](THIRD_PARTY_NOTICES.md).

Active-surface compatibility was reverified with official Gentle AI `2.6.0` on Linux
with `gentle-pi@2.4.0`; final `2.5.0` and `2.5.0-rc.3` OpenCode shapes remain
accepted as bounded legacy compatibility forms.

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
templates during those operations, replacing manual edits. After any
`gentle-pi` package update, run `./apply.sh --check` and reapply: the Pi rubric
and SDD-init overlays target package assets that package installation replaces.
Pi may install that package from git or npm; the overlay resolves one configured
package root for both assets rather than assuming one layout.

## Usage

```sh
~/gentle-ai-overrides/apply.sh          # apply the overlay (idempotent)
~/gentle-ai-overrides/apply.sh --check  # report only, write nothing
```

Exit codes:

| Code | Meaning |
| --- | --- |
| `0` | Overlay applied, or already applied (no-op). |
| `1` | Safety failure: missing/ambiguous anchor, unsafe target, ambiguous/conflicting Pi package source, failed backup/write, or concurrent target change. |
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
- `persona/neutral-style.md` is the canonical complete selected-style body.
  It replaces either `~/.claude/output-styles/neutral.md` or
  `~/.claude/output-styles/gentleman.md`; the filename is native state, not
  overlay configuration.

`## Contextual Skill Loading` and `## Persona Voice` remain installer-managed
and are preserved byte-for-byte. Missing persona markers or either targeted
heading fail the preflight before any file is written.

The selected style is resolved without changing the persona or profile: the
persisted Gentle AI `state.json` persona and Claude `settings.json`
`outputStyle` must agree when both exist. Persona `neutral` selects
`neutral.md`; personas `gentleman` and `gentleman-neutral-artifacts` select
`gentleman.md`. For isolated fixtures that lack selector metadata, exactly one
exposed native style file is accepted. An unknown selector, disagreement, or
zero/two style files fails closed; the overlay never creates a style file.

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

The delta file carries four blocks, each fenced by `<!-- shape:NAME -->` markers:

| Block | Used for |
| --- | --- |
| `list-item` | the canonical item 4 — every host that has the numbered list |
| `prose` | the condensed paragraph — the one host that has no list (see below) |
| `cache-sentence` | the session-cached, declared-intent classification sentence that replaces the weaker "resolves TDD status ONCE per session" wherever that sentence exists |
| `pi-workflow` | the marker-delimited Pi package workflow forwarding block after its binary Strict TDD contract |

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
installs it before the exact SDD-init anchors `## Decision Gates`, `## Output
Templates`, and Pi's `## Memory Contract`, which were reverified unchanged on
official Gentle AI 2.6.0 surfaces with `gentle-pi@2.4.0`; incomplete or ambiguous
managed markers and anchors fail closed.

OpenCode accepts exactly four hidden `sdd-init` shapes in strict `opencode.json`:

| Native shape | Executable surface | Overlay action |
| --- | --- | --- |
| Official 2.6.0 exact executor paragraph — `You are an SDD executor for the init phase, not the orchestrator. Do this phase's work yourself. Do NOT delegate, Do NOT call task, and Do NOT launch sub-agents. Read your skill file at ~/.config/opencode/skills/sdd-init/SKILL.md and follow it exactly.` — followed only by one complete `gentle-ai:agent-language-contract` block | `~/.config/opencode/skills/sdd-init/SKILL.md` | Applies the `skill` rubric overlay to the managed skill; the language-contract body remains installer-managed and no prompt file is created. |
| Official 2.5.0 exact executor paragraph — with either zero appended managed blocks or exactly one complete, ordered `gentle-ai:codegraph-guidance` block followed by one complete `gentle-ai:agent-language-contract` block | `~/.config/opencode/skills/sdd-init/SKILL.md` | Backward-compatible managed-skill overlay; the block bodies remain installer-managed and no prompt file is created. |
| Exact rc.3 inline prompt `Read your skill file at ~/.config/opencode/skills/sdd-init/SKILL.md and follow it exactly.` | `~/.config/opencode/skills/sdd-init/SKILL.md` | Backward-compatible managed-skill overlay; no prompt file is created. |
| Exact `{file:./prompts/sdd/sdd-init.md}` reference | `~/.config/opencode/prompts/sdd/sdd-init.md` | Applies the same `skill` rubric overlay to that referenced executable prompt. |

The external profile does not delegate to the managed skill. Its referenced
prompt is the executable phase surface, so it receives the overlay itself.
Any visible agent, missing file, symlink, arbitrary reference, traversal,
redirected/refusal text, arbitrary prefix/suffix, embedded sentence, or partial,
duplicate, unknown, or out-of-order managed marker block fails global preflight
before a host file is written.

Recovery commands are runtime-specific: Claude prose and the Pi workflow use
`recovery_action=run /gentle-sdd-init recovery`; numbered-list surfaces, including
OpenCode JSON, use `recovery_action=run /sdd-init recovery`.

### 5. Pi 2.6.0 / `gentle-pi@2.4.0` compatibility ownership

As of official 2.6.0 with `gentle-pi@2.4.0`, this overlay owns **no region** of
`~/.pi/agent/APPEND_SYSTEM.md`: `apply.sh` does not map, read, transform, back up, or
write it. The ownership split is:

- **Persona:** gentle-pi injects it at runtime, so an APPEND persona would duplicate the
  channel.
- **TDD/rubric:** the old eager Pi APPEND item-4 injection is retired. This overlay
  instead owns a marker-delimited block in gentle-pi's package lazy workflow (below).
- **Model routing:** Pi owns it outside APPEND through its models, frontmatter, and
  subagent mechanisms.
- **CodeGraph guidance:** the installer/community-tool owns it; leaving APPEND entirely
  untouched preserves it.

The Pi mappings retained by this overlay are the settings-selected `gentle-pi@2.4.0`
package assets: its `assets/agents/sdd-init.md`, which receives the
marker-delimited SDD-init rubric producer contract described above, and its
package-owned lazy workflow, where the overlay inserts the
`gentle-ai:pi-rubric-forwarding` block after the binary Strict TDD contract.

Both asset targets are resolved from one recognized gentle-pi package root in
`~/.pi/agent/settings.json` (`packages` entries may be strings or objects with a
`source` field):

- canonical GitHub git sources — shorthand
  `git:github.com/Gentleman-Programming/gentle-pi@<ref>`, HTTPS
  `git:https://github.com/Gentleman-Programming/gentle-pi.git#<ref>`, or SSH
  `git:ssh://git@github.com/Gentleman-Programming/gentle-pi.git#<ref>` /
  `git:git@github.com:Gentleman-Programming/gentle-pi.git#<ref>` — →
  `~/.pi/agent/git/github.com/Gentleman-Programming/gentle-pi/assets/{agents/sdd-init.md,sdd-orchestrator-workflow.md}`
- exact npm package `npm:gentle-pi@<version>` (or unprefixed `gentle-pi`) →
  `~/.pi/agent/npm/node_modules/gentle-pi/assets/{agents/sdd-init.md,sdd-orchestrator-workflow.md}`

Every configured source whose exact package, repository, or local-path basename is
`gentle-pi` is classified. Any noncanonical GitHub, local/path, or otherwise unsupported
`gentle-pi` identity reports `PACKAGE-TARGET-CONFIG-FAILURE` before root fallback and writes
nothing; unrelated names such as `gentle-pi-helper` are not classified as this package.
The overlay parses settings with `jq` when available, otherwise with Node (provided by Pi),
and sends both parser outputs through the same classifier. If settings exists but neither
parser is available, or settings is invalid JSON, it fails closed with
`PACKAGE-TARGET-CONFIG-FAILURE`; it never silently ignores an uninspectable configuration.
Only an absent settings file, or successfully parsed settings without a `gentle-pi` source,
permits unique-root fallback. If both layouts exist without one unambiguous configured source
or sources conflict, it reports `PACKAGE-TARGET-CONFIG-FAILURE` and writes nothing. A configured
source always wins over a stale alternate layout; if either selected asset is missing or unsafe,
the overlay reports that target instead of falling back. Neither mapping reads or modifies
`APPEND_SYSTEM.md`. The package assets are replaced by `gentle-pi`/package updates, so
run `./apply.sh --check` and reapply after each one.

### 6. OpenCode Engram injection — idempotent fallback

OpenCode already receives the full Engram protocol from `AGENTS.md`. Its Engram
plugin still needs a fallback for configurations where that block is absent, but
must not append a second protocol on every message when it is present. The overlay
rewrites only the `experimental.chat.system.transform` prefix so it checks for the
managed marker or protocol heading before appending `MEMORY_INSTRUCTIONS`; the
dynamic save nudge and the rest of the plugin remain installer-managed.

## Host -> file -> shape map

| Host | File | Persona | RUBRIC TDD |
| --- | --- | --- | --- |
| `claude-code` | `~/.claude/CLAUDE.md`, selected `~/.claude/output-styles/{neutral,gentleman}.md` | split shape — Rules + Expertise are heading-bounded; the selected native style is replaced wholesale | — |
| `claude-code` | `~/.claude/skills/_shared/sdd-orchestrator-workflow.md` | — | **prose** — this surface has no numbered list |
| `pi` | settings-selected gentle-pi `sdd-init`: git `~/.pi/agent/git/github.com/Gentleman-Programming/gentle-pi/assets/agents/sdd-init.md` or npm `~/.pi/agent/npm/node_modules/gentle-pi/assets/agents/sdd-init.md` | executable `sdd-init` asset | —; the SDD-init rubric producer contract is marker-delimited |
| `pi` | settings-selected gentle-pi workflow: git `~/.pi/agent/git/github.com/Gentleman-Programming/gentle-pi/assets/sdd-orchestrator-workflow.md` or npm `~/.pi/agent/npm/node_modules/gentle-pi/assets/sdd-orchestrator-workflow.md` | — | marker-delimited project-rubric forwarding after the binary Strict TDD contract; both Pi assets use the same selected package root and ambiguous roots fail closed |
| `opencode` | `~/.config/opencode/AGENTS.md` | marker block | — |
| `opencode` | `~/.config/opencode/opencode.json` | — | item 4, via `jq` into `.agent["gentle-orchestrator"].prompt` |
| `opencode` | `~/.config/opencode/skills/sdd-init/SKILL.md`, `~/.config/opencode/skills/sdd-init/references/init-details.md` | managed `sdd-init` skill and reference; the skill is transformed before `## Decision Gates` | — |
| `opencode` | `~/.config/opencode/opencode.json` | official 2.6.0 hidden executor paragraph followed only by the agent-language-contract block; legacy 2.5.0 zero-block and ordered CodeGraph/agent-language-contract forms, exact rc.3 inline prompt, or exact external reference remain accepted; external mode maps `prompts/sdd/sdd-init.md` as the executable skill-shaped target | — |
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
  the selected `output-styles/neutral.md` or `output-styles/gentleman.md`. The
  overlay replaces only Rules and Expertise in `CLAUDE.md`, preserves the other
  two sections, and replaces only the selected native style file with the
  canonical body.

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

## Pi `APPEND_SYSTEM.md` boundary (2.6.0 / `gentle-pi@2.4.0`)

`~/.pi/agent/APPEND_SYSTEM.md` is entirely outside this overlay's ownership boundary.
The 2.6.0 host map has no Pi row for that path, and the overlay contains no Pi model,
persona, rubric, or proposal-name transform **on APPEND**. A hermetic regression fixture
using the complete installer-managed CodeGraph and routing blocks verifies that APPEND
remains byte-identical and is neither read, transformed, backed up, nor written across
both `--check` and apply runs. Pi's separate `sdd-init` phase-agent mapping and package
lazy-workflow rubric block remain intentionally owned.

## Deliberately NOT in this overlay

- **`~/.pi/agent/APPEND_SYSTEM.md`** — official 2.6.0 with `gentle-pi@2.4.0` deliberately
  does not target any region of this Pi/Gentle AI-managed file. Edit or regenerate it
  through its owner, not this overlay.
- **The CodeGraph guidance block** (`<!-- gentle-ai:codegraph-guidance -->`) is
  emitted by the `codegraph` community-tool component. Also installer-managed.

## Notes

- `~/.pi/agent/gentle-ai/managed-assets.json` tracks a sha256 per managed asset, but
  **`APPEND_SYSTEM.md` is not among them** (only `chains/*.chain.md` and
  `gentle-ai/support/*.md` are). Official 2.6.0 with `gentle-pi@2.4.0` does not read or rewrite
  it, so the overlay cannot create hash drift for that file.
- Rewriting `opencode.json` through `jq` reformats the document (jq's canonical
  2-space form). The content is semantically identical and validated with
  `jq empty` before installation; gentle-ai regenerates the file wholesale on the
  next sync anyway.
