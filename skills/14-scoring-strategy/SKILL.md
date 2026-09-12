# Skill: Scoring Strategy & Target Priority

## Trigger

Use when choosing between defense work, exploit development, and which teams to hit first.

## Event scoring facts

The official rules define:

```text
SLA % = passed checker runs / total checker runs * 100
Task contribution = Task Points * SLA% / 100
```

Only `UP` is a passed check.

Flag transfer is dynamic:

```text
opponent similar score -> medium reward
opponent higher score  -> more reward
opponent lower score   -> less reward
```

Flags are valid for a limited number of rounds — **5 by default** — and a team can score a given stolen flag only once.

## Strategic consequence

Your offense is not independent of defense.

```text
points gained offensively
        x
service availability multiplier
        =
real counted value
```

Therefore prolonged downtime can erase the value of successful attacks.

## Priority function

For each candidate task, think in terms of:

```text
EXPECTED_VALUE ≈
(success_probability * flags_per_round * reward_per_flag * remaining_rounds)
- SLA_risk
- engineer_time_cost
```

You do not need exact arithmetic. Rank relative value.

## Target ranking

For a working exploit:

```text
Tier A: stronger/high-score teams where exploit still works
Tier B: similar-score teams where exploit still works
Tier C: lower-score teams where exploit still works
Tier D: repeatedly patched/timeout targets
```

If exploit cost is tiny and bounded, hit all official targets. If expensive, prioritize A then B.

## Exploit ranking

Prefer:

```text
reliable direct flag read
> reliable auth/logic exploit
> reliable SQLi/traversal
> complex RCE that still needs flag discovery
> brittle pwn requiring manual timing
```

Again, this is **points-per-minute**, not severity.

## Defense ranking

Patch in this order:

```text
1. exploit visibly stealing current flags
2. unauthenticated direct flag-store read
3. trivial widespread exploit primitive
4. RCE/state-tamper bug
5. crash bug threatening SLA
6. speculative vulnerabilities
```

## When to stop patching

Do not chase speculative hardening if:

```text
service is UP
no exploit evidence exists
working offense is producing points
patch risks checker-critical behavior
```

Queue it instead.

## When to stop exploit research

Park an exploit when:

```text
no flag-store path after 10–15 focused minutes
opponents broadly patched it
success rate too low for automation
another service has a much cheaper primitive
own SLA needs attention
```

## Fresh flag rule

Because flags expire, submission latency matters.

Priority:

```text
newest current-round flag
-> previous still-valid flags
-> never spend time retrying clearly expired flags
```

If an old flag was already submitted by your team, skip it permanently.

## Defender's paradox

Do not take your service down to protect flags. Under these rules:

```text
DOWN = failed SLA
AND own task downtime may also interfere with stolen-flag submission depending on event settings
```

The right defense is a functional patch.

## Scoreboard discipline

Use scoreboard only for documented viewing/submission. Never scan or probe it.

Read it strategically:

```text
Which teams are above us?
Which service/task are we bleeding on?
Did SLA drop after last patch?
Did an exploit stop generating accepted submissions?
```

## 5-round review

Every few rounds, ask:

```text
Highest flags/minute exploit?
Worst SLA task?
Which target tier is paying best?
Which patch saved most leakage?
Which human task can be killed/reassigned?
```

Then deliberately shift effort.

## Final-round strategy

Late game:

```text
protect UP state
keep known-good automation running
avoid speculative refactors
prioritize fresh flags only
patch only evidence-backed active leaks
```

A late `DOWN` can cost more than one last uncertain exploit is worth.
