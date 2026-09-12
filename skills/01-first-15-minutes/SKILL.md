# Skill: First 15 Minutes

## Trigger

Use immediately after credentials, Private IP, service ports, and start signal are issued.

## Objective

Reach this state as fast as possible:

```text
service identified
service backed up
Git baseline exists
logs/pcap visible
checker-critical workflow understood enough not to break it
first vulnerability hypothesis assigned
```

## Minute 0–2 — orient

```bash
whoami
hostname
ip -br addr
ip route
uname -a
cat /etc/os-release
ss -lntup
ps auxf
systemctl --type=service --state=running --no-pager
docker ps -a 2>/dev/null || true
```

Write down immediately:

```text
MY_PUBLIC_IP=
MY_PRIVATE_IP=
SERVICE_NAME=
SERVICE_PORT=
SERVICE_PROCESS=
SERVICE_DIR=
DB_TYPE/FILE=
RESTART_COMMAND=
LOG_COMMAND=
```

Do not probe other hosts until organizer scope is explicit.

## Minute 2–5 — locate service and dependencies

```bash
sudo lsof -i -P -n | head -100
find /opt /srv /var/www /home -maxdepth 3 -type f \
  \( -name 'docker-compose.yml' -o -name 'compose.yml' -o -name 'package.json' \
  -o -name 'requirements.txt' -o -name 'pyproject.toml' -o -name 'go.mod' \
  -o -name 'pom.xml' -o -name '*.jar' -o -name '*.service' \) 2>/dev/null
```

For a PID:

```bash
readlink -f /proc/PID/exe
readlink -f /proc/PID/cwd
tr '\0' '\n' < /proc/PID/environ | sed -E 's/(PASS|TOKEN|SECRET|KEY)=.*/\1=<redacted>/'
```

## Minute 5–7 — backup before touching code

```bash
mkdir -p ~/siege/{backups,notes,logs,pcaps,exploits}
sudo tar czf ~/siege/backups/service-original-$(date +%s).tgz /PATH/TO/SERVICE
```

If source is not already versioned:

```bash
cd /PATH/TO/SERVICE
git init
git add .
git commit -m 'baseline: original service'
```

Capture basic state:

```bash
ss -lntup > ~/siege/notes/listeners.initial
ps auxf > ~/siege/notes/processes.initial
find /PATH/TO/SERVICE -type f -exec sha256sum {} \; > ~/siege/notes/hashes.initial
```

## Minute 7–9 — start bounded visibility

For the **announced service port** only:

```bash
sudo tcpdump -i any -nn -s0 -C 40 -W 8 \
  -w ~/siege/pcaps/service.pcap port ANNOUNCED_PORT &
```

Logs:

```bash
journalctl -u SERVICE -f
# or
docker logs -f --tail 100 CONTAINER
# or
tail -F /var/log/nginx/access.log /var/log/nginx/error.log
```

## Minute 9–12 — 3-minute code triage

```bash
cd /PATH/TO/SERVICE
rg -n 'eval\(|exec\(|system\(|popen\(|subprocess|shell=True|pickle|yaml\.load|unserialize|readObject|Runtime\.getRuntime|ProcessBuilder|SELECT|INSERT|UPDATE|DELETE|render_template_string|send_file|open\(|file_get_contents|http\.Get|requests\.get|fetch\(' .
```

Then map:

```text
ENTRYPOINTS -> AUTH -> STORAGE -> RETRIEVAL -> DANGEROUS SINKS
```

Do not read every file. Find routes/handlers first, then trace user-controlled data.

## Minute 12–15 — choose one bug and split work

Pick the bug with the shortest path to **reading another user's stored secret/flag**.

Priority:

```text
IDOR > SQLi > command injection > traversal > auth bypass > deserialization/SSTI > pwn
```

For the selected bug:

```text
A: prove locally / write exploit
B: understand minimal patch
C: watch traffic/checker if team size permits
```

Do not patch until the offensive path is understood unless the service is actively losing flags and immediate containment is required.

## Exit condition

You are ready for normal rounds only when:

- original service is restorable;
- restart and log commands are known;
- service/port/process are mapped;
- packet/log visibility is running;
- someone owns SLA monitoring;
- someone owns the highest-confidence exploit hypothesis.
