# Skill scripts depend only on what Windows and macOS ship out of the box

Skills in this repo are supported on Windows and macOS, and their scripts may use only what those two systems ship with: `powershell.exe` (Windows PowerShell 5.1) on Windows, POSIX `sh` and `awk` on macOS. No Node, no Python, no `pwsh`. A skill that asks the user to install something first is a skill they will hit an error with instead of using — and the error arrives at the worst moment, when a grill has already paused waiting for their answer.

## Considered options

Requiring a single common runtime (Node being the obvious candidate) would collapse each skill to one script with one copy of its logic. We rejected it because the cost lands on every person who ever uses the skill, repeatedly, whereas the cost of writing two thin scripts lands on us once.

Assuming whatever the agent harness provides — Claude Code ships a bash on Windows, so one `.sh` would cover both platforms — was tempting for the same reason. We rejected it because it ties a skill's survival to a harness implementation detail we do not control and would not be told about if it changed.

## Consequences

**Validation cannot live in the build scripts.** Windows PowerShell 5.1 has no JavaScript engine and macOS has no PowerShell, so no single validator can run on both, and writing one per platform reproduces the drift that caused the bugs this decision came out of. Payload rules therefore live in `assets/questionnaire-template.html` and run in the browser — the one runtime that is guaranteed present, because without it the questionnaire has no purpose. The trade-off is real: a build's exit code no longer tells you whether the payload is sound. The page reports that instead, and the user is looking at it within seconds.

**Build scripts may only splice text, then launch.** Read, escape, substitute, write, print the path, open the browser. Any rule about payload content belongs in the renderer. This is the only thing keeping the two scripts equivalent — we have no Windows-plus-macOS test environment to catch drift, so the rule has to do that work.

**A launcher may never fail the build.** The generated file is useful on its own, so the path is printed before the browser is launched and a non-zero launcher is swallowed. Coupling them the other way round meant a failed `xdg-open` on a headless host discarded a path to a file that had been written successfully. Keeping the launch inside the script costs nothing — the scripts are already one per platform — and it keeps the whole flow to a single command.

**PowerShell scripts are capped at 5.1 syntax.** Nothing that needs PowerShell 7 — no `??`, no `?.`, no `-Parallel`. Invoke with `powershell.exe`, never `pwsh`.
