"""`gdflow check`: the governance gate. Errors exit 1 (usable in hooks and CI).

Built-in rules are cheap file reads. Project commands (parse, smoke, sims) run
only with `--run`, so the gate stays fast by default.
"""
import datetime
import glob
import os
import subprocess

from . import markdown as md
from .dream import pillars
from .ideas import Store


class Report:
    def __init__(self):
        self.items = []

    def error(self, rule, msg):
        self.items.append(("ERROR", rule, msg))

    def warn(self, rule, msg):
        self.items.append(("WARN", rule, msg))

    @property
    def errors(self):
        return [i for i in self.items if i[0] == "ERROR"]


def run(project, run_commands=False):
    r = Report()
    check_charter(project, r)
    check_handoff(project, r)
    check_ideas(project, r)
    check_briefs(project, r)
    check_line_limit(project, r)
    if run_commands:
        check_commands(project, r)
    return r


def check_charter(project, r):
    p = [x for x in pillars(project) if "TODO" not in x]
    if len(pillars(project)) > len(p):
        r.error("charter", f"pillars still have TODO placeholders in {project['pillars']['file']}")
    if not p:
        r.error("charter", f"no pillars under '{project['pillars']['section']}' in {project['pillars']['file']}")
    elif len(p) > 5:
        r.warn("charter", f"{len(p)} pillars; 2-4 keep ideas focused")
    for rel in (project["plan"]["file"], project["agent_rules"]):
        if not os.path.exists(project.path(rel)):
            r.error("charter", f"missing {rel}")


def check_handoff(project, r):
    cfg = project["handoff"]
    text = project.read(cfg["file"])
    if not text:
        r.warn("handoff", f"no {cfg['file']} yet")
        return
    n = len(text.splitlines())
    if n > cfg["max_lines"]:
        r.warn("handoff", f"{cfg['file']} is {n} lines (limit {cfg['max_lines']}); trim it")
    d = md.first_date(text)
    if d:
        age = (datetime.date.today() - datetime.date.fromisoformat(d)).days
        if age > cfg["max_age_days"]:
            r.warn("handoff", f"{cfg['file']} dated {d} ({age} days old)")


def check_ideas(project, r):
    store = Store(project)
    approvers = set(project["approvers"])
    for i in store.ideas:
        for h in i["history"]:
            if h["to"] in ("approved", "verified") and h["by"] not in approvers:
                r.error("ideas", f"{i['id']} was {h['to']} by '{h['by']}', not an approver")
        if i["status"] in ("briefed", "built") and not (i["brief"] and os.path.exists(project.path(i["brief"]))):
            r.error("ideas", f"{i['id']} is {i['status']} but its brief is missing")
        if i["status"] == "approved" and i["history"][-1]["at"] < _days_ago(14):
            r.warn("ideas", f"{i['id']} approved over 14 days ago and not briefed")
    stale = [i["id"] for i in store.ideas if i["status"] == "raw" and i["created"] < _days_ago(14)]
    if stale:
        r.warn("ideas", f"{len(stale)} raw ideas older than 14 days: score, park or reject them")


def check_briefs(project, r):
    d = project.path(project["tasks_dir"])
    if not os.path.isdir(d):
        return
    for f in glob.glob(os.path.join(d, "*.md")):
        text = open(f, encoding="utf-8").read()
        if "gdflow:" not in text:
            continue  # only gdflow briefs carry the required sections
        rel = os.path.relpath(f, project.root)
        for need in ("## Acceptance", "## Verify", "## Report"):
            if need not in text:
                r.error("briefs", f"{rel} lacks '{need}'")
        if "TODO" in text:
            r.warn("briefs", f"{rel} still has TODOs; finish it before handing it out")


def check_line_limit(project, r):
    cfg = project["line_limit"]
    allow = set(cfg.get("allow", []))
    over = []
    for g in cfg["globs"]:
        for f in glob.glob(project.path(g), recursive=True):
            rel = os.path.relpath(f, project.root)
            if rel in allow:
                continue
            with open(f, encoding="utf-8", errors="ignore") as fh:
                n = sum(1 for _ in fh)
            if n > cfg["max"]:
                over.append((n, rel))
    for n, rel in sorted(over, reverse=True)[:8]:
        r.warn("size", f"{rel}: {n} lines (limit {cfg['max']}); split by responsibility")
    if len(over) > 8:
        r.warn("size", f"...and {len(over) - 8} more over the limit")


def check_commands(project, r):
    for c in project["checks"]:
        try:
            res = subprocess.run(c["cmd"], shell=True, cwd=project.root, capture_output=True,
                                 text=True, timeout=c.get("timeout", 600))
        except subprocess.TimeoutExpired:
            r.error("cmd", f"{c['name']}: timed out")
            continue
        out = (res.stdout + res.stderr).strip().splitlines()
        bad = res.returncode != 0 or any(c.get("fail_if", "\0") in l for l in out)
        if bad:
            r.error("cmd", f"{c['name']}: failed ({'; '.join(out[-3:])[:300]})")


def _days_ago(n):
    return (datetime.date.today() - datetime.timedelta(days=n)).isoformat()
