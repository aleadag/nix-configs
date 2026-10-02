import copy
import json
import subprocess
import sys
import tempfile
from pathlib import Path

baseline_path = Path(sys.argv[1])
current_path = Path(sys.argv[2])
approved_rev = sys.argv[3]
checker_path = Path(sys.argv[4])
approved_ref = sys.argv[5] if len(sys.argv) > 5 else None
baseline = json.loads(baseline_path.read_text())
current = json.loads(current_path.read_text())


def resolved(data, link):
    if isinstance(link, str):
        return link
    node = "root"
    for part in link:
        node = resolved(data, data["nodes"][node]["inputs"][part])
    return node


def run_checker(args, should_pass, label):
    result = subprocess.run(
        [sys.executable, str(checker_path), *map(str, args)],
        capture_output=True,
        text=True,
        check=False,
    )
    if (result.returncode == 0) != should_pass:
        raise AssertionError(
            f"{label}: expected {'pass' if should_pass else 'failure'}, got {result.returncode}: "
            f"{result.stdout}{result.stderr}"
        )


def check_candidate(candidate, should_pass, label, approved=True):
    with tempfile.TemporaryDirectory(prefix="agent-steward-lock-") as directory:
        path = Path(directory) / "flake.lock"
        path.write_text(json.dumps(candidate))
        args = [baseline_path, path]
        if approved:
            args.append(approved_rev)
            if approved_ref is not None:
                args.append(approved_ref)
        run_checker(args, should_pass, label)


def mutate(label, change):
    candidate = copy.deepcopy(current)
    change(candidate)
    check_candidate(candidate, False, label)


# Keep the T3 compatibility proof on the real followed/pruned final graph. Only
# the steward's frozen source metadata is synthesized from the original input.
legacy_candidate = copy.deepcopy(current)
before_inputs = baseline["nodes"]["root"]["inputs"]
legacy_inputs = legacy_candidate["nodes"]["root"]["inputs"]
before_steward = baseline["nodes"][resolved(baseline, before_inputs["agent-steward"])]
legacy_steward = legacy_candidate["nodes"][
    resolved(legacy_candidate, legacy_inputs["agent-steward"])
]
legacy_steward["locked"] = copy.deepcopy(before_steward["locked"])
legacy_steward["original"] = copy.deepcopy(before_steward["original"])

approved_args = [approved_rev] if approved_ref is None else [approved_rev, approved_ref]
run_checker(
    [baseline_path, current_path, *approved_args], True, "approved final lock"
)
check_candidate(
    legacy_candidate, True, "legacy two-argument frozen-revision mode", approved=False
)
run_checker([baseline_path, current_path], False, "missing explicit approved revision")
run_checker(
    [baseline_path, current_path, "0" * 40, *( [approved_ref] if approved_ref else [])],
    False,
    "wrong expected revision",
)
run_checker(
    [baseline_path, current_path, "invalid"], False, "malformed approved revision"
)

mutate(
    "wrong locked revision",
    lambda data: data["nodes"]["agent-steward"]["locked"].update(rev="0" * 40),
)
if approved_ref is None:
    mutate(
        "wrong original revision",
        lambda data: data["nodes"]["agent-steward"]["original"].update(rev="0" * 40),
    )
else:
    mutate(
        "wrong original ref",
        lambda data: data["nodes"]["agent-steward"]["original"].update(ref="v0.0.0"),
    )


def path_pin(data):
    for key in ("locked", "original"):
        data["nodes"]["agent-steward"][key]["type"] = "path"
        data["nodes"]["agent-steward"][key]["path"] = "/tmp/agent-steward"


mutate("path-pinned source", path_pin)
mutate(
    "mutated root graph",
    lambda data: data["nodes"]["root"]["inputs"].update({"nixpkgs-stable": "nixpkgs"}),
)


def mutate_unrelated_pin(data):
    key = data["nodes"]["root"]["inputs"]["nixpkgs"]
    data["nodes"][key]["locked"]["rev"] = "0" * 40


mutate("mutated unrelated input", mutate_unrelated_pin)
mutate(
    "lost follows edge",
    lambda data: data["nodes"]["agent-steward"]["inputs"].update(
        {"nixpkgs": "nixpkgs"}
    ),
)


def retain_duplicate(data):
    old_steward = baseline["nodes"][resolved(baseline, before_inputs["agent-steward"])]
    duplicate = baseline["nodes"][resolved(baseline, old_steward["inputs"]["nixpkgs"])]
    data["nodes"]["retained-steward-nixpkgs"] = copy.deepcopy(duplicate)


mutate("retained duplicate or orphan node", retain_duplicate)
mutate(
    "dangling root input",
    lambda data: data["nodes"]["root"]["inputs"].update(
        {"dangling-test": "missing-node"}
    ),
)

print(
    "agent-steward lock checker: approved pin, synthetic legacy mode and all negative controls passed"
)
