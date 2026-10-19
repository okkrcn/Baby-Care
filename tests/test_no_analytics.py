"""The support site must not load the deselected visitor counter or its consent UI."""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class DeselectedAnalyticsTests(unittest.TestCase):
    def test_public_pages_do_not_load_counter_or_permission_ui(self):
        for name in ("index.html", "privacy.html"):
            with self.subTest(page=name):
                html = (ROOT / name).read_text()
                self.assertNotIn('src="moskai-visitor.js"', html)
                self.assertNotIn('href="moskai-consent.css"', html)
                self.assertNotIn("moskai_visit_consent_v1", html)
        self.assertFalse((ROOT / "moskai-visitor.js").exists())
        self.assertFalse((ROOT / "moskai-consent.css").exists())

    def test_privacy_copy_describes_current_non_tracking_site(self):
        text = (ROOT / "privacy.html").read_text()
        self.assertIn("Bu destek sitesinde ziyaretçi analitiği kapalıdır.", text)
        self.assertNotIn("“Ölçüm tercihi”", text)


if __name__ == "__main__":
    unittest.main()
