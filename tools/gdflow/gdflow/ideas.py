"""Idea pipeline: the store (design/ideas.json), the state machine and scoring.

raw -> scored -> approved -> briefed -> built -> verified
Any open idea can be parked or rejected (with a reason). Only an approver may
approve or verify; that is the governance gate between dreaming and building.
"""
import datetime
import json
import os

STATES = ["raw", "scored", "approved", "briefed", "built", "verified", "parked", "rejected"]
MOVES = {
    "raw": {"scored", "parked", "rejected"},
    "scored": {"approved", "parked", "rejected", "scored"},
    "approved": {"briefed", "parked", "rejected"},
    "briefed": {"built", "approved", "rejected"},
    "built": {"verified", "briefed"},
    "verified": set(),
    "parked": {"raw", "rejected"},
    "rejected": {"raw"},
}
NEEDS_APPROVER = {"approved", "verified"}
NEEDS_REASON = {"parked", "rejected"}
SCORE_KEYS = ["fun", "fit", "novelty", "cost", "risk"]
SCORE_HELP = {
    "fun": "how much it adds to moment-to-moment play (1-5)",
    "fit": "how well it serves the pillars (1-5)",
    "novelty": "how fresh it feels for this genre (1-5)",
    "cost": "build effort, 1 = an afternoon, 5 = a phase (1-5)",
    "risk": "chance it breaks balance/scope/tech (1-5)",
}


def today():
    return datetime.date.today().isoformat()


def priority(s):
    """Value over effort: (2*fun + 2*fit + novelty) / (cost + risk). ~0.5 .. 12.5."""
    return round((2 * s["fun"] + 2 * s["fit"] + s["novelty"]) / (s["cost"] + s["risk"]), 2)


class Store:
    def __init__(self, project):
        self.project = project
        self.file = project.design("ideas.json")
        self.data = {"next": 1, "ideas": []}
        if os.path.exists(self.file):
            with open(self.file, encoding="utf-8") as f:
                self.data = json.load(f)

    @property
    def ideas(self):
        return self.data["ideas"]

    def get(self, iid):
        iid = normalize(iid)
        for idea in self.ideas:
            if idea["id"] == iid:
                return idea
        raise SystemExit(f"gdflow: no idea {iid}")

    def add(self, title, pitch="", pillar="", source="human", lenses=None, hook=""):
        key = title.strip().lower()
        for idea in self.ideas:
            if idea["title"].strip().lower() == key:
                raise SystemExit(f"gdflow: duplicate of {idea['id']} \"{idea['title']}\"")
        iid = "I-%03d" % self.data["next"]
        self.data["next"] += 1
        idea = {"id": iid, "title": title.strip(), "pitch": pitch.strip(), "hook": hook.strip(),
                "pillar": pillar.strip(), "source": source, "lenses": lenses or [],
                "status": "raw", "scores": None, "priority": None, "brief": None,
                "created": today(), "history": []}
        self.ideas.append(idea)
        return idea

    def score(self, iid, scores, by="agent"):
        idea = self.get(iid)
        for k in SCORE_KEYS:
            v = int(scores[k])
            if not 1 <= v <= 5:
                raise SystemExit(f"gdflow: {k} must be 1..5")
            scores[k] = v
        idea["scores"] = {k: scores[k] for k in SCORE_KEYS}
        idea["priority"] = priority(idea["scores"])
        if idea["status"] in ("raw", "scored"):
            self._log(idea, "scored", by, "scored")
            idea["status"] = "scored"
        return idea

    def move(self, iid, to, by, why=""):
        idea = self.get(iid)
        if to not in STATES:
            raise SystemExit(f"gdflow: unknown state {to}; one of {', '.join(STATES)}")
        if to not in MOVES[idea["status"]]:
            raise SystemExit(f"gdflow: {idea['id']} is {idea['status']}; can't move to {to} "
                             f"(allowed: {', '.join(sorted(MOVES[idea['status']])) or 'none'})")
        if to in NEEDS_APPROVER and by not in self.project["approvers"]:
            raise SystemExit(f"gdflow: only an approver ({', '.join(self.project['approvers'])}) "
                             f"may move an idea to {to}. Ask them first.")
        if to in NEEDS_REASON and not why:
            raise SystemExit(f"gdflow: moving to {to} needs --why")
        if to == "approved" and not idea["scores"]:
            raise SystemExit("gdflow: score an idea before approving it")
        self._log(idea, to, by, why)
        idea["status"] = to
        return idea

    def _log(self, idea, to, by, why):
        idea["history"].append({"at": today(), "from": idea["status"], "to": to,
                                "by": by, "why": why})

    def save(self):
        os.makedirs(os.path.dirname(self.file), exist_ok=True)
        with open(self.file, "w", encoding="utf-8") as f:
            json.dump(self.data, f, indent=2, ensure_ascii=False)
            f.write("\n")
        from .board import render
        render(self.project, self.ideas)

    def by_status(self, *states):
        out = [i for i in self.ideas if i["status"] in states]
        return sorted(out, key=lambda i: -(i["priority"] or 0))


def normalize(iid):
    """Accepts I-007, i7, 7 or 007."""
    s = str(iid).upper().strip().lstrip("I").lstrip("-")
    return "I-%03d" % int(s) if s.isdigit() else str(iid).upper().strip()
