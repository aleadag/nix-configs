import ctypes
import json
import os
import shlex
import subprocess
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET
from datetime import datetime, timedelta, timezone
from pathlib import Path

COMMAND = shlex.split(sys.argv.pop(1))
PANGO = ctypes.CDLL(sys.argv.pop(1))
PANGO.pango_parse_markup.argtypes = [
    ctypes.c_char_p,
    ctypes.c_int,
    ctypes.c_uint32,
    ctypes.c_void_p,
    ctypes.c_void_p,
    ctypes.c_void_p,
    ctypes.c_void_p,
]
PANGO.pango_parse_markup.restype = ctypes.c_int


class QuotaDisplayTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.state = Path(self.temp.name)
        self.quota = self.state / "agent-steward/quota"
        self.quota.mkdir(parents=True)
        self.now = datetime.now(timezone.utc)

    def window(self, percent, **extra):
        return {
            "scope": {"type": "account"},
            "id": "5h",
            "remaining_percent": percent,
            "observed_at": (self.now - timedelta(minutes=10)).isoformat(),
            "reset_at": (self.now + timedelta(hours=3)).isoformat(),
            "valid_until": (self.now + timedelta(minutes=40)).isoformat(),
            **extra,
        }

    def write(self, bucket, windows, **extra):
        (self.quota / (bucket + ".json")).write_text(
            json.dumps(
                {
                    "schema_version": 1,
                    "source": bucket,
                    "identity_fingerprint": "a" * 64,
                    "windows": windows,
                    **extra,
                }
            )
        )

    def display(self, **env):
        result = subprocess.run(
            COMMAND,
            env={**os.environ, "XDG_STATE_HOME": str(self.state), **env},
            capture_output=True,
            text=True,
            check=True,
        )
        self.assertEqual(result.stderr, "")
        output = json.loads(result.stdout)
        self.assertTrue(
            PANGO.pango_parse_markup(
                output["tooltip"].encode(), -1, 0, None, None, None, None
            ),
            "Tooltip must be valid Pango markup",
        )
        return output

    def test_missing_snapshots_are_unknown(self):
        output = self.display()
        self.assertEqual(output["text"], "Codex ? · xAI ? · Gemini ?")
        self.assertEqual(output.get("class"), "unknown")

    def test_lowest_applicable_limit_and_tooltip(self):
        self.write("pi_codex", [self.window(65), self.window(42, id="weekly")])
        self.write("pi_xai", [self.window(90)])
        self.write(
            "antigravity",
            [
                self.window(80, scope={"type": "pool", "pool_id": "gemini"}),
                self.window(1, scope={"type": "pool", "pool_id": "third_party"}),
            ],
        )
        output = self.display()
        self.assertEqual(output["text"], "Codex 42% · xAI 90% · Gemini 80%")
        self.assertIn("weekly: 42%", output["tooltip"])
        self.assertIn("reset", output["tooltip"])
        self.assertIn("10m ago", output["tooltip"])
        self.assertNotIn("third_party", output["tooltip"])

    def test_visual_tooltip_has_headings_and_proportional_meters(self):
        for percent, meter in [
            (0, "▱▱▱▱▱▱▱▱▱▱"),
            (65, "▰▰▰▰▰▰▱▱▱▱"),
            (100, "▰▰▰▰▰▰▰▰▰▰"),
        ]:
            with self.subTest(percent=percent):
                self.write("pi_codex", [self.window(percent)])
                output = self.display()
                self.assertIn(f"<b>Codex · {percent}%</b>", output["tooltip"])
                self.assertIn(f"<tt>{meter}</tt>", output["tooltip"])
                self.assertIn("<small>reset ", output["tooltip"])
                self.assertIn(f"Codex {percent}%", output["text"])
                self.assertNotIn("<", output["text"])

    def test_quota_state_classes_and_thresholds(self):
        for percent, expected in [
            (20, "healthy"),
            (19, "warning"),
            (10, "warning"),
            (9, "critical"),
        ]:
            with self.subTest(percent=percent):
                self.write("pi_codex", [self.window(percent)])
                self.write("pi_xai", [self.window(80)])
                self.write(
                    "antigravity",
                    [self.window(80, scope={"type": "pool", "pool_id": "gemini"})],
                )
                self.assertEqual(self.display().get("class"), expected)
        (self.quota / "antigravity.json").unlink()
        self.assertEqual(self.display().get("class"), "critical")
        self.write("pi_codex", [self.window(50)])
        self.assertEqual(self.display().get("class"), "unknown")

    def test_stale_tooltip_does_not_render_a_quota_meter(self):
        self.write("pi_codex", [self.window(65, valid_until=self.now.isoformat())])
        output = self.display()
        self.assertIn("<b>Codex · ?</b>", output["tooltip"])
        self.assertIn("? (stale)", output["tooltip"])
        self.assertNotIn("▰", output["tooltip"])
        self.assertNotIn("▱", output["tooltip"])
        self.assertEqual(output.get("class"), "unknown")

    def test_reset_tooltip_uses_relative_time(self):
        cases = [
            (timedelta(minutes=5, seconds=30), "reset in 5m"),
            (timedelta(hours=2, minutes=15, seconds=30), "reset in 2h 15m"),
            (timedelta(days=3, hours=4, minutes=15), "reset in 3d 4h"),
            (timedelta(seconds=30), "reset in &lt;1m"),
            (-timedelta(minutes=5, seconds=30), "reset 5m ago"),
            (-timedelta(seconds=30), "reset &lt;1m ago"),
        ]
        for delta, expected in cases:
            with self.subTest(expected=expected):
                reset = (self.now + delta).astimezone(timezone(timedelta(hours=8)))
                self.write("pi_codex", [self.window(65, reset_at=reset.isoformat())])
                output = self.display()
                self.assertIn(expected + "; observed 10m ago", output["tooltip"])
                self.assertNotIn(reset.isoformat(), output["tooltip"])
                self.assertIn(
                    "Codex ?" if delta.total_seconds() < 0 else "Codex 65%",
                    output["text"],
                )

    def test_stale_future_reset_and_malformed_data_withhold_percentages(self):
        mutations = [
            {"valid_until": (self.now - timedelta(seconds=1)).isoformat()},
            {"reset_at": (self.now - timedelta(seconds=1)).isoformat()},
            {"observed_at": (self.now + timedelta(minutes=1)).isoformat()},
            {"remaining_percent": 101},
            {"remaining_percent": True},
            {"remaining_percent": "80"},
            {"valid_until": "invalid"},
            {"observed_at": self.now.replace(tzinfo=None).isoformat()},
        ]
        for mutation in mutations:
            with self.subTest(mutation=mutation):
                self.write("pi_codex", [self.window(80, **mutation)])
                self.assertIn("Codex ?", self.display()["text"])
        for mutation in [
            {"source": "codex"},
            {"identity_fingerprint": ""},
            {"schema_version": 2},
        ]:
            self.write("pi_codex", [self.window(80)], **mutation)
            self.assertIn("Codex ?", self.display()["text"])
        for raw in ["not json", "[]", '{"windows":null}']:
            (self.quota / "pi_codex.json").write_text(raw)
            self.assertIn("Codex ?", self.display()["text"])

    def test_one_stale_limit_makes_pool_unknown(self):
        self.write(
            "pi_codex",
            [self.window(65), self.window(42, valid_until=self.now.isoformat())],
        )
        self.assertIn("Codex ?", self.display()["text"])

    def test_tooltip_escapes_markup(self):
        self.write("pi_codex", [self.window(65, id="<b>&")])
        output = self.display()
        self.assertIn("&lt;b&gt;&amp;", output["tooltip"])
        markup = ET.fromstring("<markup>" + output["tooltip"] + "</markup>")
        self.assertIn("<b>&: 65%", [node.text for node in markup.findall("b")])

    def test_empty_xdg_state_uses_home(self):
        home = self.state / "home"
        quota = home / ".local/state/agent-steward/quota"
        quota.mkdir(parents=True)
        self.write("pi_xai", [self.window(75)])
        (self.quota / "pi_xai.json").rename(quota / "pi_xai.json")
        self.assertIn(
            "xAI 75%", self.display(HOME=str(home), XDG_STATE_HOME="")["text"]
        )


unittest.main()
