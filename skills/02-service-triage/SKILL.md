# Skill: Service Triage & Architecture Mapping

## Trigger

Use when you have an unfamiliar Ubuntu service and need to understand it in minutes.

## Goal

Produce a one-screen architecture map:

```text
PORT -> PROCESS -> SERVICE MANAGER -> CODE DIR -> DEPENDENCIES -> DATASTORE -> FLAG PATH
```

## 60-second host inventory

```bash
ss -lntup
ps auxf
systemctl --type=service --state=running --no-pager
docker ps -a 2>/dev/null || true
sudo lsof -i -P -n | head -150
```

For each announced port, identify PID and executable:

```bash
sudo lsof -nP -iTCP:PORT -sTCP:LISTEN
readlink -f /proc/PID/exe
readlink -f /proc/PID/cwd
cat /proc/PID/cmdline | tr '\0' ' '; echo
```

## Determine launch mechanism

```bash
systemctl status SERVICE --no-pager
systemctl cat SERVICE
journalctl -u SERVICE -n 80 --no-pager
```

Docker:

```bash
docker ps --no-trunc
docker inspect CONTAINER | less
docker logs CONTAINER --tail 100
```

Process tree:

```bash
pstree -ap PID
```

## Architecture clues by files

```bash
find . -maxdepth 3 -type f | sort | sed -n '1,250p'
```

Common markers:

```text
Python   requirements.txt / pyproject.toml / app.py / wsgi.py
Node     package.json / server.js / app.js / dist/
PHP      index.php / composer.json
Go       go.mod / main.go
Java     pom.xml / build.gradle / *.jar
C/C++    ELF binary / Makefile / CMakeLists.txt
Docker   Dockerfile / docker-compose.yml / compose.yml
Nginx    /etc/nginx/sites-enabled/*
Apache   /etc/apache2/sites-enabled/*
```

## Find external dependencies

Environment, with secrets redacted before sharing:

```bash
tr '\0' '\n' < /proc/PID/environ | sort
```

Connections:

```bash
ss -antp
```

Config discovery:

```bash
rg -n 'DATABASE|DB_|REDIS|MYSQL|POSTGRES|SQLITE|HOST|PORT|SECRET|TOKEN|UPLOAD|STORAGE' .
```

## Route/handler map

Do not read linearly. Find application entrypoints:

```bash
rg -n '@app\.(route|get|post|put|delete)|router\.(get|post|put|delete)|app\.(get|post|put|delete)|http\.HandleFunc|@GetMapping|@PostMapping|do_GET|do_POST' .
```

Create a scratch table:

```text
METHOD PATH              AUTH?   INPUTS          SINK/STORAGE
POST   /login            no      user, pass      users DB
POST   /notes            yes     title, body     notes DB
GET    /notes/:id        yes?    id              notes DB
GET    /download         yes?    filename        filesystem
POST   /tools/ping       yes?    host            subprocess
```

Question marks are your first audit targets.

## Flag-store path

Trace one normal object end-to-end:

```text
checker/client request
 -> handler
 -> parsing
 -> auth/session
 -> database/filesystem write
 -> identifier returned
 -> read/retrieval endpoint
```

The easiest attack is often a broken authorization check on the retrieval endpoint, not the fanciest bug in the codebase.

## Baseline functionality tests

Before patching, record known-good behavior with `curl -i` or a tiny script. Capture:

```text
status code
response body shape
cookies/tokens
required fields
object IDs
error behavior
```

Example:

```bash
curl -si http://127.0.0.1:PORT/
curl -si -X POST http://127.0.0.1:PORT/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"baseline_user","password":"baseline_pass"}'
```

## Time-saving rule

If you cannot explain the service in five boxes after 5 minutes, stop reading implementation details and trace one actual request using logs, `strace`, or application-level debug output.

## Output artifact

Keep this in `~/siege/notes/service-map.txt`:

```text
SERVICE=
PORT=
PID/CONTAINER=
START=
RESTART=
LOGS=
CODE=
DB=
FLAG_WRITE_PATH=
FLAG_READ_PATH=
AUTH_MECHANISM=
TOP_3_BUG_HYPOTHESES=
LAST_KNOWN_GOOD_COMMIT=
```
