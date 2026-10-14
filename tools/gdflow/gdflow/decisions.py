"""`gdflow decide`: an append-only decision log (design/DECISIONS.md), numbered D-001..."""
import os
import re

from .ideas import today

HEADER = ("# Decisions\n\nAppend-only. Each entry records what was settled, why, and who decided. "
          "Reverse a decision with a new entry that names the old one.\n")


def add(project, title, why, by, idea="", supersedes=""):
    path = project.design("DECISIONS.md")
    text = open(path, encoding="utf-8").read() if os.path.exists(path) else HEADER
    n = max([int(m) for m in re.findall(r"^## D-(\d+)", text, re.M)] or [0]) + 1
    did = "D-%03d" % n
    entry = [f"\n## {did} ({today()}): {title}", f"- **Why:** {why}", f"- **By:** {by}"]
    if idea:
        entry.append(f"- **Idea:** {idea}")
    if supersedes:
        entry.append(f"- **Supersedes:** {supersedes}")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text.rstrip("\n") + "\n" + "\n".join(entry) + "\n")
    return did
