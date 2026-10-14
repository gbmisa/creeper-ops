"""`gdflow status`: one screen (or, with --hook, a few lines) on where the project stands."""
from . import checks
from . import markdown as md
from .dream import plan_state
from .ideas import Store


def summary(project, hook=False):
    store = Store(project)
    stages, log = plan_state(project)
    out = [f"[gdflow] {project['project']}"]
    if stages:
        counts = {}
        for s in stages:
            counts[s["status"]] = counts.get(s["status"], 0) + 1
        out.append("plan: " + ", ".join(f"{v} {k}" for k, v in counts.items()))
        doing = [s for s in stages if s["status"] == "doing"]
        if counts.get("unverified", 0) > 3:
            out.append(f"  {counts['unverified']} stages are done but not human-verified: schedule a playtest")
        out += [f"  doing: {s['id']} {md.strip_md(s['name'])[:70]}" for s in doing[:3]]
    pipe = {}
    for i in store.ideas:
        pipe[i["status"]] = pipe.get(i["status"], 0) + 1
    if pipe:
        out.append("ideas: " + ", ".join(f"{v} {k}" for k, v in pipe.items()))
    for i in store.by_status("approved")[:3]:
        out.append(f"  next up: {i['id']} {i['title']} (prio {i['priority']})")
    waiting = store.by_status("scored")[:3]
    if waiting:
        out.append("  awaiting a human decision: " + ", ".join(i["id"] for i in waiting))
    built = store.by_status("built")
    if built:
        out.append("  built, needs human verification: " + ", ".join(i["id"] for i in built))
    if log and not hook:
        out.append("last change: " + log[0][:200])
    rep = checks.run(project)
    if rep.items:
        out.append(f"gate: {len(rep.errors)} error(s), {len(rep.items) - len(rep.errors)} warning(s)"
                   + (" (run `gdflow check`)" if hook else ""))
        if not hook:
            out += [f"  {lvl} [{rule}] {msg}" for lvl, rule, msg in rep.items]
    else:
        out.append("gate: clean")
    return "\n".join(out)
