# Skill: SLA / Checker Recovery

## Trigger

Use whenever scoreboard/checker status is not `UP`.

## Event semantics

```text
UP           service behaved correctly            PASS
CORRUPT      stored flag/data missing or damaged  FAIL
MUMBLE       unexpected/broken response           FAIL
DOWN         unreachable/port closed              FAIL
CHECK FAILED checker internal error                FAIL
```

Do not treat these as synonyms. Diagnose by class.

# DOWN

## 30-second ladder

```bash
ss -lntup
ps auxf
systemctl status SERVICE --no-pager
journalctl -u SERVICE -n 100 --no-pager
```

Docker:

```bash
docker ps -a
docker logs CONTAINER --tail 100
```

Questions:

```text
port listening?
process alive?
crash loop?
database/dependency alive?
wrong bind address?
recent patch/restart?
disk full?
```

Resource checks:

```bash
df -h
df -i
free -h
uptime
```

If a recent change preceded failure, rollback before deep debugging.

# MUMBLE

Meaning: reachable, but checker sees wrong behavior.

Highest-probability causes:

```text
recent security patch changed valid behavior
response/status format changed
session/auth flow broken
exception on checker input
wrong database schema/state
incorrect dependency/config
```

Fast path:

```bash
git status --short
git diff
git log --oneline -5
journalctl -u SERVICE -n 150 --no-pager
```

Then replay your baseline workflow exactly.

Rule:

```text
MUMBLE + recent patch = rollback newest patch first, investigate second
```

# CORRUPT

Treat as state/retrieval integrity failure.

Do **not** wipe or reset databases.

Check:

```bash
find /PATH/TO/SERVICE -type f -mmin -20 -ls
ls -l DB_OR_STORAGE
journalctl -u SERVICE -n 150 --no-pager
git diff
```

Questions:

```text
Did a restart recreate/empty storage?
Did migration/schema code run?
Did patch change key/object identifiers?
Did ownership/session linkage change?
Did file permissions change?
Is retrieval path now denying legitimate checker access?
Was data actually deleted by an attacker?
```

Restore **application code/config** from known-good backup if needed, but do not blindly overwrite live flag data with an old DB snapshot unless you understand the consequences.

# CHECK FAILED

Official rules say this is still not an SLA pass, but it may be checker-side.

Actions:

```text
1. verify your service locally
2. preserve logs/timestamps
3. avoid random changes if service is healthy
4. report organizer-side technical problems as instructed
```

# Checker contract reconstruction

Use passive traffic/logs to infer normal checker workflow:

```text
create/register?
login?
store value?
retrieve same value?
service-specific operation?
```

Capture the sequence as `baseline.sh`/`baseline.py` so every patch can be tested in seconds.

## Example baseline structure

```bash
#!/usr/bin/env bash
set -euo pipefail
BASE="http://127.0.0.1:PORT"
# register/login/store/read requests here
```

Avoid hardcoding real live flags into your test files.

# Restart minimization

Every unnecessary restart creates a risk window. Prefer:

```text
edit once
syntax/build check
single restart
baseline replay
```

Examples:

```bash
python -m py_compile path/to/file.py
node --check path/to/file.js
go test ./...
php -l file.php
```

Then restart only if syntax/build succeeds.

# SLA-first priority inversion

If your service is failing checker while you are developing an exploit:

```text
STOP offense work
restore UP
resume offense
```

The event scoring multiplies task points by SLA percentage, so extended downtime devalues offensive gains.

# Status board

Keep one line visible to the whole team:

```text
SERVICE | STATUS | LAST CHANGE | LAST GOOD COMMIT | OWNER | NEXT ACTION
```

Examples:

```text
notes | UP     | auth patch 09:42 | a1b2c3d | A | monitor
chat  | MUMBLE | SQL patch 09:44  | d4e5f6a | B | rollback
```

# Recovery decision tree

```text
NOT UP
 |
 +-- port absent? ------> DOWN ladder
 |
 +-- responds normally? -- no --> MUMBLE ladder
 |
 +-- stored test object missing? --> CORRUPT ladder
 |
 +-- everything local works? --> preserve evidence / possible checker issue
```

# Done condition

Do not declare recovered until:

```text
[ ] announced port listening
[ ] process stable for several minutes
[ ] baseline store/retrieve works
[ ] logs show no immediate crash loop
[ ] last known-good commit recorded
[ ] next official checker observed
```
