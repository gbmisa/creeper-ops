---
name: greenlight
description: Review scored ideas on the gdflow board with the user and record their decisions (approve, park, reject), then optionally write a task brief for an approved idea. Use when the user wants to choose what to build next, triage ideas, or greenlight/approve work.
---

# Greenlight: the human decides what gets built

1. `{cli} idea list --status scored raw` and `{cli} status`. Score any raw idea first
   (`{cli} idea score`), with a one-line rationale per score.
2. Present at most 4 ideas at a time, highest priority first, with: pitch, hook, pillar, cost/risk, and
   your recommendation (build now / park / reject) plus one sentence why. Flag ideas that conflict with
   work in progress.
3. Ask the user with AskUserQuestion (one question per idea, options: Approve, Park, Reject). **Only the
   user's explicit answer counts.** Never approve on their behalf, never infer approval from silence.
4. Record each answer: `{cli} idea move I-00N approved --by human --why "<their reason>"` (park/reject
   need `--why`). If an answer settles a design rule, also `{cli} decide "<rule>" --why "..." --by human --idea I-00N`.
5. For approved ideas the user wants built now: `{cli} brief I-00N --model "<agent>"`, then fill in the
   brief's TODO Scope and Acceptance with concrete, testable lines (name exact files; keep it one
   short agent run). Tell the user the brief path.
