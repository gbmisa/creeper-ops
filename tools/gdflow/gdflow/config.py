"""Project config: `gdflow.json` at the project root. Every path in it is root-relative."""
import json
import os

CONFIG_NAME = "gdflow.json"

DEFAULTS = {
    "project": "Untitled Game",
    "cli": "gdflow",
    "design_dir": "design",
    "pillars": {"file": "design/PILLARS.md", "section": "Pillars"},
    "plan": {"file": "design/PLAN.md", "changelog_section": "Changelog"},
    "handoff": {"file": "HANDOFF.md", "max_lines": 60, "max_age_days": 7},
    "tasks_dir": "design/tasks",
    "agent_rules": "AGENTS.md",
    "playtest_dir": "design/playtests",
    "systems": [],
    "line_limit": {"globs": [], "max": 250, "allow": []},
    "checks": [],
    "approvers": ["human"],
}


class Project:
    """A loaded project: root path + merged config + path helpers."""

    def __init__(self, root, data):
        self.root = root
        self.data = data

    def __getitem__(self, key):
        return self.data[key]

    def get(self, key, default=None):
        return self.data.get(key, default)

    def path(self, rel):
        return os.path.join(self.root, rel)

    def design(self, *parts):
        return os.path.join(self.root, self.data["design_dir"], *parts)

    def read(self, rel):
        p = self.path(rel)
        if not os.path.exists(p):
            return ""
        with open(p, encoding="utf-8") as f:
            return f.read()


def merged(data):
    out = json.loads(json.dumps(DEFAULTS))
    for k, v in data.items():
        if isinstance(v, dict) and isinstance(out.get(k), dict):
            out[k].update(v)
        else:
            out[k] = v
    return out


def find_root(start):
    cur = os.path.abspath(start)
    while True:
        if os.path.exists(os.path.join(cur, CONFIG_NAME)):
            return cur
        parent = os.path.dirname(cur)
        if parent == cur:
            return None
        cur = parent


def load(start="."):
    root = find_root(start)
    if root is None:
        raise SystemExit(f"gdflow: no {CONFIG_NAME} found from {os.path.abspath(start)} upward. "
                         "Run `gdflow init` in the project root.")
    with open(os.path.join(root, CONFIG_NAME), encoding="utf-8") as f:
        return Project(root, merged(json.load(f)))


def save(root, data):
    with open(os.path.join(root, CONFIG_NAME), "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
