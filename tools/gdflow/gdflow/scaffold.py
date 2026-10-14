"""`gdflow init`: sets up governance in a new or existing project. Never overwrites a file."""
import datetime
import json
import os
import shutil

from . import config
from .config import Project, merged

TEMPLATES = os.path.join(os.path.dirname(os.path.abspath(__file__)), "templates")
TOOL_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def cli_command(root):
    """How this project invokes gdflow: the in-repo copy if there is one, else the installed command."""
    root = os.path.abspath(root)
    if TOOL_DIR.startswith(root + os.sep):
        return "python3 " + os.path.relpath(TOOL_DIR, root)
    return "gdflow" if shutil.which("gdflow") else "python3 " + TOOL_DIR


def fill(text, values):
    for k, v in values.items():
        text = text.replace("{" + k + "}", v)
    return text


def write_new(path, text, made):
    if os.path.exists(path):
        return
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
    made.append(path)


def init(root, name, overrides, claude=True, force=False):
    root = os.path.abspath(root)
    if os.path.exists(os.path.join(root, config.CONFIG_NAME)) and not force:
        raise SystemExit("gdflow: already initialised (gdflow.json exists); use --force to rewrite it")
    data = {"project": name, "cli": cli_command(root)}
    data.update({k: v for k, v in overrides.items() if v})
    project = Project(root, merged(data))
    config.save(root, project.data)
    values = {"project": name, "date": datetime.date.today().isoformat(),
              "design": project["design_dir"], "tasks": project["tasks_dir"], "cli": project["cli"]}
    made = []
    templ = {project["pillars"]["file"]: "PILLARS.md", project["plan"]["file"]: "PLAN.md",
             project["handoff"]["file"]: "HANDOFF.md", project["agent_rules"]: "AGENTS.md"}
    for rel, tname in templ.items():
        write_new(project.path(rel), fill(_tmpl(tname), values), made)
    os.makedirs(project.path(project["tasks_dir"]), exist_ok=True)
    from .decisions import HEADER
    write_new(project.design("DECISIONS.md"), HEADER, made)
    from .ideas import Store
    store = Store(project)
    if not os.path.exists(store.file):
        store.save()
        made += [store.file, project.design("IDEAS.md")]
    if claude:
        made += install_claude(project, values)
    return [os.path.relpath(p, root) for p in made]


def install_claude(project, values):
    made = []
    for skill in ("dream", "greenlight"):
        src = os.path.join(TEMPLATES, "skills", skill, "SKILL.md")
        dst = project.path(os.path.join(".claude", "skills", skill, "SKILL.md"))
        write_new(dst, fill(open(src, encoding="utf-8").read(), values), made)
    settings = project.path(os.path.join(".claude", "settings.json"))
    data = {}
    if os.path.exists(settings):
        with open(settings, encoding="utf-8") as f:
            data = json.load(f)
    hooks = data.setdefault("hooks", {}).setdefault("SessionStart", [])
    if not any("gdflow" in h.get("command", "") for e in hooks for h in e.get("hooks", [])):
        cmd = f'cd "$CLAUDE_PROJECT_DIR" && {values["cli"]} status --hook || true'
        hooks.append({"hooks": [{"type": "command", "command": cmd}]})
        os.makedirs(os.path.dirname(settings), exist_ok=True)
        with open(settings, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)
            f.write("\n")
        made.append(settings)
    claude_md = project.path("CLAUDE.md")
    text = open(claude_md, encoding="utf-8").read() if os.path.exists(claude_md) else f"# CLAUDE.md: {values['project']}\n"
    if "gdflow" not in text:
        with open(claude_md, "w", encoding="utf-8") as f:
            f.write(text.rstrip("\n") + "\n" + fill(_tmpl("CLAUDE_SNIPPET.md"), values))
        made.append(claude_md)
    return made


def _tmpl(name):
    with open(os.path.join(TEMPLATES, name), encoding="utf-8") as f:
        return f.read()
