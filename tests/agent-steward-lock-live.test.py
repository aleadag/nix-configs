import copy
import json
import runpy
import sys
from pathlib import Path

validate = runpy.run_path(sys.argv[1])["validate"]
current = json.loads(Path(sys.argv[2]).read_text())
approved_revision, approved_ref = sys.argv[3:5]


def check(change, should_pass, label):
    candidate = copy.deepcopy(current)
    change(candidate)
    try:
        validate(candidate, approved_revision, approved_ref)
    except (AssertionError, KeyError):
        if should_pass:
            raise AssertionError(f"{label}: expected pass")
    else:
        if not should_pass:
            raise AssertionError(f"{label}: expected rejection")


validate(current, approved_revision, approved_ref)
for name in ("superpowers", "nixpkgs"):
    check(
        lambda data: data["nodes"][data["nodes"]["root"]["inputs"][name]]["locked"].update(rev="0" * 40),
        True,
        f"independent {name} update",
    )


def steward(data):
    return data["nodes"][data["nodes"]["root"]["inputs"]["agent-steward"]]


check(lambda data: steward(data)["locked"].update(rev="0" * 40), False, "wrong steward revision")
check(lambda data: steward(data)["original"].update(ref="v0.0.0"), False, "wrong steward ref")
check(lambda data: steward(data)["locked"].update(type="path"), False, "path-pinned source")
check(lambda data: steward(data)["locked"].update(owner="other"), False, "wrong source owner")
check(lambda data: steward(data)["locked"].update(repo="other"), False, "wrong source repository")
check(lambda data: steward(data)["locked"].update(narHash="invalid"), False, "invalid source hash")
check(lambda data: steward(data).update(flake=False), False, "non-flake steward")
check(lambda data: steward(data)["inputs"].update(nixpkgs="nixpkgs"), False, "lost follows edge")
check(
    lambda data: data["nodes"].update(duplicate=copy.deepcopy(data["nodes"]["nixpkgs"])),
    False,
    "retained duplicate or orphan node",
)
check(
    lambda data: data["nodes"]["root"]["inputs"].update(dangling="missing-node"),
    False,
    "dangling graph edge",
)
print("live steward lock: unrelated updates accepted; source, follows and graph negative controls passed")
