# Skill: Minimal Patching & Rollback

## Trigger

Use the moment you know the vulnerable code path and need to defend without sacrificing SLA.

## Prime directive

Patch **the vulnerability**, not the feature.

```text
keep protocol
keep expected status codes
keep data shape
keep checker workflow
remove exploit primitive
```

## Mandatory sequence

```text
1. prove exploit locally
2. save exploit PoC
3. inspect git status/diff
4. make ONE logical patch
5. restart safely
6. replay baseline functionality
7. verify exploit fails
8. commit
9. watch next checker
```

## Before edit

```bash
cd /PATH/TO/SERVICE
git status --short
git diff
cp TARGET_FILE ~/siege/backups/$(basename TARGET_FILE).$(date +%s)
```

## Patch mappings

### SQL injection

Bad:

```text
SQL + user input
```

Patch:

```text
prepared/parameterized query
```

Do not rely on quote blacklists.

### IDOR

Bad:

```text
fetch object by attacker-controlled ID -> return
```

Patch:

```text
fetch object -> verify owner/ACL -> return
```

Prefer owner-constrained query where possible.

### Command injection

Bad:

```text
shell("cmd " + input)
```

Patch:

```text
argv execution with shell disabled
```

Then validate input semantically if needed.

### Path traversal

Bad:

```text
base + user path
```

Patch:

```text
resolve canonical path -> verify it remains inside base -> open
```

### SSTI

Bad:

```text
user input becomes template source
```

Patch:

```text
fixed template + user input as data
```

### Unsafe deserialization

Bad:

```text
untrusted bytes -> powerful object deserializer
```

Patch:

```text
schema-validated safe format
```

If format is checker-visible, preserve wire protocol and safely transform internally.

### Upload

Preserve upload feature while enforcing:

```text
server-generated storage name
no traversal
bounded size
non-executable storage where practical
format validation required by intended functionality
```

### Memory corruption

Fix the exact bounds/lifetime bug. Do not disable the entire command/menu unless checker never needs it and you have verified that assumption.

## Restart patterns

Systemd:

```bash
sudo systemctl restart SERVICE
sudo systemctl status SERVICE --no-pager
journalctl -u SERVICE -n 80 --no-pager
```

Docker:

```bash
docker compose restart SERVICE
docker compose ps
docker compose logs --tail 80 SERVICE
```

Standalone process: identify the **official launch method** first. Avoid ad-hoc background copies that diverge from the checker-facing service.

## Baseline replay

Keep commands in `~/siege/notes/baseline.sh`.

Typical sequence:

```text
register
login
store object
retrieve own object
perform service-specific action
```

Patch is not done until baseline passes.

## Exploit regression

Run your saved exploit against localhost/original test setup. Expected:

```text
before patch -> succeeds
patch       -> deployed
baseline    -> still succeeds
exploit     -> fails cleanly
```

## Commit discipline

```bash
git add PATHS
git commit -m 'patch: enforce ownership on note retrieval'
```

Good commit messages:

```text
patch: parameterize login lookup
patch: remove shell interpretation from ping action
patch: confine downloads to upload root
patch: validate message owner before read
```

One vulnerability per commit whenever possible.

## Fast rollback

If checker becomes `MUMBLE` immediately after your patch:

```bash
git log --oneline -5
git show --stat HEAD
git revert --no-edit HEAD
# restart service and retest
```

If uncommitted:

```bash
git diff
cp ~/siege/backups/KNOWN_GOOD_FILE TARGET_FILE
```

Prefer `git revert` over destructive history rewrites during the game.

## Forbidden shortcut

Do not compensate for bad application security using firewall or traffic-blocking tools. That is explicitly banned in this event.

## Patch triage matrix

| Situation | Action |
|---|---|
| Exploit actively stealing flags | patch immediately after preserving working exploit |
| Easy remote flag read found | weaponize + patch now |
| Speculative bug, no flag path | queue behind proven bugs |
| Patch risks checker-critical redesign | find narrower fix |
| Patch caused MUMBLE/DOWN | rollback first |
| Multiple patches pending | deploy one at a time |

## Done condition

A patch is complete only when:

```text
[ ] known exploit blocked
[ ] normal store/retrieve still works
[ ] service listening
[ ] logs clean enough to understand
[ ] patch committed
[ ] rollback path known
[ ] next checker watched
```
