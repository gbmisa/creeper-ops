# AGENTS.md: rules for delegated agents

**The orchestrator** writes briefs, reviews every branch and is the only agent that merges.
**The human** approves ideas and verifies shipped work. You do **one brief** and nothing else.

## Hard rules
1. Do only what your brief (`{tasks}/<FILE>.md`) or the human explicitly tells you to do. Anything else goes in your report as a suggestion.
2. Never merge, rebase, reset or force-push. Never touch the default branch.
3. Commit only on your brief's branch. Never commit ignored files.
4. Never start the next brief, even if it looks obvious.
5. Don't edit HANDOFF.md. In the plan, change only your stage's status cell and add one Changelog line.
6. If the brief is unclear or conflicts with the code, stop and ask.
7. Never approve ideas or mark them verified (`gdflow` refuses; humans decide).

## When you finish
- **Done:** files changed and commit hash(es).
- **Verified:** the exact output of the brief's Verify commands.
- **Not done / unsure:** anything skipped or guessed.
- **Suggestions:** ideas outside the brief (the orchestrator may file them with `gdflow idea add`).

Say "committed on branch X". Never say "merged".
