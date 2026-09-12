# Siege of Servers — Meticulous Match Plan

This is the execution plan. Read it before the event, then use the individual skills during play.

## T-30 to T-0: pre-start setup

### Local machine

Have ready:

```text
terminal multiplexer: tmux
editor: vim/nvim/code if available
python3 + requests
ripgrep (`rg`)
git
curl
jq
sqlite3
netcat/socat
tcpdump/tshark
file/checksec/gdb/strace/ltrace if binary service appears
```

Prepare three terminal panes:

```text
PANE 1: SSH + service operations
PANE 2: logs / packet capture
PANE 3: exploit development / runner
```

Create notes template:

```text
MY_PUBLIC_IP=
MY_PRIVATE_IP=
SERVICE=
PORT=
PROCESS=
CODE_DIR=
DB=
RESTART=
LOGS=
LAST_GOOD_COMMIT=
CHECKER_STATE=
TOP_VULN=
EXPLOIT=
PATCH=
```

### Rule confirmation

Before start, fill:

```text
START_TIME=
END_TIME=
FLAG_SUBMISSION_METHOD=
EMERGENCY_CONTACT=
OFFICIAL_OPPONENT_PRIVATE_IP_LIST=
ANNOUNCED_SERVICE_PORTS=
ROUND_LENGTH_IF_ANNOUNCED=
```

Do not improvise scope.

---

# Phase 1 — 0:00 to 0:05

## Goal

Know exactly what is running and be able to restore it.

### Actions

```bash
ip -br addr
ip route
ss -lntup
ps auxf
systemctl --type=service --state=running --no-pager
docker ps -a 2>/dev/null || true
```

Map:

```text
PORT -> PID -> process -> code dir -> datastore
```

Backup immediately:

```bash
mkdir -p ~/siege/{backups,notes,logs,pcaps,exploits}
sudo tar czf ~/siege/backups/service-original-$(date +%s).tgz /PATH/TO/SERVICE
```

Create Git baseline if needed.

### Exit criteria

```text
[ ] restart command known
[ ] log command known
[ ] code dir known
[ ] backup exists
[ ] Git baseline exists
```

---

# Phase 2 — 0:05 to 0:10

## Goal

Gain visibility before opponents teach you the service the hard way.

Start bounded pcap on announced service port:

```bash
./scripts/pcap_rotate.sh PORT
```

Start logs:

```bash
journalctl -u SERVICE -f
```

or container/web logs.

Create a simple baseline functional interaction with the service.

### Exit criteria

```text
[ ] pcap/log visibility active
[ ] one normal request/response captured
[ ] checker-critical functionality roughly understood
```

---

# Phase 3 — 0:10 to 0:20

## Goal

Find the first cheap flag-reading primitive.

Audit in strict order:

```text
1. IDOR / missing ownership
2. SQL injection
3. command injection
4. traversal / file read
5. hardcoded auth/secret
6. deserialization / SSTI / SSRF / upload
7. memory corruption / deeper reversing
```

Use route-first/dataflow-first reading. Do not read the repository linearly.

For every hypothesis:

```text
SOURCE -> CODE PATH -> SINK -> FLAG STORE
```

Kill weak hypotheses quickly.

### Time budget

```text
5 min evidence deadline
10 min exploit-or-park deadline
```

---

# Phase 4 — first exploit

## Goal

Convert one vulnerability into both offense and defense.

Sequence:

```text
prove locally
-> trace to flag store
-> save PoC
-> test ONE authorized opponent
-> convert to deterministic script
-> patch your own copy minimally
-> baseline test
-> verify exploit fails locally after patch
-> commit
-> run against all official targets with bounded concurrency
```

Do not patch first and forget how to weaponize the bug.

---

# Phase 5 — steady-state rounds

Every round/tick:

```text
1. own SLA glance
2. run known-good exploits for fresh flags
3. submit immediately
4. inspect new attack traffic/log anomalies
5. deploy at most one evidence-backed patch
6. continue highest-value exploit research
7. update status board
```

Status board format:

```text
SERVICE | SLA | VULN | EXPLOIT | PATCH | OWNER | NEXT
```

---

# Priority engine

At any decision point:

## If own service not UP

```text
STOP secondary offense work
restore UP
then resume
```

## If active flag theft observed

```text
preserve request
reproduce
patch root cause
reuse primitive offensively if applicable
```

## If exploit works manually

```text
stop manual repetition
script now
```

## If exploit fails on many targets

```text
check whether opponents patched it
avoid retry storms
move to next primitive
```

## If one engineer has >2 active tasks

```text
kill/park one task
```

---

# Team plan

## 4-person optimal

```text
A — SLA/infra/rollback
B — service audit + patch engineering
C — exploit engineering
D — traffic intel + runner + submission
```

## 3-person

```text
A — SLA/infra
B — audit/patch
C — offense/traffic/automation
```

## 2-person

```text
A — defense + code audit
B — offense + automation + traffic
```

Each person reports only:

```text
status / evidence / next action
```

No long explanations mid-round.

---

# Exact speed optimizations

## Replace manual actions

```text
manual listener check     -> health_watch.sh
manual repeated exploit   -> run_targets.py
manual packet capture     -> pcap_rotate.sh
manual recent-file checks -> diff_watch.sh
manual service discovery  -> quick_triage.sh
```

## Replace vague work

Bad:

```text
"look for bugs"
```

Good:

```text
"trace GET /note/:id ownership check for 8 minutes"
```

Bad:

```text
"analyze traffic"
```

Good:

```text
"reconstruct the 09:48 request that caused a 500 and map it to handler"
```

## Replace risky patches

Bad:

```text
rewrite auth subsystem
```

Good:

```text
add owner predicate to the vulnerable read query
```

---

# Emergency plans

## Service DOWN

```text
listener -> process -> logs -> dependency -> disk -> recent patch -> rollback
```

## MUMBLE

```text
recent patch? rollback first
then compare expected response shape
```

## CORRUPT

```text
do not wipe DB
check storage, schema, permissions, retrieval path, recent changes
```

## Compromise suspected

```text
preserve 60-second snapshot
restore known-good app code/config
remove clearly malicious runtime artifact
patch root cause
baseline test
```

## Flags stolen fast

```text
traffic -> replay -> source -> sink -> patch -> offense reuse
```

---

# Final rounds

Freeze unnecessary change.

```text
keep SLA UP
keep successful exploits running
prioritize freshest flags
avoid speculative hardening
avoid dependency upgrades
avoid major refactors
patch only active/evidence-backed leaks
```

A late self-inflicted `DOWN` is often unrecoverable in score.

---

# Final mental model

```text
BACKUP
  -> OBSERVE
    -> MAP FLAG STORE
      -> FIND CHEAP PRIMITIVE
        -> WEAPONIZE
          -> PATCH
            -> VERIFY SLA
              -> AUTOMATE
                -> MINE TRAFFIC
                  -> REPEAT
```

The team that turns discoveries into **repeatable points and minimal safe patches faster than everyone else** wins.