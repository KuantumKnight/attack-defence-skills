# Skill: Incident Response on the Vulnbox

## Trigger

Use when you see unexpected processes, modified files, suspicious requests, unexplained checker failures, or signs another team achieved code execution.

## Objective

Restore a known-good service, preserve enough evidence to learn the exploit, and patch the root cause without violating the no-firewall rule.

## 60-second snapshot

```bash
date -Is
ps auxf
ss -antup
last -a | head -30
find /tmp /var/tmp -type f -mmin -30 -ls 2>/dev/null
find /PATH/TO/SERVICE -type f -mmin -30 -ls 2>/dev/null
git -C /PATH/TO/SERVICE status --short
git -C /PATH/TO/SERVICE diff
```

Systemd/logs:

```bash
journalctl -u SERVICE --since '-30 min' --no-pager
```

## Preserve before cleaning

If practical, save:

```bash
mkdir -p ~/siege/incidents/$(date +%Y%m%d-%H%M%S)
DIR=$(ls -dt ~/siege/incidents/* | head -1)
ps auxf > "$DIR/processes.txt"
ss -antup > "$DIR/sockets.txt"
cp -a /PATH/TO/RELEVANT/LOG "$DIR/" 2>/dev/null || true
git -C /PATH/TO/SERVICE diff > "$DIR/service.diff"
```

Do not spend 20 minutes doing forensics while SLA burns. Preserve high-signal evidence, then restore.

## Triage categories

### A. Application files modified

Compare Git/baseline:

```bash
git -C /PATH/TO/SERVICE status --short
git -C /PATH/TO/SERVICE diff
```

Restore only files you know should be clean. Do not overwrite live datastore files with stale backups by accident.

### B. Unexpected process

Inspect before killing if time permits:

```bash
ps -fp PID
readlink -f /proc/PID/exe
readlink -f /proc/PID/cwd
tr '\0' ' ' < /proc/PID/cmdline; echo
ls -l /proc/PID/fd | head -50
```

If clearly malicious and not checker/service-critical, terminate it, then patch the exploit path that launched it.

### C. Unexpected SSH access

```bash
last -a | head -50
find /root /home -path '*/.ssh/authorized_keys' -type f -print -exec sed -n '1,40p' {} \; 2>/dev/null
```

Do not change event credentials blindly if organizers/checkers depend on them; follow event rules and organizer guidance.

### D. Database/state tampering

Check timestamps, schema, permissions, and app logs. Avoid destructive DB recovery commands.

### E. Persistence mechanism

Inspect:

```bash
crontab -l 2>/dev/null
sudo crontab -l 2>/dev/null
find /etc/cron* -maxdepth 2 -type f -ls 2>/dev/null
systemctl list-timers --all --no-pager
systemctl --type=service --state=running --no-pager
```

If an attacker altered startup/service files, restore from baseline and restart only the intended service.

## Root-cause workflow

```text
artifact/request
 -> how did attacker reach service?
 -> which input was controlled?
 -> which code path handled it?
 -> what primitive was gained?
 -> what file/process/state changed?
 -> narrow patch at root cause
```

Do not confuse cleanup with remediation. Killing a process without fixing the vulnerable handler guarantees repeat compromise.

## Recovery order

```text
1. preserve evidence
2. restore service code/config to known good
3. remove clearly malicious runtime artifacts
4. patch root cause
5. syntax/build check
6. restart once
7. replay baseline
8. verify exploit no longer works
9. commit patch
10. watch checker + traffic
```

## File integrity comparison

```bash
sha256sum -c ~/siege/notes/hashes.initial 2>/dev/null | grep -v ': OK$'
```

Expect legitimate changes in DB/cache/log files; focus on code/config/binaries.

## Useful recent-change views

```bash
find /PATH/TO/SERVICE -type f -printf '%TY-%Tm-%Td %TH:%TM:%TS %p\n' | sort -r | head -100
find /etc/systemd /etc/cron* /tmp /var/tmp -type f -mmin -60 -ls 2>/dev/null
```

## What not to do

```text
DO NOT install/block with a firewall.
DO NOT DDoS/retaliate.
DO NOT attack source IPs outside official target scope.
DO NOT wipe /tmp, databases, or user data indiscriminately.
DO NOT reboot the whole VM unless absolutely necessary.
DO NOT overwrite the only live flag store with an old backup without understanding impact.
```

## Exit condition

Incident is contained when:

```text
[ ] service is UP locally
[ ] baseline workflow works
[ ] malicious runtime artifact removed
[ ] root-cause patch deployed
[ ] exploit regression fails
[ ] code/config integrity understood
[ ] relevant pcap/log evidence saved
[ ] patch committed and rollback known
```
