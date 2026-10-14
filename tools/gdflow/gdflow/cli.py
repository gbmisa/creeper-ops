"""Command line: `gdflow <command>`. Run `gdflow -h` for the list."""
import argparse
import os
import sys

from . import brief, checks, config, decisions, dream, scaffold, status
from .ideas import SCORE_HELP, SCORE_KEYS, STATES, Store
from .lenses import CONSTRAINTS, LENSES


def build_parser():
    p = argparse.ArgumentParser(prog="gdflow", description="Lightweight, governed game-design flow.")
    p.add_argument("-C", dest="cwd", default=".", help="project directory (default: here)")
    sub = p.add_subparsers(dest="cmd", required=True)

    s = sub.add_parser("init", help="set up gdflow in a project (never overwrites files)")
    s.add_argument("--name", required=True)
    for opt in ("design-dir", "pillars-file", "pillars-section", "plan-file", "handoff",
                "tasks-dir", "agent-rules", "playtest-dir"):
        s.add_argument("--" + opt)
    s.add_argument("--no-claude", action="store_true", help="skip skills, hook and CLAUDE.md snippet")
    s.add_argument("--force", action="store_true")

    sub.add_parser("status", help="where the project stands").add_argument("--hook", action="store_true")
    s = sub.add_parser("check", help="governance gate (exit 1 on errors)")
    s.add_argument("--run", action="store_true", help="also run the project's check commands")

    s = sub.add_parser("dream", help="print an ideation packet for the agent")
    s.add_argument("--count", type=int, default=5)
    s.add_argument("--lenses", type=int, default=3)
    s.add_argument("--lens", nargs="*", default=[], help="force lens ids")
    s.add_argument("--focus", default="")
    s.add_argument("--seed", type=int)
    sub.add_parser("lenses", help="list the lens deck and constraints")

    idea = sub.add_parser("idea", help="the idea pipeline").add_subparsers(dest="icmd", required=True)
    s = idea.add_parser("add")
    s.add_argument("title")
    for opt in ("pitch", "hook", "pillar"):
        s.add_argument("--" + opt, default="")
    s.add_argument("--source", default="human", help="human, dream, playtest, agent")
    s.add_argument("--lens", nargs="*", default=[])
    s = idea.add_parser("list")
    s.add_argument("--status", nargs="*", choices=STATES)
    idea.add_parser("show").add_argument("id")
    s = idea.add_parser("score")
    s.add_argument("id")
    for k in SCORE_KEYS:
        s.add_argument("--" + k, type=int, required=True, help=SCORE_HELP[k])
    s.add_argument("--by", default="agent")
    s = idea.add_parser("move")
    s.add_argument("id")
    s.add_argument("to", choices=STATES)
    s.add_argument("--by", default="agent")
    s.add_argument("--why", default="")

    s = sub.add_parser("brief", help="write a task brief for an approved idea")
    s.add_argument("id")
    s.add_argument("--model", default="")
    s.add_argument("--branch", default="")
    s.add_argument("--read", default="", help="extra files the agent may read")

    s = sub.add_parser("decide", help="append a decision to DECISIONS.md")
    s.add_argument("title")
    s.add_argument("--why", required=True)
    s.add_argument("--by", required=True)
    s.add_argument("--idea", default="")
    s.add_argument("--supersedes", default="")
    return p


def main(argv=None):
    a = build_parser().parse_args(argv)
    if a.cmd == "init":
        o = {"design_dir": a.design_dir, "handoff": {"file": a.handoff} if a.handoff else None,
             "tasks_dir": a.tasks_dir, "agent_rules": a.agent_rules, "playtest_dir": a.playtest_dir,
             "plan": {"file": a.plan_file} if a.plan_file else None}
        if a.pillars_file or a.pillars_section:
            o["pillars"] = {k: v for k, v in (("file", a.pillars_file), ("section", a.pillars_section)) if v}
        if a.design_dir:  # keep default design files inside the chosen design dir
            for key, name in (("pillars", "PILLARS.md"), ("plan", "PLAN.md")):
                o[key] = o.get(key) or {}
                o[key].setdefault("file", os.path.join(a.design_dir, name))
            o["tasks_dir"] = o["tasks_dir"] or os.path.join(a.design_dir, "tasks")
            o["playtest_dir"] = o["playtest_dir"] or os.path.join(a.design_dir, "playtests")
        made = scaffold.init(a.cwd, a.name, o, claude=not a.no_claude, force=a.force)
        print("gdflow: initialised. Created:" if made else "gdflow: initialised (nothing new to create).")
        print("\n".join("  " + m for m in made))
        print("Next: fill in the pillars, then `gdflow dream` (or /dream in Claude Code).")
        return 0
    if a.cmd == "lenses":
        for lid, name, q in LENSES:
            print(f"{lid:14} {name}: {q}")
        print("\nConstraints:\n" + "\n".join("  - " + c for c in CONSTRAINTS))
        return 0
    project = config.load(a.cwd)
    if a.cmd == "status":
        print(status.summary(project, hook=a.hook))
    elif a.cmd == "check":
        rep = checks.run(project, run_commands=a.run)
        for lvl, rule, msg in rep.items:
            print(f"{lvl:5} [{rule}] {msg}")
        print(f"gdflow check: {len(rep.errors)} error(s), {len(rep.items) - len(rep.errors)} warning(s)")
        return 1 if rep.errors else 0
    elif a.cmd == "dream":
        print(dream.packet(project, a.count, a.lenses, a.lens, a.focus, a.seed))
    elif a.cmd == "idea":
        return idea_cmd(project, a)
    elif a.cmd == "brief":
        print("gdflow: wrote " + brief.make(project, a.id, a.model, a.branch, a.read)
              + ". Fill in its TODO Scope and Acceptance before handing it out.")
    elif a.cmd == "decide":
        print("gdflow: recorded " + decisions.add(project, a.title, a.why, a.by, a.idea, a.supersedes))
    return 0


def idea_cmd(project, a):
    store = Store(project)
    if a.icmd == "add":
        i = store.add(a.title, a.pitch, a.pillar, a.source, a.lens, a.hook)
        print(f"gdflow: added {i['id']} {i['title']}")
    elif a.icmd == "list":
        rows = store.by_status(*(a.status or STATES))
        for i in rows:
            print(f"{i['id']}  {i['status']:9} {str(i['priority'] or '-'):>5}  {i['title']}")
        if not rows:
            print("(no ideas)")
        return 0
    elif a.icmd == "show":
        i = store.get(a.id)
        for k in ("id", "title", "status", "pillar", "pitch", "hook", "source", "lenses",
                  "scores", "priority", "brief", "created"):
            print(f"{k:9} {i[k]}")
        for h in i["history"]:
            print(f"  {h['at']} {h['from']} -> {h['to']} by {h['by']}" + (f": {h['why']}" if h["why"] else ""))
        return 0
    elif a.icmd == "score":
        i = store.score(a.id, {k: getattr(a, k) for k in SCORE_KEYS}, a.by)
        print(f"gdflow: {i['id']} priority {i['priority']}")
    elif a.icmd == "move":
        i = store.move(a.id, a.to, a.by, a.why)
        print(f"gdflow: {i['id']} is now {i['status']}")
    store.save()
    return 0


if __name__ == "__main__":
    sys.exit(main())
