"""Run: python3 -m unittest discover -s tools/gdflow/tests"""
import contextlib
import io
import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from gdflow import cli, config, markdown  # noqa: E402
from gdflow.ideas import Store, normalize, priority  # noqa: E402


def run(root, *args):
    out = io.StringIO()
    with contextlib.redirect_stdout(out):
        code = cli.main(["-C", root, *args])
    return code, out.getvalue()


class FlowTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = self.tmp.name
        run(self.root, "init", "--name", "T", "--design-dir", "design")

    def tearDown(self):
        self.tmp.cleanup()

    def fill_pillars(self):
        p = os.path.join(self.root, "design", "PILLARS.md")
        text = open(p).read().replace("TODO pillar", "Real pillar")
        open(p, "w").write(text)

    def test_init_never_overwrites(self):
        p = os.path.join(self.root, "AGENTS.md")
        open(p, "w").write("mine")
        run(self.root, "init", "--name", "T", "--force")
        self.assertEqual(open(p).read(), "mine")

    def test_unfilled_charter_fails_gate(self):
        self.assertEqual(run(self.root, "check")[0], 1)
        self.fill_pillars()
        self.assertEqual(run(self.root, "check")[0], 0)

    def test_pipeline_and_governance(self):
        self.fill_pillars()
        run(self.root, "idea", "add", "Bet the wave", "--pitch", "p", "--source", "dream")
        with self.assertRaises(SystemExit):  # unscored
            run(self.root, "idea", "move", "1", "approved", "--by", "human")
        run(self.root, "idea", "score", "1", "--fun", "4", "--fit", "5", "--novelty", "3",
            "--cost", "2", "--risk", "3")
        with self.assertRaises(SystemExit):  # agents can't approve
            run(self.root, "idea", "move", "1", "approved", "--by", "agent")
        with self.assertRaises(SystemExit):  # not approved yet
            run(self.root, "brief", "1")
        run(self.root, "idea", "move", "1", "approved", "--by", "human")
        code, out = run(self.root, "brief", "1")
        self.assertIn("I001_Bet_the_wave.md", out)
        idea = Store(config.load(self.root)).get("I-001")
        self.assertEqual(idea["status"], "briefed")
        self.assertIn("still has TODOs", run(self.root, "check")[1])
        with self.assertRaises(SystemExit):  # reject needs a reason
            run(self.root, "idea", "move", "1", "rejected")

    def test_duplicate_titles_refused(self):
        run(self.root, "idea", "add", "Same")
        with self.assertRaises(SystemExit):
            run(self.root, "idea", "add", "same ")

    def test_dream_packet_has_lenses_and_constraint(self):
        self.fill_pillars()
        out = run(self.root, "dream", "--seed", "1", "--lens", "reverse", "--focus", "enemies")[1]
        self.assertIn("Lens: Reverse", out)
        self.assertIn("**Constraint:**", out)
        self.assertIn("Focus:** enemies", out)
        self.assertIn("Real pillar", out)

    def test_decisions_numbered(self):
        run(self.root, "decide", "A", "--why", "x", "--by", "human")
        _, out = run(self.root, "decide", "B", "--why", "y", "--by", "human")
        self.assertIn("D-002", out)


class UnitTest(unittest.TestCase):
    def test_normalize(self):
        for s in ("7", "i7", "I-007", "007"):
            self.assertEqual(normalize(s), "I-007")

    def test_priority(self):
        self.assertEqual(priority({"fun": 5, "fit": 5, "novelty": 5, "cost": 1, "risk": 1}), 12.5)

    def test_plan_stages(self):
        rows = markdown.plan_stages("| # | S | M | Status |\n|---|---|---|---|\n| 1 | [A](x) | m | ⚠ ok |\n")
        self.assertEqual(rows, [{"id": "1", "name": "A", "status": "unverified", "note": "ok"}])

    def test_section_and_bullets(self):
        text = "# T\n### Pillars\n- **One.** a\n  wrapped\n- Two\n### Next\n- no"
        self.assertEqual(markdown.bullets(markdown.section(text, "pillars")), ["**One.** a wrapped", "Two"])


if __name__ == "__main__":
    unittest.main()
