#!/usr/bin/env python3
"""Smoke test for Supermemory API connectivity using .env.local."""

from __future__ import annotations

import os
import sys


def _load_env_local(path: str = ".env.local") -> None:
    if not os.path.exists(path):
        return
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" not in line:
                continue
            key, value = line.split("=", 1)
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            if key and key not in os.environ:
                os.environ[key] = value


def main() -> int:
    _load_env_local()
    api_key = os.environ.get("SUPERMEMORY_API_KEY")
    if not api_key:
        print("SUPERMEMORY_API_KEY not set. Add it to .env.local or export it.")
        return 2

    try:
        from supermemory import Supermemory
    except Exception as exc:
        print(f"Failed to import supermemory: {exc}")
        return 3

    client = Supermemory()
    try:
        resp = client.profile(container_tag="necromancer_godot", q="hello")
    except Exception as exc:
        print(f"Supermemory request failed: {exc}")
        return 4

    print("OK:", resp)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
