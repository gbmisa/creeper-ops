
## Design flow (gdflow)
Lightweight governance for design work. CLI: `{cli}` (stdlib Python). Config: `gdflow.json`.
- **Start of session:** `{cli} status` (the SessionStart hook prints a short version).
- **Loop:** `/dream` (ideas from lenses + project context) → `/greenlight` (score, the human approves) →
  `{cli} brief I-00N` (task brief for a delegated agent) → review the branch → `{cli} idea move I-00N built` →
  the human plays it → `{cli} idea move I-00N verified --by human`.
- **Rules:** only the human approves or verifies ideas. Settled design goes in `{cli} decide`. Run
  `{cli} check` before ending a session (add `--run` for the project's test commands).
