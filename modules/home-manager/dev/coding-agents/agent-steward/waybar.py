import html
import json
import math
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path


def timestamp(value):
    time = datetime.fromisoformat(value.replace("Z", "+00:00"))
    if time.tzinfo is None:
        raise ValueError("Missing timezone")
    return time


def snapshot(path, bucket):
    with path.open() as file:
        raw = file.read(1048577)
    if len(raw.encode()) > 1048576:
        raise ValueError("Oversized snapshot")
    data = json.loads(raw)
    if (
        data["schema_version"] != 1
        or data["source"] != bucket
        or not re.fullmatch("[0-9a-f]{64}", data["identity_fingerprint"])
        or not isinstance(data["windows"], list)
    ):
        raise ValueError("Invalid snapshot")
    for window in data["windows"]:
        scope = window["scope"]
        if scope["type"] not in ("account", "pool"):
            raise ValueError("Invalid scope")
        if scope["type"] == "pool" and not isinstance(scope["pool_id"], str):
            raise ValueError("Invalid pool")
        percent = window["remaining_percent"]
        if (
            type(percent) not in (int, float)
            or not math.isfinite(percent)
            or not 0 <= percent <= 100
        ):
            raise ValueError("Invalid percentage")
        observed = timestamp(window["observed_at"])
        reset = timestamp(window["reset_at"])
        valid = timestamp(window["valid_until"])
        if observed >= reset or observed >= valid:
            raise ValueError("Invalid times")
        if "id" in window and not isinstance(window["id"], str):
            raise ValueError("Invalid label")
    return data["windows"]


def relative_reset(reset, now):
    seconds = (reset - now).total_seconds()
    days, minutes = divmod(int(abs(seconds) // 60), 1440)
    hours, minutes = divmod(minutes, 60)
    parts = [
        f"{value}{unit}"
        for value, unit in [(days, "d"), (hours, "h"), (minutes, "m")]
        if value
    ]
    duration = " ".join(parts[:2]) or "<1m"
    return f"in {duration}" if seconds >= 0 else f"{duration} ago"


def display(config, state, now):
    labels = {
        "codex": "Codex",
        "pi_codex": "Codex",
        "pi_xai": "xAI",
        "antigravity": "Antigravity",
    }
    pools = dict.fromkeys(
        (candidate["quota_bucket"], candidate["quota_pool"])
        for candidate in config["candidates"]
        if candidate["tool"] in config["tools"]
    )
    text, tooltip, pool_values = [], [], []
    for bucket, pool in pools:
        label = (
            "Gemini" if bucket == "antigravity" and pool == "gemini" else labels[bucket]
        )
        if bucket == "codex" and ("pi_codex", pool) in pools:
            label = "Native Codex"
        if sum(other == bucket for other, _ in pools) > 1 or (
            bucket == "antigravity" and pool != "gemini"
        ):
            label += "/" + pool
        details, percentages = [], []
        try:
            windows = snapshot(
                state / "agent-steward/quota" / (bucket + ".json"), bucket
            )
            windows = [
                window
                for window in windows
                if window["scope"]["type"] == "account"
                or window["scope"]["pool_id"] == pool
            ]
            for window in windows:
                observed = timestamp(window["observed_at"])
                reset = timestamp(window["reset_at"])
                fresh = observed <= now < min(reset, timestamp(window["valid_until"]))
                percent = window["remaining_percent"] if fresh else None
                percentages.append(percent)
                remaining = f"{percent:.0f}%" if fresh else "? (stale)"
                age = (
                    f"{int((now - observed).total_seconds() // 60)}m ago"
                    if observed <= now
                    else "future observation"
                )
                title = html.escape(
                    f"{window.get('id', window.get('cadence', 'limit'))}: {remaining}"
                )
                timing = html.escape(
                    f"reset {relative_reset(reset, now)}; observed {age}"
                )
                meter = ""
                if fresh:
                    filled = int(percent // 10)
                    meter = f"\n  <tt>{'▰' * filled}{'▱' * (10 - filled)}</tt>"
                details.append(f"  <b>{title}</b>{meter}\n  <small>{timing}</small>")
        except (
            OSError,
            ValueError,
            TypeError,
            KeyError,
            AttributeError,
            RecursionError,
        ):
            details = ["  <small>Unavailable or invalid snapshot</small>"]
            percentages = []
        value = min(percentages) if percentages and None not in percentages else None
        pool_values.append(value)
        remaining = f"{value:.0f}%" if value is not None else "?"
        text.append(f"{label} {remaining}")
        tooltip.append(
            f"<b>{html.escape(label)} · {remaining}</b>\n"
            + "\n\n".join(details or ["  <small>No applicable limits</small>"])
        )
    lowest = min((value for value in pool_values if value is not None), default=100)
    if lowest < 10:
        state = "critical"
    elif lowest < 20:
        state = "warning"
    elif not pool_values or None in pool_values:
        state = "unknown"
    else:
        state = "healthy"
    return {"text": " · ".join(text), "tooltip": "\n\n".join(tooltip), "class": state}


if __name__ == "__main__":
    config = json.loads(Path(sys.argv[1]).read_text())
    state = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state")
    print(json.dumps(display(config, state, datetime.now(timezone.utc))))
