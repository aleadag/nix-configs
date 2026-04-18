#!/usr/bin/env python3

from __future__ import annotations

import argparse
import dataclasses
import json
import pathlib
import re
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request


DEFAULT_PLUGIN_FILE = (
    pathlib.Path(__file__).resolve().parents[1]
    / "modules"
    / "home-manager"
    / "desktop"
    / "obsidian"
    / "plugins.nix"
)


@dataclasses.dataclass(frozen=True)
class PluginBlock:
    attr_name: str
    kind: str
    start: int
    end: int
    version: str
    pname: str | None = None
    owner: str | None = None
    repo: str | None = None
    has_styles_css: bool = False
    url: str | None = None
    name: str | None = None
    strip_root: bool = False


@dataclasses.dataclass(frozen=True)
class PluginUpdate:
    version: str
    hash_main_js: str | None = None
    hash_manifest_json: str | None = None
    hash_styles_css: str | None = None
    url: str | None = None
    hash_zip: str | None = None


def _require_match(pattern: str, text: str, field_name: str) -> str:
    match = re.search(pattern, text, re.MULTILINE)
    if match is None:
        raise ValueError(f"Could not find `{field_name}` in plugin block")
    return match.group(1)


def parse_plugins(text: str) -> list[PluginBlock]:
    plugins: list[PluginBlock] = []

    mk_pattern = re.compile(
        r"(?ms)^  (?P<attr>[a-z0-9-]+) = mkObsidianPlugin \{\n(?P<body>.*?)^  \};"
    )
    zip_pattern = re.compile(
        r"(?ms)^  (?P<attr>[a-z0-9-]+) = pkgs\.fetchzip \{\n(?P<body>.*?)^  \};"
    )

    for match in mk_pattern.finditer(text):
        body = match.group("body")
        plugins.append(
            PluginBlock(
                attr_name=match.group("attr"),
                kind="mk",
                start=match.start(),
                end=match.end(),
                pname=_require_match(r'^    pname = "([^"]+)";$', body, "pname"),
                version=_require_match(r'^    version = "([^"]+)";$', body, "version"),
                owner=_require_match(r'^    owner = "([^"]+)";$', body, "owner"),
                repo=_require_match(r'^    repo = "([^"]+)";$', body, "repo"),
                has_styles_css=(
                    re.search(r'^    hashStylesCss = "([^"]+)";$', body, re.MULTILINE)
                    is not None
                ),
            )
        )

    for match in zip_pattern.finditer(text):
        body = match.group("body")
        url = _require_match(r'^    url = "([^"]+)";$', body, "url")
        version_match = re.search(r"/download/([^/]+)/", url)
        if version_match is None:
            raise ValueError(f"Could not infer version from url `{url}`")
        plugins.append(
            PluginBlock(
                attr_name=match.group("attr"),
                kind="zip",
                start=match.start(),
                end=match.end(),
                version=version_match.group(1),
                url=url,
                name=_require_match(r'^    name = "([^"]+)";$', body, "name"),
                strip_root=(
                    re.search(r"^    stripRoot = false;$", body, re.MULTILINE)
                    is not None
                ),
            )
        )

    return sorted(plugins, key=lambda plugin: plugin.start)


def render_plugin_block(plugin: PluginBlock, update: PluginUpdate) -> str:
    if plugin.kind == "mk":
        lines = [
            f"  {plugin.attr_name} = mkObsidianPlugin {{",
            f'    pname = "{plugin.pname}";',
            f'    version = "{update.version}";',
            f'    owner = "{plugin.owner}";',
            f'    repo = "{plugin.repo}";',
            f'    hashMainJs = "{update.hash_main_js}";',
            f'    hashManifestJson = "{update.hash_manifest_json}";',
        ]
        if plugin.has_styles_css:
            lines.append(f'    hashStylesCss = "{update.hash_styles_css}";')
        lines.append("  };")
        return "\n".join(lines)

    lines = [
        f"  {plugin.attr_name} = pkgs.fetchzip {{",
        f'    url = "{update.url}";',
        f'    name = "{plugin.name}";',
    ]
    if plugin.strip_root:
        lines.append("    stripRoot = false;")
    lines.extend(
        [
            f'    hash = "{update.hash_zip}";',
            "  };",
        ]
    )
    return "\n".join(lines)


def apply_updates(
    text: str,
    updates: dict[str, PluginUpdate],
    plugins: list[PluginBlock] | None = None,
) -> str:
    parsed_plugins = parse_plugins(text) if plugins is None else plugins
    updated_text = text

    for plugin in sorted(parsed_plugins, key=lambda item: item.start, reverse=True):
        update = updates.get(plugin.attr_name)
        if update is None:
            continue
        updated_text = (
            updated_text[: plugin.start]
            + render_plugin_block(plugin, update)
            + updated_text[plugin.end :]
        )

    return updated_text


