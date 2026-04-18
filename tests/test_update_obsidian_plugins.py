import importlib.util
import pathlib
import sys
import unittest


def load_module():
    module_path = (
        pathlib.Path(__file__).resolve().parents[1]
        / "scripts"
        / "update-obsidian-plugins.py"
    )
    spec = importlib.util.spec_from_file_location(
        "update_obsidian_plugins", module_path
    )
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


SAMPLE = """{
  heatmap-calendar = mkObsidianPlugin {
    pname = "heatmap-calendar";
    version = "0.7.1";
    owner = "Richardsl";
    repo = "heatmap-calendar-obsidian";
    hashMainJs = "sha256-old-main";
    hashManifestJson = "sha256-old-manifest";
    hashStylesCss = "sha256-old-styles";
  };

  templater = pkgs.fetchzip {
    url = "https://github.com/SilentVoid13/Templater/releases/download/2.18.1/templater-obsidian.zip";
    name = "templater-obsidian";
    stripRoot = false;
    hash = "sha256-old-zip";
  };
}
"""


class UpdateObsidianPluginsTest(unittest.TestCase):
    def test_parse_plugins_detects_supported_blocks(self):
        module = load_module()

        plugins = module.parse_plugins(SAMPLE)

        self.assertEqual(
            [plugin.attr_name for plugin in plugins], ["heatmap-calendar", "templater"]
        )
        self.assertEqual(plugins[0].kind, "mk")
        self.assertEqual(plugins[0].version, "0.7.1")
        self.assertEqual(plugins[1].kind, "zip")
        self.assertEqual(plugins[1].version, "2.18.1")

    def test_apply_updates_rewrites_only_changed_values(self):
        module = load_module()
        plugins = module.parse_plugins(SAMPLE)

        updated = module.apply_updates(
            SAMPLE,
            {
                "heatmap-calendar": module.PluginUpdate(
                    version="0.7.2",
                    hash_main_js="sha256-new-main",
                    hash_manifest_json="sha256-new-manifest",
                    hash_styles_css="sha256-new-styles",
                ),
                "templater": module.PluginUpdate(
                    version="2.19.0",
                    url="https://github.com/SilentVoid13/Templater/releases/download/2.19.0/templater-obsidian.zip",
                    hash_zip="sha256-new-zip",
                ),
            },
            plugins,
        )

        self.assertIn('version = "0.7.2";', updated)
        self.assertIn('hashMainJs = "sha256-new-main";', updated)
        self.assertIn('hashManifestJson = "sha256-new-manifest";', updated)
        self.assertIn('hashStylesCss = "sha256-new-styles";', updated)
        self.assertIn("/download/2.19.0/templater-obsidian.zip", updated)
        self.assertIn('hash = "sha256-new-zip";', updated)
        self.assertIn("stripRoot = false;", updated)
        self.assertNotIn("sha256-old-main", updated)
        self.assertNotIn("sha256-old-zip", updated)


if __name__ == "__main__":
    unittest.main()
