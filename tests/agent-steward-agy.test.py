import json
import os
import shlex
import subprocess
import sys
import tempfile
from pathlib import Path

fixture = json.loads(Path(sys.argv[1]).read_text())
with tempfile.TemporaryDirectory() as directory:
    home = Path(directory) / "home"
    state = home / ".local/state"
    settings = home / ".gemini/antigravity-cli/settings.json"
    manifest = state / "agent-steward/agy/statusline.json"
    workdir = state / "agent-steward/agy-quota-workdir"
    settings.parent.mkdir(parents=True)
    settings.write_text(
        json.dumps(
            {
                "unrelated": "preserve me",
                "statusLine": {
                    "type": "command",
                    "command": "old renderer",
                    "enabled": True,
                },
            }
        )
    )
    env = {
        **os.environ,
        "HOME": str(home),
        "XDG_STATE_HOME": str(state),
        "DRY_RUN_CMD": "",
    }

    def activate():
        script = (fixture["directories"] + "\n" + fixture["activation"]).replace(
            fixture["home"], str(home)
        )
        subprocess.run(["bash", "-euo", "pipefail", "-c", script], env=env, check=True)

    activate()
    assert manifest.is_file(), "Activation must install the quota-capture manifest"
    saved = json.loads(manifest.read_text())
    current = json.loads(settings.read_text())
    assert current["statusLine"]["command"] == saved["installedCommand"]
    assert saved["schema_version"] == 1
    assert saved["previousStatusLine"]["command"] != saved["installedCommand"]
    assert current["unrelated"] == "preserve me"
    assert current["permissions"]["allow"] == ["command(pwd)"]
    assert current["permissions"]["deny"] == ["command(rm -rf /)"]
    assert workdir.is_dir() and not workdir.is_symlink()
    for path in [state / "agent-steward", manifest.parent, workdir]:
        assert path.stat().st_mode & 0o777 == 0o700
    for path in [settings, manifest]:
        assert not path.is_symlink()
        assert path.stat().st_mode & 0o777 == 0o600

    payload = json.dumps(
        {
            "agent_state": "working",
            "model": {"display_name": "Test Gemini"},
            "context_window": {"used_percentage": 25},
        }
    )
    original = subprocess.run(
        ["bash", "-c", saved["previousStatusLine"]["command"]],
        input=payload,
        env=env,
        text=True,
        capture_output=True,
        check=True,
    )
    assert "Test Gemini" in original.stdout and "WORKING" in original.stdout
    hooked = subprocess.run(
        shlex.split(saved["installedCommand"]),
        input=payload,
        env=env,
        text=True,
        capture_output=True,
        check=True,
    )
    assert hooked.stdout == original.stdout, (
        "Capture hook must preserve native status-line rendering"
    )
    assert hooked.stderr == ""
    assert not (state / "agent-steward/quota/antigravity.json").exists()

    activate()
    assert json.loads(manifest.read_text()) == saved
    assert json.loads(settings.read_text()) == current
    assert fixture["statusLine"] == current["statusLine"]

    manifest.write_text(
        json.dumps(
            {
                **saved,
                "installedCommand": "outdated capture hook",
                "previousStatusLine": {
                    **saved["previousStatusLine"],
                    "command": "outdated renderer",
                },
            }
        )
    )
    settings.write_text(
        json.dumps(
            {
                **current,
                "statusLine": {
                    **current["statusLine"],
                    "command": "outdated capture hook",
                },
            }
        )
    )
    activate()
    assert json.loads(manifest.read_text()) == saved
    assert json.loads(settings.read_text()) == current

    workdir.rmdir()
    target = Path(directory) / "symlink-target"
    target.mkdir(mode=0o755)
    workdir.symlink_to(target, target_is_directory=True)
    script = fixture["directories"].replace(fixture["home"], str(home))
    result = subprocess.run(
        ["bash", "-euo", "pipefail", "-c", script],
        env=env,
        text=True,
        capture_output=True,
        check=False,
    )
    assert result.returncode != 0, "Private quota directories must reject symlinks"
    assert target.stat().st_mode & 0o777 == 0o755

print("AGY activation, renderer passthrough, permissions, and symlink checks passed")
