# PANIC SKILL — Everything Is On Fire

Open this when you have seconds, not minutes.

## Rule zero

```text
DO NOT firewall.
DO NOT touch scoreboard except normal view/submit.
DO NOT attack Public IPs.
DO NOT flood.
```

## Own service DOWN

```bash
ss -lntup
ps auxf
systemctl status SERVICE --no-pager
journalctl -u SERVICE -n 100 --no-pager
df -h
```

Docker:

```bash
docker ps -a
docker logs CONTAINER --tail 100
```

If recent patch caused it:

```bash
cd /PATH/TO/SERVICE
git log --oneline -5
git revert --no-edit HEAD
sudo systemctl restart SERVICE
```

Then baseline test.

## MUMBLE

```text
reachable + wrong behavior
```

Do:

```bash
git diff
git log --oneline -5
journalctl -u SERVICE -n 120 --no-pager
```

**Recent patch? Roll it back first.**

## CORRUPT

```text
flag/state missing or retrieval broken
```

Check:

```bash
ls -l DB_OR_STORAGE
find /PATH/TO/SERVICE -type f -mmin -20 -ls
git diff
journalctl -u SERVICE -n 120 --no-pager
```

Do **not** wipe/reset database.

## Flags are being stolen

```text
1. preserve exact request/pcap
2. map request -> route -> sink
3. reproduce locally
4. save exploit
5. patch root cause minimally
6. baseline test
7. automate same primitive against authorized opponents
```

Live view:

```bash
sudo tcpdump -i any -nn -A port ANNOUNCED_PORT
```

## Box appears compromised

```bash
ps auxf
ss -antup
find /tmp /var/tmp -type f -mmin -30 -ls 2>/dev/null
find /PATH/TO/SERVICE -type f -mmin -30 -ls
git -C /PATH/TO/SERVICE status --short
git -C /PATH/TO/SERVICE diff
last -a | head -30
```

Preserve evidence, restore app code/config, remove clearly malicious runtime artifacts, patch root cause, restart once.

## Need a bug NOW

```bash
cd /PATH/TO/SERVICE
rg -n 'eval\(|exec\(|system\(|popen\(|subprocess|shell=True|pickle|yaml\.load|unserialize|readObject|Runtime\.getRuntime|SELECT|INSERT|UPDATE|DELETE|render_template_string|send_file|open\(' .
```

Then inspect in order:

```text
IDOR
SQLi
command injection
traversal
hardcoded auth/secret
unsafe deserialization/SSTI
pwn
```

## Manual exploit works

Stop doing it by hand.

Make script:

```text
TARGET_IP TARGET_PORT [FLAG_ID]
2s-ish timeout
one clean flag output
bounded retry
```

Test one opponent, then bounded parallel runner.

## Submission urgency

Official default flag lifetime: **5 rounds**.

```text
CURRENT FLAGS FIRST.
SUBMIT IMMEDIATELY.
DEDUP EVERYTHING.
```

## Team lost coordination

Say exactly:

```text
A = SLA/rollback
B = patch/service audit
C = exploit/automation
D = traffic/submission
```

Then status each service:

```text
SERVICE | UP? | VULN | EXPLOIT | PATCH | OWNER
```

## Never do under panic

```text
rebuild whole app
upgrade dependencies
randomly chmod/chown everything
wipe DB
reboot unless absolutely necessary
broad-scan VPC
increase exploit workers wildly
make 3 patches at once
```

## The recovery loop

```text
RESTORE UP
  -> preserve exploit intelligence
  -> patch one root cause
  -> verify baseline
  -> commit
  -> resume offense
```
