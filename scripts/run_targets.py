#!/usr/bin/env python3
"""
AUTHORIZED USE: Siege of Servers Attack–Defense CTF only.
Loads ONLY organizer-confirmed targets from a local JSON allow-list.

Usage:
    python3 scripts/run_targets.py targets.json path/to/exploit.py [WORKERS]

Exploit module contract:
    exploit(host: str, port: int, flag_id: str | None = None) -> str | None

This runner does not submit flags. Keep scoreboard submission isolated to the
organizer-documented interface only.
"""

from __future__ import annotations

import importlib.util
import json
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Optional


@dataclass(frozen=True)
class Target:
    team: str
    ip: str
    port: int
    flag_id: Optional[str] = None


def load_exploit(path: Path) -> Callable[[str, int, Optional[str]], Optional[str]]:
    spec = importlib.util.spec_from_file_location("ctf_exploit", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load exploit module: {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    fn = getattr(module, "exploit", None)
    if not callable(fn):
        raise RuntimeError("exploit module must define exploit(host, port, flag_id=None)")
    return fn


def load_targets(path: Path) -> list[Target]:
    data = json.loads(path.read_text())
    default_port = int(data["port"])
    out: list[Target] = []
    for row in data.get("targets", []):
        if not row.get("enabled", True):
            continue
        ip = str(row["ip"]).strip()
        team = str(row.get("team", ip))
        port = int(row.get("port", default_port))
        flag_id = row.get("flag_id")
        out.append(Target(team=team, ip=ip, port=port, flag_id=flag_id))
    if not out:
        raise RuntimeError("target allow-list is empty")
    return out


def worker(target: Target, exploit: Callable[[str, int, Optional[str]], Optional[str]]):
    start = time.monotonic()
    try:
        flag = exploit(target.ip, target.port, target.flag_id)
        latency = int((time.monotonic() - start) * 1000)
        return target, "SUCCESS" if flag else "NO_FLAG", latency, flag, None
    except Exception as exc:
        latency = int((time.monotonic() - start) * 1000)
        return target, "ERROR", latency, None, f"{type(exc).__name__}: {exc}"


def main() -> int:
    if len(sys.argv) < 3:
        print(
            f"Usage: {sys.argv[0]} TARGETS_JSON EXPLOIT_PY [WORKERS]",
            file=sys.stderr,
        )
        return 2

    targets_path = Path(sys.argv[1])
    exploit_path = Path(sys.argv[2])
    workers = int(sys.argv[3]) if len(sys.argv) > 3 else 8
    workers = max(1, min(workers, 20))

    targets = load_targets(targets_path)
    exploit = load_exploit(exploit_path)

    seen_flags: set[str] = set()

    with ThreadPoolExecutor(max_workers=workers) as pool:
        futures = {pool.submit(worker, target, exploit): target for target in targets}
        for future in as_completed(futures):
            target, status, latency, flag, error = future.result()
            if flag and flag not in seen_flags:
                seen_flags.add(flag)
                print(flag, flush=True)
            print(
                f"{target.team:>12} {target.ip}:{target.port:<5} {status:<8} {latency:>5}ms"
                + (f" {error}" if error else ""),
                file=sys.stderr,
                flush=True,
            )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