def github_json(url: str) -> dict:
    request = urllib.request.Request(
        url,
        headers={
            "Accept": "application/vnd.github+json",
            "User-Agent": "update-obsidian-plugins",
        },
    )
    with urllib.request.urlopen(request) as response:
        return json.load(response)


def latest_release(owner: str, repo: str) -> dict:
    url = f"https://api.github.com/repos/{owner}/{repo}/releases/latest"
    try:
        return github_json(url)
    except urllib.error.HTTPError as error:
        raise RuntimeError(
            f"Failed to fetch latest release for {owner}/{repo}: {error}"
        ) from error


def run_command(args: list[str]) -> str:
    completed = subprocess.run(
        args,
        check=True,
        capture_output=True,
        text=True,
    )
    return completed.stdout.strip()


def prefetch_sri(url: str, *, unpack: bool) -> str:
    command = ["nix-prefetch-url", "--type", "sha256"]
    if unpack:
        command.append("--unpack")
    command.append(url)
    hash_value = run_command(command)
    return run_command(["nix", "hash", "to-sri", "--type", "sha256", hash_value])


def select_zip_asset(release: dict, plugin: PluginBlock) -> str:
    zip_assets = [
        asset for asset in release.get("assets", []) if asset["name"].endswith(".zip")
    ]
    if not zip_assets:
        raise RuntimeError(f"No zip asset found for {plugin.attr_name}")

    current_basename = pathlib.PurePosixPath(
        urllib.parse.urlparse(plugin.url or "").path
    ).name
    expected_name = current_basename.replace(plugin.version, release["tag_name"])

    for asset in zip_assets:
        if asset["name"] == expected_name:
            return asset["browser_download_url"]

    if len(zip_assets) == 1:
        return zip_assets[0]["browser_download_url"]

    raise RuntimeError(
        f"Could not decide which zip asset to use for {plugin.attr_name}: "
        + ", ".join(asset["name"] for asset in zip_assets)
    )


def build_update(plugin: PluginBlock) -> PluginUpdate | None:
    if plugin.kind == "mk":
        assert plugin.owner is not None and plugin.repo is not None
        release = latest_release(plugin.owner, plugin.repo)
        version = release["tag_name"]
        if version == plugin.version:
            return None
        base_url = f"https://github.com/{plugin.owner}/{plugin.repo}/releases/download/{version}"
        return PluginUpdate(
            version=version,
            hash_main_js=prefetch_sri(f"{base_url}/main.js", unpack=False),
            hash_manifest_json=prefetch_sri(f"{base_url}/manifest.json", unpack=False),
            hash_styles_css=(
                prefetch_sri(f"{base_url}/styles.css", unpack=False)
                if plugin.has_styles_css
                else None
            ),
        )

    release = latest_release(_zip_owner(plugin), _zip_repo(plugin))
    version = release["tag_name"]
    if version == plugin.version:
        return None
    asset_url = select_zip_asset(release, plugin)
    return PluginUpdate(
        version=version,
        url=asset_url,
        hash_zip=prefetch_sri(asset_url, unpack=True),
    )


def _zip_owner(plugin: PluginBlock) -> str:
    assert plugin.url is not None
    path_parts = urllib.parse.urlparse(plugin.url).path.strip("/").split("/")
    return path_parts[0]


def _zip_repo(plugin: PluginBlock) -> str:
    assert plugin.url is not None
    path_parts = urllib.parse.urlparse(plugin.url).path.strip("/").split("/")
    return path_parts[1]


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Update pinned Obsidian plugin versions and hashes."
    )
    parser.add_argument(
        "--path",
        type=pathlib.Path,
        default=DEFAULT_PLUGIN_FILE,
        help="Path to plugins.nix",
    )
    parser.add_argument(
        "--plugin",
        action="append",
        dest="plugins",
        default=[],
        help="Limit updates to specific attr names. Can be passed multiple times.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print planned updates without writing the file.",
    )
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    text = args.path.read_text()
    plugins = parse_plugins(text)
    selected = [
        plugin
        for plugin in plugins
        if not args.plugins or plugin.attr_name in args.plugins
    ]

    if not selected:
        print("No matching plugins found.", file=sys.stderr)
        return 1

    updates: dict[str, PluginUpdate] = {}
    for plugin in selected:
        update = build_update(plugin)
        if update is None:
            print(f"{plugin.attr_name}: already up to date ({plugin.version})")
            continue
        updates[plugin.attr_name] = update
        print(f"{plugin.attr_name}: {plugin.version} -> {update.version}")

    if not updates:
        return 0

    updated_text = apply_updates(text, updates, plugins)
    if args.dry_run:
        return 0

    args.path.write_text(updated_text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
