import json
import re
import sys
from pathlib import Path

if len(sys.argv) not in (3, 4, 5):
    raise SystemExit(
        "usage: agent-steward-lock.py BEFORE.lock AFTER.lock [APPROVED_REV [APPROVED_REF]]"
    )

before = json.loads(Path(sys.argv[1]).read_text())
after = json.loads(Path(sys.argv[2]).read_text())
approved_revision = sys.argv[3] if len(sys.argv) >= 4 else None
approved_ref = sys.argv[4] if len(sys.argv) == 5 else None
if approved_revision is not None and not re.fullmatch(
    r"[0-9a-f]{40}", approved_revision
):
    raise SystemExit("approved revision must be an explicit lowercase 40-hex commit")
if approved_ref is not None and not re.fullmatch(r"v[0-9A-Za-z._-]+", approved_ref):
    raise SystemExit("approved ref must be a version tag")


def resolved(data, link):
    if isinstance(link, str):
        return link
    current = "root"
    for part in link:
        current = resolved(data, data["nodes"][current]["inputs"][part])
    return current


def snapshot(data, link):
    node = data["nodes"][resolved(data, link)]
    return {
        "locked": node.get("locked"),
        "original": node.get("original"),
        "flake": node.get("flake", True),
        "inputs": {
            key: snapshot(data, value)
            for key, value in sorted(node.get("inputs", {}).items())
        },
    }


before_root_inputs = before["nodes"]["root"]["inputs"]
after_root_inputs = after["nodes"]["root"]["inputs"]
assert set(before_root_inputs) == set(after_root_inputs)
for name, link in before_root_inputs.items():
    if name != "agent-steward":
        assert snapshot(before, link) == snapshot(after, after_root_inputs[name]), name

before_steward = before["nodes"][resolved(before, before_root_inputs["agent-steward"])]
steward = after["nodes"][resolved(after, after_root_inputs["agent-steward"])]
assert set(before_steward) == set(steward)
assert steward.get("flake", True) == before_steward.get("flake", True)

before_locked = before_steward["locked"]
before_original = before_steward["original"]
locked = steward["locked"]
original = steward["original"]
if approved_revision is None:
    assert locked == before_locked
    assert original == before_original
else:
    assert re.fullmatch(r"[0-9a-f]{40}", approved_revision)
    assert locked["rev"] == approved_revision
    if approved_ref is None:
        assert original["rev"] == approved_revision
        assert {key: value for key, value in original.items() if key != "rev"} == {
            key: value for key, value in before_original.items() if key != "rev"
        }
    else:
        assert original.get("ref") == approved_ref
        assert "rev" not in original
        assert {key: value for key, value in original.items() if key != "ref"} == {
            key: value for key, value in before_original.items() if key not in {"rev", "ref"}
        }
    assert locked["owner"] == original["owner"] == "aleadag"
    assert locked["repo"] == original["repo"] == "agent-steward"
    assert locked["type"] == original["type"] == "github"
    assert isinstance(locked.get("lastModified"), int)
    assert isinstance(locked.get("narHash"), str) and locked["narHash"].startswith(
        "sha256-"
    )
    assert {
        key: value
        for key, value in locked.items()
        if key not in {"rev", "narHash", "lastModified"}
    } == {
        key: value
        for key, value in before_locked.items()
        if key not in {"rev", "narHash", "lastModified"}
    }

before_steward_inputs = before_steward.get("inputs", {})
after_steward_inputs = steward.get("inputs", {})
assert set(before_steward_inputs) == set(after_steward_inputs)
assert after_steward_inputs["nixpkgs"] == ["nixpkgs"]
assert snapshot(after, after_steward_inputs["nixpkgs"]) == snapshot(
    after, after_root_inputs["nixpkgs"]
)
for name, link in before_steward_inputs.items():
    if name != "nixpkgs":
        assert snapshot(before, link) == snapshot(after, after_steward_inputs[name]), (
            name
        )

old_nixpkgs = before["nodes"][resolved(before, before_steward_inputs["nixpkgs"])]
assert not any(
    node.get("locked") == old_nixpkgs.get("locked") for node in after["nodes"].values()
)

reachable = set()


def visit(link):
    key = resolved(after, link)
    if key in reachable:
        return
    reachable.add(key)
    for value in after["nodes"][key].get("inputs", {}).values():
        visit(value)


visit("root")
assert reachable == set(after["nodes"])
print("root/unrelated semantics preserved; steward follows root; duplicate pruned")
