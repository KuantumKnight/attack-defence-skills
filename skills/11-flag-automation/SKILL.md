# Skill: Flag Automation

## Trigger

Use after at least one exploit is reliable enough to run unattended against official opponent targets.

## Event-specific constraints

- Flags are valid for a limited number of rounds; official rules say **5 rounds by default**.
- A given attacking team only scores a particular flag once.
- Own-service downtime may prevent submission for that task depending on event settings.
- Attacking stronger teams yields more points than weaker teams under the event's transfer model.

Therefore the automation priorities are:

```text
freshness > reliability > high-value targets > breadth > elegance
```

## Data model

Keep explicit allow-listed target configuration:

```json
{
  "service": "notes",
  "port": 5000,
  "targets": [
    {"team": "team02", "ip": "10.0.0.22"},
    {"team": "team03", "ip": "10.0.0.23"}
  ]
}
```

Never discover arbitrary VPC targets by broad scanning when organizers already provide target IPs/ports.

## Runner architecture

```text
TARGET LIST
   |
   v
BOUNDED WORK QUEUE
   |
   +--> exploit(team A)
   +--> exploit(team B)
   +--> exploit(team C)
   |
   v
FLAG VALIDATOR
   |
   v
DEDUP SET / DB
   |
   v
SUBMITTER
   |
   v
RESULT LOG
```

## Minimal concurrency pattern

```python
from concurrent.futures import ThreadPoolExecutor, as_completed


def run_all(targets, exploit, workers=10):
    out = []
    with ThreadPoolExecutor(max_workers=workers) as pool:
        future_map = {pool.submit(exploit, t): t for t in targets}
        for fut in as_completed(future_map):
            target = future_map[fut]
            try:
                flag = fut.result()
                if flag:
                    out.append((target, flag))
            except Exception:
                pass
    return out
```

Keep `workers` bounded. This is not a load generator.

## Deduplication

Persist already-submitted flags:

```python
from pathlib import Path

SEEN = Path("submitted_flags.txt")
seen = set(SEEN.read_text().splitlines()) if SEEN.exists() else set()


def mark_seen(flag: str):
    if flag not in seen:
        with SEEN.open("a") as f:
            f.write(flag + "\n")
        seen.add(flag)
```

Do not waste time resubmitting duplicates.

## Freshness queue

If the event exposes flag IDs/timestamps/rounds, store:

```text
service
team
round
flag_id
first_seen
attempted_at
success
submitted
```

Always process newest active rounds first.

## Submission adapter

Keep scoreboard submission isolated in **one function/file** because scoreboard interaction is allowed only for normal flag submission/viewing.

```text
exploit code must not probe scoreboard endpoints
submission adapter uses only organizer-documented submission flow
```

If submission protocol is announced as HTTP/TCP, implement only that documented interface.

## Result classes

Normalize failures:

```text
SUCCESS
TIMEOUT
TARGET_DOWN
PATCHED/DENIED
BAD_FLAG
DUPLICATE
SUBMIT_REJECTED
```

This allows quick tactical decisions.

## Target ordering

When a working exploit is not cheap enough to hit everyone every round:

```text
1. higher-scoring vulnerable teams
2. same-score vulnerable teams
3. lower-scoring teams
4. previously patched/low-success targets last
```

If exploit is cheap and reliable, cover all official targets with bounded concurrency.

## Circuit breaker

Temporarily stop attacking one target when repeated failures indicate a patch or outage:

```text
3 deterministic denials -> cool down target for one cycle
network timeout -> retry at most once
success -> reset failure counter
```

This saves time and avoids accidental flooding.

## Metrics file

Write one compact CSV/JSONL event per attempt:

```text
time,service,team,status,latency_ms,flag_found,submitted
```

Every few rounds answer:

```text
Which exploit has best flags/minute?
Which targets still work?
Which exploit is timing out?
Which service deserves more human attention?
```

## Round-safe scheduler

Do not assume round length until organizers announce it. Once known:

```text
round starts
-> fetch/receive current target/flag info if provided
-> run high-confidence exploits
-> submit immediately
-> retry only transient failures
-> leave time for SLA/defense
```

## Own-service guard

Before a heavy attack cycle:

```bash
ss -lnt | grep ':YOUR_PORT '
```

Better: have the SLA role continuously monitor your service so offense never silently runs while your own task is `DOWN`.

## Done condition

```text
[ ] official target allow-list only
[ ] announced ports only
[ ] bounded concurrency
[ ] hard timeouts
[ ] duplicate suppression
[ ] freshest flags first
[ ] submission separated from exploitation
[ ] per-target result metrics
[ ] no retry storms
[ ] no scoreboard probing beyond documented submit/view actions
```
