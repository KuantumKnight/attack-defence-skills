# Skill Router

Use this file like an incident-response switchboard. Do not read the repo linearly during the match.

## Immediate routing

| Symptom / goal | Open this skill | First action |
|---|---|---|
| Match just started | `skills/01-first-15-minutes/SKILL.md` | Inventory, backup, capture, baseline |
| Unknown service/processes | `skills/02-service-triage/SKILL.md` | `ss -lntup && ps auxf` |
| HTTP/API app | `skills/03-web-audit/SKILL.md` | map routes, sinks, auth, datastore |
| ELF/native/custom TCP | `skills/04-binary-audit/SKILL.md` | `file`, `checksec`, `strings`, `strace` |
| Need location of flags | `skills/05-datastore-flagstore/SKILL.md` | trace create/store/retrieve path |
| Vulnerability found | `skills/06-minimal-patching/SKILL.md` | weaponize first, then one minimal patch |
| `DOWN` | `skills/07-sla-checker/SKILL.md` | listener -> process -> logs -> dependency |
| `MUMBLE` | `skills/07-sla-checker/SKILL.md` | rollback newest patch first |
| `CORRUPT` | `skills/07-sla-checker/SKILL.md` | inspect datastore and retrieval path |
| Weird incoming request | `skills/08-traffic-intel/SKILL.md` | preserve pcap/log, identify endpoint/sink |
| Unexpected process/file | `skills/09-incident-response/SKILL.md` | preserve evidence, restore app, patch root cause |
| Exploit works manually | `skills/10-exploit-engineering/SKILL.md` | make deterministic + timeout-safe |
| Need recurring flags | `skills/11-flag-automation/SKILL.md` | allow-listed targets + bounded concurrency |
| Team losing execution tempo | `skills/12-round-operations/SKILL.md` | use round loop and ownership board |
| Need grep patterns | `skills/13-language-patterns/SKILL.md` | jump to language section |
| Need target priority | `skills/14-scoring-strategy/SKILL.md` | high-score vulnerable targets first |
| Multiple failures at once | `skills/99-panic/SKILL.md` | freeze changes, restore SLA, then offense |

## 30-second decision tree

```text
IS OWN SERVICE HEALTHY?
  |
  +-- NO --> 07 SLA/checker
  |            |
  |            +-- recent patch? --> rollback
  |            +-- process dead? --> logs/restart
  |            +-- CORRUPT? --> datastore path
  |
  +-- YES --> ARE FLAGS BEING STOLEN?
               |
               +-- YES --> 08 traffic intel -> 06 patch
               |
               +-- NO --> DO WE HAVE A WORKING EXPLOIT?
                           |
                           +-- NO --> 03/04 audit -> 10 exploit
                           +-- YES --> 11 automation -> 14 targeting
```

## Bug discovery priority

Search in this order because it maximizes points per minute:

```text
1. IDOR / missing authorization
2. SQL injection / datastore query bugs
3. command injection / unsafe process execution
4. path traversal / arbitrary file read
5. obvious hardcoded secret / auth bypass
6. unsafe deserialization / SSTI / SSRF / upload flaws
7. race/logic bugs
8. native memory corruption and deeper reversing
```

This is not a universal severity ranking. It is a **speed ranking for Attack–Defense**: easy-to-reproduce, easy-to-automate flag reads come first.

## Patch priority

Patch based on evidence, not aesthetics:

```text
ACTIVE EXPLOIT SEEN > EASY FLAG READ > REMOTE CODE EXECUTION > AUTH BYPASS >
flag-store exposure > crash bug > speculative hardening
```

## Time budgets

- 2 min: identify process, port, service directory.
- 3 min: backup + Git baseline.
- 5 min: first dangerous-call grep and route/dataflow map.
- 10 min per hypothesis: prove or kill it.
- 5 min after exploit works: script it.
- 3 min after patch: functional test + checker observation.

If a hypothesis burns 10 minutes with no evidence, park it and switch.