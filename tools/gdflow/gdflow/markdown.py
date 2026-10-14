"""Tiny markdown readers: sections, bullet lists, status tables. No dependencies."""
import re

STATUS_MARKS = {"☐": "todo", "◐": "doing", "☑": "done", "⚠": "unverified"}


def section(text, name):
    """Body of the first heading whose title contains `name` (case-insensitive)."""
    lines = text.splitlines()
    start, level = None, 0
    for i, line in enumerate(lines):
        m = re.match(r"^(#+)\s+(.*)$", line)
        if not m:
            continue
        if start is None and name.lower() in m.group(2).lower():
            start, level = i + 1, len(m.group(1))
        elif start is not None and len(m.group(1)) <= level:
            return "\n".join(lines[start:i]).strip()
    return "\n".join(lines[start:]).strip() if start is not None else ""


def bullets(text):
    """Top-level bullet items (with wrapped continuation lines joined)."""
    items = []
    for line in text.splitlines():
        if re.match(r"^[-*]\s+", line):
            items.append(re.sub(r"^[-*]\s+", "", line).strip())
        elif items and line.startswith("  ") and line.strip():
            items[-1] += " " + line.strip()
    return items


def plan_stages(text):
    """Rows of `| id | name | ... | status |` tables whose last cell starts with a status mark."""
    rows = []
    for line in text.splitlines():
        if not line.startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 3 or not cells[-1]:
            continue
        mark = cells[-1][0]
        if mark in STATUS_MARKS:
            rows.append({"id": cells[0], "name": strip_md(cells[1]),
                         "status": STATUS_MARKS[mark], "note": cells[-1][1:].strip()})
    return rows


def strip_md(s):
    s = re.sub(r"\[([^\]]+)\]\([^)]*\)", r"\1", s)
    return re.sub(r"[*_`]", "", s).strip()


def first_date(text):
    m = re.search(r"(\d{4}-\d{2}-\d{2})", text)
    return m.group(1) if m else None
