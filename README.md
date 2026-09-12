# attack-defence-skills

Speed-first field kit for **Siege of Servers**, an authorized Attack–Defense CTF. This repository is deliberately split into small skills so you can jump directly to the exact playbook you need under time pressure.

## Win condition

Your score depends on **offense + keeping your own service healthy**. The event checker tests every round; only `UP` counts as a passed SLA check. `CORRUPT`, `MUMBLE`, `DOWN`, and `CHECK FAILED` do not. Stolen flags are short-lived (5 rounds by default), so exploitation and submission must be fast.

## Hard event constraints

- Attack **only other teams' Private IPs** and only the announced service ports.
- Never attack another team's Public IP.
- Never scan, attack, log in to, or tamper with the scoreboard.
- Never use `iptables`, `ufw`, AWS Security Group changes, or any other incoming traffic-blocking mechanism.
- No DDoS/flooding or attacks on organizer infrastructure.
- Official rules allow ChatGPT/Gemini, ban Claude, and ban MCP. If organizers announce stricter rules on event day, their ruling wins.
- Your Ubuntu VM will not be reset for you if you break it. Backup before changing anything.

## 10-second router

Open [`SKILL_ROUTER.md`](SKILL_ROUTER.md).

| Situation | Open |
|---|---|
| Event just started | `skills/01-first-15-minutes/SKILL.md` |
| Need to understand what's running | `skills/02-service-triage/SKILL.md` |
| Web/API service | `skills/03-web-audit/SKILL.md` |
| Native binary/custom daemon | `skills/04-binary-audit/SKILL.md` |
| Need to find flag storage | `skills/05-datastore-flagstore/SKILL.md` |
| Found a bug; need safe patch | `skills/06-minimal-patching/SKILL.md` |
| Checker is failing | `skills/07-sla-checker/SKILL.md` |
| Want to learn from incoming attacks | `skills/08-traffic-intel/SKILL.md` |
| Think your box is compromised | `skills/09-incident-response/SKILL.md` |
| Need a reliable exploit | `skills/10-exploit-engineering/SKILL.md` |
| Need repeated flag collection/submission | `skills/11-flag-automation/SKILL.md` |
| Need round-by-round execution discipline | `skills/12-round-operations/SKILL.md` |
| Need language-specific audit patterns | `skills/13-language-patterns/SKILL.md` |
| Need scoring/target prioritization | `skills/14-scoring-strategy/SKILL.md` |
| Everything is on fire | `skills/99-panic/SKILL.md` |

## Core loop

```text
BACKUP -> BASELINE -> OBSERVE -> FIND BUG -> WEAPONIZE -> PATCH
   ^                                                    |
   |                                                    v
ROLLBACK <- VERIFY SLA <- RESTART SAFELY <- MINIMAL CHANGE

OFFENSE: exploit -> extract current flag -> submit immediately -> repeat
DEFENSE: checker -> logs/pcap -> root cause -> minimal patch -> retest
```

## Speed rules

1. Availability before elegance.
2. One patch per commit.
3. Never change three things at once.
4. Prove exploit locally before patching it.
5. Convert every manual exploit into a timeout-safe script.
6. Keep packet capture bounded; disk exhaustion can kill SLA.
7. Do not broad-scan the VPC. Use only organizer-provided private targets and announced ports.
8. If a patch causes `MUMBLE`, rollback first, redesign second.

## Included helpers

- `scripts/quick_triage.sh` — first-box inventory without network blocking.
- `scripts/health_watch.sh` — listeners/process/service snapshot loop.
- `scripts/pcap_rotate.sh` — bounded rotating packet capture for an announced service port.
- `scripts/diff_watch.sh` — recent-file and Git-change watch.
- `templates/web_exploit.py` — bounded HTTP exploit skeleton for authorized targets.
- `templates/tcp_exploit.py` — bounded TCP exploit skeleton.
- `templates/targets.json.example` — explicit allow-list structure for opponent Private IPs/ports.

Read [`RULES_GUARD.md`](RULES_GUARD.md) before the event.