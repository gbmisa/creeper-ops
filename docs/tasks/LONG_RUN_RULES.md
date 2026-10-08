# Rules for long, unattended Grok runs

These apply to every brief named `*_long.md`, on top of [AGENTS.md](../../AGENTS.md) and [README.md](README.md).

- Do the phases **in order**. Each phase ends **playable**: parse check clean, full smoke all PASS (the castle-garrison check flakes ~1 in 10; re-run once if only that fails), then **commit** with message `<Stage> Pn: ...`.
- Keep a running log in `docs/tasks/<STAGE>_progress.md` (the brief names it): per phase, what you did, test output (pass count, sim lines), every decision where the spec was silent, and what is unfinished. Update it **before** each commit. If the session dies, Opus resumes from this file.
- If a phase is blocked after a real attempt (about 3 tries at the same problem), write exactly what blocks it in the log, revert the half-done part so the branch stays green, and **continue with the next phase that doesn't depend on it**.
- Every file under ~250 lines: split by responsibility before it gets close (smoke files too: start `smoke_x2.gd` rather than growing one past 250). New tunables in `config.gd`, a def table or level data. New `class_name` files: run `godot --headless --path godot --import`.
- New smoke checks go in the new smoke file(s) the brief names, each registered with one line in `smoke_test.gd`. A smoke check must not depend on what earlier smoke files left behind: clear raiders/shots/structures it relies on.
- Screenshots (Xvfb, CLAUDE.md Testing §5) for everything visible. Look at them yourself before saying something works.
- Don't edit HANDOFF.md or CLAUDE.md. In MASTER_PLAN.md change only your stages' status cells and add one Changelog line at the end. List new files in your report so Opus can update the CLAUDE.md map.
- Never merge, rebase or push; commit only on your branch; never touch `main` or its working tree. Don't start work outside the brief: put ideas in the log under **Suggestions**.
- Finish with the AGENTS.md report: per phase done / partial / skipped, commits, test counts, sims before/after, screenshot paths, spec gaps you filled.
