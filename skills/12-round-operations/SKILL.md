# Skill: Round Operations & Team Tempo

## Trigger

Use once the match is live and multiple tasks compete for attention.

## Objective

Prevent the two classic A/D losses:

```text
1. everyone hacks, nobody watches SLA
2. everyone patches, nobody converts bugs into points
```

## Round loop

```text
ROUND START
  |
  +-> SLA glance: own service healthy?
  |      +-- no -> defense takes priority
  |
  +-> exploit runner: current known-good exploits
  |
  +-> traffic/log review: new attack pattern?
  |
  +-> patch queue: one evidence-backed patch at a time
  |
  +-> exploit dev: highest-value unresolved primitive
  |
  +-> submit flags immediately
  |
  +-> status update before next round
```

## Role split

### 2 people

```text
A: SLA + patching + service internals
B: exploit dev + automation + traffic
```

### 3 people

```text
A: SLA/infra/rollback
B: service audit + patching
C: offense + automation + traffic replay
```

### 4 people

```text
A: SLA/infra
B: patch engineer
C: exploit engineer
D: traffic intel + automation/submission
```

If someone is idle, pair them with the bottleneck rather than inventing a new task.

## Shared status board

Use a text file/whiteboard/chat message with exactly:

```text
SERVICE | SLA | ACTIVE VULN | EXPLOIT | PATCH | OWNER | NEXT
```

Example:

```text
notes | UP | IDOR | WORKING | DEPLOYED | A | automate all teams
chat  | UP | ?    | NONE    | NONE     | B | trace message read
pwn   | UP | fmt  | PoC     | NONE     | C | stabilize parser
```

## WIP limit

Per person:

```text
ONE primary task
ONE parked backup task
```

No five simultaneous hypotheses. Context switching is lethal under rounds.

## Escalation rules

Interrupt current work when:

```text
own service DOWN/MUMBLE/CORRUPT
active exploit observed stealing flags
working exploit suddenly stops across many targets
submission path fails
VM resource pressure threatens SLA
```

Do **not** interrupt for:

```text
speculative vulnerability
cosmetic cleanup
code refactor
new tool installation unless it removes a real bottleneck
```

## 10-minute hypothesis rule

For each bug idea:

```text
0 min  -> state exact hypothesis
5 min  -> must have dataflow/evidence
10 min -> exploit proof or park it
```

Exceptions: deep binary exploitation deliberately assigned as a high-value lane.

## Patch handoff format

Before another teammate deploys your patch, send:

```text
FILE/FUNCTION:
BUG:
EXPLOIT POC:
PATCH CHANGE:
BASELINE TEST:
ROLLBACK COMMIT:
```

This prevents "what did you change?" debugging.

## Exploit handoff format

```text
SERVICE:
VULN:
TARGET ARGUMENTS:
FLAG-ID NEEDED?:
SUCCESS CONDITION:
KNOWN FAILURE:
SCRIPT:
```

## Round metrics

Every ~5 rounds, spend 30 seconds on:

```text
SLA trend
flags/minute by exploit
which targets patched
which service is leaking most
which human lane is blocked
```

Then reassign.

## Speed optimization hierarchy

```text
manual repeat action -> script
slow script -> hard timeout
serial independent targets -> bounded parallelism
repeated parsing work -> normalize output
repeated team confusion -> status board
repeated patch regression -> baseline test script
repeated forensic searching -> rotating pcap + grep recipe
```

## Change freeze rule

If your service is stable and the event is in the final rounds:

```text
avoid speculative patches
avoid dependency upgrades
avoid architecture changes
keep known-good exploits running
respond only to evidence-backed threats
```

Late self-inflicted downtime is rarely recoverable in score.

## End-of-round verbal protocol

Each owner reports in one sentence:

```text
"notes UP; IDOR patched; exploit works on 7 teams; automation running."
```

No storytelling during live rounds.

## Done condition

Team is operating well when:

```text
[ ] SLA has an explicit owner
[ ] every service has an owner
[ ] every working exploit is automated
[ ] every deployed patch has rollback
[ ] traffic has an owner
[ ] no person has >2 active tasks
[ ] priorities update from evidence/score, not curiosity
```
