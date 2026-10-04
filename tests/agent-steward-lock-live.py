import json
import re
import sys
from pathlib import Path


def validate(data):
    nodes = data["nodes"]

    def resolved(link):
        if isinstance(link, str):
            return link
        key = "root"
        for part in link:
            key = resolved(nodes[key]["inputs"][part])
        return key

    steward = nodes[resolved(nodes["root"]["inputs"]["agent-steward"])]
    assert steward.get("flake", True)
    original = steward["original"]
    assert original["type"] == "github"
    assert original["owner"] == "aleadag"
    assert original["repo"] == "agent-steward"
    locked = steward["locked"]
    assert locked["type"] == "github"
    assert locked["owner"] == "aleadag"
    assert locked["repo"] == "agent-steward"
    assert re.fullmatch(r"[0-9a-f]{40}", locked["rev"])
    assert isinstance(locked["lastModified"], int)
    assert isinstance(locked["narHash"], str) and locked["narHash"].startswith(
        "sha256-"
    )
    assert steward["inputs"]["nixpkgs"] == ["nixpkgs"]
    assert resolved(steward["inputs"]["nixpkgs"]) in nodes

    reachable = set()

    def visit(link):
        key = resolved(link)
        if key in reachable:
            return
        reachable.add(key)
        for value in nodes[key].get("inputs", {}).values():
            visit(value)

    visit("root")
    assert reachable == set(nodes)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("usage: agent-steward-lock-live.py CURRENT.lock")
    validate(json.loads(Path(sys.argv[1]).read_text()))
    print("live steward lock: source, root follows and reachable graph passed")
