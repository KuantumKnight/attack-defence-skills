# Skill: Datastore & Flag-Store Tracing

## Trigger

Use when you need to answer: **where does the checker put the flag, how is it identified, and how can it be retrieved?**

## Why this skill matters

In Attack–Defense, a vulnerability is only valuable if it reaches **fresh flags**. Trace storage before polishing an exploit.

## Fast discovery

```bash
find . -type f \( -name '*.db' -o -name '*.sqlite' -o -name '*.sqlite3' -o -name '*.json' -o -name '*.jsonl' -o -name '*.log' \) -print
rg -ni 'flag|secret|token|note|message|content|password|owner|user_id|object_id' .
rg -ni 'sqlite|mysql|postgres|redis|mongodb|DATABASE_URL|DB_HOST|DB_NAME' .
```

## Build the flag lifecycle

Trace one normal checker-like object:

```text
1. CREATE/STORE request
2. identifier returned or derived
3. persistence location
4. retrieval request
5. authorization decision
6. returned secret/flag
```

Write it down as:

```text
STORE: POST /notes -> notes(id, owner, body)
KEY: note_id
READ: GET /notes/:id
AUTH: ???
FLAG FIELD: body
```

The `???` is frequently the bug.

## SQLite

```bash
sqlite3 app.db '.tables'
sqlite3 app.db '.schema'
sqlite3 app.db 'SELECT name FROM sqlite_master WHERE type="table";'
```

Inspect a small sample only:

```bash
sqlite3 -header -column app.db 'SELECT * FROM users LIMIT 5;'
sqlite3 -header -column app.db 'SELECT * FROM notes LIMIT 5;'
```

Watch DB mutations during a local request:

```bash
stat app.db
```

If schema is unfamiliar:

```bash
sqlite3 app.db '.schema TABLENAME'
```

## PostgreSQL

```bash
psql -U USER -d DB
```

Inside:

```text
\l
\dt
\d TABLE
```

Quick read:

```sql
SELECT * FROM table_name LIMIT 5;
```

## MySQL/MariaDB

```bash
mysql -u USER -p
```

Inside:

```sql
SHOW DATABASES;
USE dbname;
SHOW TABLES;
DESCRIBE table_name;
SELECT * FROM table_name LIMIT 5;
```

## Redis

```bash
redis-cli INFO keyspace
redis-cli DBSIZE
redis-cli --scan | head -100
```

Do not use destructive commands. Never `FLUSHALL`/`FLUSHDB` in-game.

## File-backed storage

Trace writes:

```bash
strace -f -e trace=openat,read,write,rename,unlink -s 200 -p PID
```

Recent files:

```bash
find /PATH/TO/SERVICE -type f -mmin -5 -ls
```

Search contents carefully:

```bash
rg -n 'FLAG_PATTERN_OR_KNOWN_TEST_VALUE' /PATH/TO/SERVICE 2>/dev/null
```

Use a **local test marker** rather than a real event flag when experimenting on your own service.

## Authorization audit around storage

For every retrieval path, verify all three:

```text
AUTHENTICATED?
OBJECT EXISTS?
REQUESTER AUTHORIZED FOR THIS OBJECT?
```

Common broken patterns:

```text
SELECT * FROM notes WHERE id = ?              # no owner constraint
SELECT * FROM messages WHERE token = ?         # token predictable/leaked
GET /file?path=<user controlled>               # filesystem flag store
GET /profile/<user_id>                         # no ownership check
```

Safer query shape:

```text
SELECT ... WHERE object_id = ? AND owner_id = CURRENT_USER
```

## CORRUPT response triage

`CORRUPT` means do **not** start deleting state. Check:

```text
DB file exists?
DB reachable?
schema unchanged?
flag/object record still present?
permissions changed?
retrieval handler changed?
session/owner linkage broken?
recent migration/restart reset state?
```

Commands:

```bash
git diff
find . -type f -mmin -15 -ls
journalctl -u SERVICE -n 150 --no-pager
ls -l DB_OR_STORAGE_PATH
```

## Exploit design from flag store

Prefer the shortest primitive:

```text
known/predictable object ID -> unauthorized read -> flag
SQLi -> query flag-bearing row -> flag
traversal -> read flag-bearing file -> flag
logic bug -> switch identity/object owner -> flag
```

Avoid unnecessary RCE if a direct data-read primitive is faster and more reliable.

## Output artifact

Maintain `~/siege/notes/flagstore.txt`:

```text
SERVICE=
STORE_ENDPOINT=
READ_ENDPOINT=
IDENTIFIER=
DATABASE/FILES=
TABLE/KEY/PATH=
OWNER FIELD=
AUTH CHECK LOCATION=
CURRENT EXPLOIT PRIMITIVE=
PATCH LOCATION=
```
