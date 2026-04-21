import sys
import tomllib

import tomlkit


def merge(left, right):
    if isinstance(left, dict) and isinstance(right, dict):
        merged = dict(left)
        for key, value in right.items():
            if key in merged:
                merged[key] = merge(merged[key], value)
            else:
                merged[key] = value
        return merged
    return right


with open(sys.argv[1], "rb") as handle:
    backup = tomllib.load(handle)

with open(sys.argv[2], "rb") as handle:
    current = tomllib.load(handle)

merged = merge(backup, current)

with open(sys.argv[3], "w", encoding="utf-8") as handle:
    tomlkit.dump(merged, handle)
