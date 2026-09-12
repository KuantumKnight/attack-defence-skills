# Skill: Binary / Custom Daemon Audit

## Trigger

Use for ELF binaries, custom TCP protocols, C/C++ services, or opaque daemons where source is absent or incomplete.

## Goal

Identify protocol, dangerous memory operations, flag-store path, and the fastest reliable exploit/patch pair.

## 90-second fingerprint

```bash
file ./service
sha256sum ./service
checksec --file=./service 2>/dev/null || true
ldd ./service 2>/dev/null || true
strings -a -n 4 ./service | less
```

Record:

```text
ARCH=
PIE=
NX=
CANARY=
RELRO=
STRIPPED=
PORT=
PROTOCOL=
```

## Identify protocol before reversing deeply

Observe your own service locally:

```bash
nc 127.0.0.1 PORT
```

or:

```bash
socat - TCP:127.0.0.1:PORT
```

Capture one benign session:

```bash
sudo tcpdump -i lo -nn -A port PORT
```

Determine whether protocol is:

```text
line-based text
length-prefixed binary
JSON over TCP
HTTP-like
menu-driven
custom framed messages
```

## Runtime tracing

System calls:

```bash
strace -f -s 256 -o /tmp/service.strace ./service
```

Library calls:

```bash
ltrace -f -s 256 -o /tmp/service.ltrace ./service 2>/dev/null || true
```

Search traces for:

```text
open/openat
read/write
recv/send
execve
system
connect
sqlite/mysql/postgres access
flag/secret filenames
```

## Static danger scan

```bash
strings -a ./service | grep -Ei 'flag|secret|pass|token|/tmp|/bin/sh|system|debug|admin|sqlite|mysql|postgres'
```

With source:

```bash
rg -n 'gets\(|strcpy\(|strcat\(|sprintf\(|scanf\(|memcpy\(|memmove\(|system\(|popen\(|printf\([^,]*\)|read\(|recv\(' .
```

High-value classes:

```text
format string
stack overflow
heap overflow
use-after-free/double free
integer truncation/overflow -> bad size
command execution
unchecked index/ID
logic/auth bug
unsafe temporary-file handling
```

## GDB fast path

```bash
gdb -q ./service
```

Useful commands:

```gdb
set disassembly-flavor intel
info functions
break main
run
bt
info registers
x/32gx $rsp
disassemble /m main
```

Crash triage:

```bash
ulimit -c unlimited
```

Inside gdb:

```gdb
run < input
bt
info registers
```

## Fuzz minimally, not noisily

Against **your own local service**, vary one field at a time:

```text
empty
1 byte
boundary length-1
boundary length
boundary length+1
large but reasonable
negative value if parser is signed
max integer
repeated format tokens
invalid object index
```

Do not use load/flood fuzzing against opponent systems.

## Format-string recognition

Red flag:

```c
printf(user_controlled);
```

Patch:

```c
printf("%s", user_controlled);
```

If checker output relies on exact text, preserve formatting semantics.

## Bounds bug recognition

Bad pattern:

```text
fixed buffer
+ attacker-controlled read length
```

Patch principles:

```text
cap reads to destination capacity
reserve space for terminator where needed
validate signed/unsigned conversions
check indexes before dereference
```

## Flag-store tracing

The best pwn bug is only useful if it reaches current flags. Trace where normal protocol operations store/retrieve secrets:

```bash
strace -f -e trace=file,read,write,network -s 256 ./service
```

Look for database/file paths created after a normal 'store' operation.

## Patch discipline

Prefer source-level fix when source is present.

If only a binary exists:

1. backup binary;
2. understand exact vulnerable branch/call;
3. make the smallest binary change possible;
4. restart;
5. replay baseline protocol;
6. keep instant rollback.

Do not randomly NOP security-sensitive paths without understanding checker behavior.

## Exploit reliability checklist

Before automation:

```text
[ ] deterministic protocol state
[ ] 1–2 second connection timeout
[ ] no interactive/manual step
[ ] current flag extracted exactly
[ ] connection closes cleanly
[ ] failure returns quickly
[ ] exploit works repeatedly against your local original service
```

## Time-box rule

If native exploitation is consuming 20+ minutes while a web/auth/IDOR path exists on another service, reassign. Deep pwn is valuable only when its expected points exceed the time cost.