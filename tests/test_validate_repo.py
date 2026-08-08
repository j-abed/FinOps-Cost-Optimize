import tempfile
import unittest
from pathlib import Path

from scripts.validate_repo import load_jsonc, strip_json_comments


class JsonCommentTests(unittest.TestCase):
    def test_strips_comments_without_changing_strings(self) -> None:
        content = '''{
            // A line comment
            "schema": "https://example.test/schema.json",
            "value": "text // retained",
            /* A block comment */
            "enabled": true
        }'''

        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "template.json"
            path.write_text(content)

            parsed = load_jsonc(path)

        self.assertEqual(parsed["schema"], "https://example.test/schema.json")
        self.assertEqual(parsed["value"], "text // retained")
        self.assertTrue(parsed["enabled"])

    def test_rejects_unterminated_block_comment(self) -> None:
        with self.assertRaisesRegex(ValueError, "Unterminated JSON block comment"):
            strip_json_comments('{"value": true /* missing terminator')


if __name__ == "__main__":
    unittest.main()