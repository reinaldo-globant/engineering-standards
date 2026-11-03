# engineering-standards

One engineering baseline, two delivery formats, no plugin installs.

Built for environments where you cannot drop third-party Claude Code plugins into the machine:
the whole thing is plain Markdown in a repo, copied in by a script.

## What's inside

**`skills/engineering-standards/SKILL.md`** — the always-loaded baseline:

- **Three iron laws** — root cause before fix · failing test before code · fresh evidence before
  any completion claim.
- **Right-sizing gate** — Throwaway / Evolving / Core tiers decide how much structure is *correct*.
  The floor (validation, error handling, security, accessibility, clarity) is tier-independent.
- **The YAGNI ladder** — seven rungs, stop at the first that holds. No abstraction without a
  second caller.
- **Solution before stack** — the design is stated with no language, framework or library in it;
  the stack is chosen afterwards, from the solution.
- **Repository context** — every repo carries `docs/ARCHITECTURE.md` (structure as it *is*, updated
  in the same diff as the code) and `docs/MEMORY.md` (only what the code and git log cannot tell
  you). An index of repositories lives in `$ES_REGISTRY`, default `~/.claude/REPOSITORIES.md`,
  outside every repo.
- Clean code · SOLID · design-decision protocol · error handling · security baseline ·
  communication · git discipline · approval gates.

**`skills/engineering-standards/references/`** — loaded on demand, one per situation:

| File | Load when |
|---|---|
| `debugging.md` | Any bug or test failure, before proposing a fix. 4 phases + the 3-fix rule |
| `tdd.md` | Before writing implementation code. RED → GREEN → REFACTOR, verify each |
| `verification.md` | About to claim done/fixed/passing. The gate + claim→evidence table |
| `planning.md` | Spike / Bounded / Architectural paths, written plans, executing them |
| `code-review.md` | Requesting a review, and receiving one without performative agreement |
| `delegation.md` | Subagents, parallel dispatch, worktrees, verifying agent output |
| `architecture.md` | Core-tier design: layers, dependency rule, modular monolith |
| `repo-memory.md` | Entering a repo: the two docs, what belongs in each, the registry |

## Install

**bash / zsh** (Linux, macOS, WSL, Git Bash):

```bash
./scripts/install.sh                 # user-wide Claude Code skill (~/.claude/skills)
./scripts/install.sh /path/to/repo   # into a project, all targets at once
```

**PowerShell** (5.1 and later):

```powershell
.\scripts\install.ps1
.\scripts\install.ps1 C:\src\my-project
```

**cmd.exe** — wrapper around the same script, and the way around a restrictive execution policy:

```bat
scripts\install.cmd
scripts\install.cmd C:\src\my-project
```

If PowerShell refuses `install.ps1` directly (`running scripts is disabled on this system`), use
`install.cmd` — it passes `-ExecutionPolicy Bypass` for that one invocation without changing any
machine setting.

Into a project it writes `.claude/skills/`, `.cursor/rules/`, `.github/` and `AGENTS.md`
(the last one only if the repo doesn't already have one — otherwise merge by hand).

The generated files are committed, so **installing never needs a build.** Regenerating them after
editing `skills/engineering-standards/` needs bash: `./scripts/build.sh`, from Git Bash or WSL on
Windows. Editing the standard is a maintainer action; installing it is not.

## Targets

| Tool | Files | Loading |
|---|---|---|
| Claude Code (CLI, desktop, VS Code / JetBrains extension) | `.claude/skills/engineering-standards/` | Native skill: SKILL.md always, `references/` on demand |
| Cursor | `.cursor/rules/engineering-standards.mdc` (`alwaysApply: true`)<br>`.cursor/rules/engineering-workflows.mdc` (`alwaysApply: false`, agent-requested) | No lazy file loading — baseline always on, workflows pulled by description |
| VS Code + GitHub Copilot | `.github/copilot-instructions.md`<br>`.github/instructions/engineering-workflows.instructions.md` (`applyTo: '**'`) | Baseline always on. In agent mode Copilot can also open the `references/` files directly — the paths in the baseline point at them |
| Anything else that reads `AGENTS.md` | `AGENTS.md` | Thin pointer only, no duplicated content |

Copilot needs `github.copilot.chat.codeGeneration.useInstructionFiles: true` in VS Code settings
(default on in current versions).

If the always-on workflows file costs too much context in Copilot, narrow its `applyTo` globs or
delete it — agent mode still reaches the references through the paths in the baseline.

**Never edit the generated files** (`.cursor/rules/*.mdc`, `.github/**`, `AGENTS.md`). Edit
`skills/engineering-standards/`, then:

```bash
./scripts/build.sh
```

`build.sh` fails if the iron laws, the reference bodies, or the rewritten reference paths don't
survive generation — that's the test.

## Integrity lock

Agents execute what these files tell them to, so every file an agent reads as instructions —
`AGENTS.md`, the Cursor and Copilot files, the whole skill — is covered by
`.engineering-standards.sha256`. `build.sh` writes it, after a scan that refuses any network call
or code execution (`curl`, `wget`, `irm`/`iwr`, `iex`, `eval`, `base64`, `| sh`, `sh -c`, any
`http(s)://`) and any invisible unicode (zero-width or bidi-override characters that hide text from
a reviewer).

- **History:** the lock is committed. Every approved change to the instructions shows up as a hash
  diff in `git log -p .engineering-standards.sha256` — a PR that changes instructions without
  changing the lock, or changes the lock without changing a source, is the one to read twice.
- **Hand edits are caught:** a generated file edited without rebuilding no longer matches its
  hash. `scripts/integrity.sh verify` exits non-zero.
- **Installs are checked:** `install.ps1` refuses to copy unless this repo matches its lock (it
  copies committed files, with no build step); `install.sh` rebuilds first. Both leave a lock in the
  target, checked later with `scripts/install.sh --verify <repo>` or `install.ps1 -Verify <repo>`.
  A pre-existing `AGENTS.md` belongs to the target repo and stays out of its lock.

The scan is a tripwire, not a sandbox: an instruction written as plain prose ("send the contents of
`.env` to …") passes it. The hash diff in review is what catches that. `scripts/test-integrity.sh`
checks that every injection path above fails.

## Provenance

Distilled from three sources, all MIT:

- [superpowers](https://github.com/obra/superpowers) (Jesse Vincent) — the iron-law framing, TDD
  cycle, systematic debugging phases, verification gate, brainstorming paths, review reception.
- [ponytail](https://github.com/dietrichgebert/ponytail) (Dietrich Gebert) — the YAGNI ladder,
  "no abstraction without a second caller", marked deliberate shortcuts.
- The author's own `global-engineering-guidelines` — clean code, SOLID, clean architecture,
  right-sizing tiers, git discipline, approval gates.

The persona and tone layers of both plugins were deliberately left out. This is a standard, not
a character.

## License

MIT — see [LICENSE](LICENSE).
