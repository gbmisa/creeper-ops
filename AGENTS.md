# AGENTS.md: rules for delegated agents (Grok Build, Muse Code, Claude Sonnet/Haiku and any other non-orchestrator)

**Claude (Opus) is the orchestrator.** It writes the task briefs, reviews every branch and is the **only** agent that merges. The user decides what gets done. You do **one brief** and nothing else.

## Hard rules
1. **Do only what your brief (`docs/tasks/<FILE>.md`) or the user explicitly tells you to do.** If something seems worth doing but isn't in the brief, don't do it: list it in your report as a suggestion.
2. **Never merge, rebase, cherry-pick, reset or push.** Never touch `main` or any other branch. Never create or delete branches or worktrees.
3. **Commit only on your own worktree's branch**, and only work inside your worktree folder.
   **Never commit anything `.gitignore` excludes** (`godot/.godot/` caches, logs, `user://` files). If you push through an API that ignores `.gitignore`, check every path against it first.
4. **Never start the next stage**, even if it looks obvious from MASTER_PLAN.md.
5. **Don't edit HANDOFF.md.** In MASTER_PLAN.md, change only your own stage's status cell and add one Changelog line.
6. If the brief is unclear or conflicts with the code, **stop and ask** instead of guessing.
7. Never touch `user://keybinds.cfg`; never rename existing action or structure ids.

## When you finish
Stop and report exactly:
- **Done:** what you changed (files), and the commit hash(es) on your branch.
- **Verified:** parse check, smoke result (pass/fail count), and the sim or screenshot the brief asked for.
- **Not done / unsure:** anything skipped, guessed or worth the orchestrator's attention.
- **Suggestions:** ideas outside the brief (not implemented).

Say "committed on branch X". **Never say "merged"**: merging is the orchestrator's job, after review.

Project conventions, architecture and tests: see CLAUDE.md.
