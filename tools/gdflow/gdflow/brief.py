"""`gdflow brief <id>`: turns an approved idea into a task brief for a delegated agent."""
import os
import re

from .ideas import Store

TEMPLATE = """# Brief {iid}: {title}

<!-- gdflow:{iid} -->
**Idea:** {iid} on the [idea board]({board}). **Pillar:** {pillar}. **Priority:** {prio}
**Branch:** `{branch}` (from the default branch). **Model:** {model}
**Read only:** {rules}, this brief{read}. Don't read whole design docs.

## Why
{pitch}

**Player moment we want:** {hook}

## Scope
Do:
1. TODO (orchestrator): the smallest slice that delivers the moment above.

Must not change:
- Anything outside the files you need for the slice. List other ideas as suggestions.

## Acceptance
- TODO (orchestrator): the observable result that proves the moment exists.
- New tunables live in the project's config/data tables, not in logic.

## Verify
{verify}

## Report
Stop and report in the {rules} format: **Done** (files, commits), **Verified** (exact check output),
**Not done / unsure**, **Suggestions** (not implemented). Never merge.
"""


def slug(s):
    return re.sub(r"[^A-Za-z0-9]+", "_", s).strip("_")[:40]


def make(project, iid, model="", branch="", read=""):
    store = Store(project)
    idea = store.get(iid)
    if idea["status"] != "approved":
        raise SystemExit(f"gdflow: {idea['id']} is {idea['status']}; only approved ideas get a brief")
    rel = os.path.join(project["tasks_dir"], f"{idea['id'].replace('-', '')}_{slug(idea['title'])}.md")
    path = project.path(rel)
    if os.path.exists(path):
        raise SystemExit(f"gdflow: {rel} already exists")
    checks = project["checks"]
    verify = "\n".join(f"{n}. {c['name']}: `{c['cmd']}`" for n, c in enumerate(checks, 1)) \
        or "1. TODO: name the project's parse/test/sim commands in gdflow.json `checks`."
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(TEMPLATE.format(
            iid=idea["id"], title=idea["title"], pillar=idea["pillar"] or "-",
            prio=idea["priority"], board=os.path.relpath(project.design("IDEAS.md"), os.path.dirname(path)),
            branch=branch or f"idea/{idea['id'].lower()}-{slug(idea['title']).lower()[:24]}",
            model=model or "TODO (cheapest agent that can do it)", rules=project["agent_rules"],
            read=(", " + read) if read else "", pitch=idea["pitch"] or "-",
            hook=idea["hook"] or "-", verify=verify))
    idea["brief"] = rel
    store.move(idea["id"], "briefed", by="gdflow", why=rel)
    store.save()
    return rel
