"""`gdflow dream`: builds a compact, randomized ideation packet for the agent.

The CLI never calls a model. It gathers just enough project context (pillars,
plan state, recent changes, playtest notes, existing ideas), draws lenses and a
constraint, and prints a prompt. The agent (the `dream` skill) does the dreaming
and files each idea back with `gdflow idea add --source dream`.
"""
import glob
import os
import random

from . import markdown as md
from .ideas import Store
from .lenses import CONSTRAINTS, LENSES, by_id


def pillars(project):
    cfg = project["pillars"]
    text = project.read(cfg["file"])
    return md.bullets(md.section(text, cfg["section"])) if text else []


def plan_state(project):
    text = project.read(project["plan"]["file"])
    stages = md.plan_stages(text)
    log = md.bullets(md.section(text, project["plan"]["changelog_section"]))
    return stages, log


def playtest_notes(project, limit=2):
    globs = project.get("playtest_globs") or [os.path.join(project["playtest_dir"], "*.md")]
    found = {f for g in globs for f in glob.glob(project.path(g))}
    files = sorted(found, key=os.path.getmtime, reverse=True)[:limit]
    out = []
    for f in files:
        with open(f, encoding="utf-8") as fh:
            body = " ".join(l.strip() for l in fh.read().splitlines()[:12] if l.strip())
        out.append(f"{os.path.basename(f)}: {clip(body, 400)}")
    return out


def clip(s, n):
    return s if len(s) <= n else s[: n - 1].rstrip() + "…"


def draw(n, forced, seed):
    rng = random.Random(seed)
    known = by_id()
    picked = [(lid, *known[lid]) for lid in forced if lid in known]
    pool = [l for l in LENSES if l[0] not in forced]
    picked += rng.sample(pool, max(0, n - len(picked)))
    return picked, rng.choice(CONSTRAINTS)


def packet(project, count=5, lenses=3, forced=(), focus="", seed=None):
    store = Store(project)
    stages, log = plan_state(project)
    drawn, constraint = draw(lenses, list(forced), seed)
    systems = project["systems"] or [s["name"] for s in stages][-12:]
    rng = random.Random(seed)
    pair = rng.sample(systems, 2) if len(systems) >= 2 else systems

    cli = project["cli"]
    p = [f"# Dream packet: {project['project']}", ""]
    pil = pillars(project)
    p += ["## Pillars (every idea must serve at least one)"]
    p += [f"- {clip(x, 220)}" for x in pil] or ["- (none set: write pillars first, `gdflow check` flags this)"]
    if stages:
        open_ = [s for s in stages if s["status"] in ("doing", "todo")]
        counts = {k: sum(1 for s in stages if s["status"] == k) for k in ("done", "unverified", "doing", "todo")}
        p += ["", "## Where the game is", "Stages: " + ", ".join(f"{v} {k}" for k, v in counts.items() if v)]
        p += [f"- open: {s['id']} {clip(s['name'], 90)}" for s in open_[:5]]
    if log:
        p += ["", "## Recent changes"] + [f"- {clip(x, 260)}" for x in log[:3]]
    notes = playtest_notes(project)
    if notes:
        p += ["", "## Playtest notes"] + [f"- {n}" for n in notes]
    if systems:
        p += ["", "## Systems", ", ".join(systems)]
    taken = [f"{i['id']} {i['title']} ({i['status']})" for i in store.ideas]
    if taken:
        p += ["", "## Already on the board (don't repeat; build on them only if you say so)"]
        p += [f"- {t}" for t in taken[-25:]]
    p += ["", "## This round"]
    if focus:
        p.append(f"- **Focus:** {focus}")
    p += [f"- **Lens: {name}** ({lid}): {q}" for lid, name, q in drawn]
    if len(pair) == 2:
        p.append(f"- **Collision:** what happens when *{pair[0]}* meets *{pair[1]}*?")
    p.append(f"- **Constraint:** {constraint}")
    p += ["", "## Task",
          f"1. Diverge: sketch {count * 2} rough ideas, at least one per lens"
          + (" and one for the collision." if len(pair) == 2 else "."),
          f"2. Converge: keep the best {count}. Kill anything that fights a pillar, duplicates the board, "
          "or is only content with no new decision.",
          "3. For each keeper write: **title** (≤ 8 words), **pitch** (2 sentences: what the player does, "
          "why it's interesting), **hook** (the moment a player would remember), **pillar**, "
          "**first slice** (smallest testable version).",
          "4. File each one:",
          f'   `{cli} idea add "<title>" --pitch "<pitch + first slice>" --hook "<hook>" '
          '--pillar "<pillar>" --source dream --lens <lens ids>`',
          f"5. Optionally score them (`{cli} idea score`). Never approve: approval is the human's call."]
    return "\n".join(p)
