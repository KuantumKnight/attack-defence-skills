# Skill: Traffic Intelligence

## Trigger

Use when incoming traffic may reveal checker behavior, active exploits, or an opponent's working attack primitive.

## Objective

Turn packet/log evidence into:

```text
request -> vulnerable endpoint -> vulnerable sink -> local reproduction -> patch -> exploit automation
```

## Capture safely

Use the **announced service port** and bounded rotation:

```bash
mkdir -p ~/siege/pcaps
sudo tcpdump -i any -nn -s0 -C 40 -W 8 \
  -w ~/siege/pcaps/service.pcap port PORT &
```

For short live inspection:

```bash
sudo tcpdump -i any -nn -A port PORT
```

Avoid unlimited capture. Disk exhaustion can become self-inflicted `DOWN`.

## HTTP quick extraction

```bash
tshark -r FILE.pcap -Y 'http.request' \
  -T fields -e frame.time -e ip.src -e http.request.method -e http.host -e http.request.uri
```

Payload-oriented search:

```bash
strings FILE.pcap | grep -Ei \
  'union|select|\.\./|/etc/passwd|%2e%2e|__proto__|pickle|cmd=|exec|flag|secret|token'
```

## TCP stream reconstruction

List conversations:

```bash
tshark -r FILE.pcap -q -z conv,tcp
```

Follow a stream:

```bash
tshark -r FILE.pcap -q -z follow,tcp,ascii,STREAM_NUMBER
```

## Log-first workflow for web apps

Nginx:

```bash
tail -F /var/log/nginx/access.log /var/log/nginx/error.log
```

Apache:

```bash
tail -F /var/log/apache2/access.log /var/log/apache2/error.log
```

Systemd app:

```bash
journalctl -u SERVICE -f
```

## Checker fingerprinting

At the start, record recurring benign request patterns:

```text
source characteristics
request sequence
timing
paths/methods
status codes
object creation/read pattern
```

Use this only to understand **what functionality the checker requires**. Do not build traffic-blocking rules; this event explicitly bans incoming traffic blocking.

## Suspicious-request triage

For every unusual request:

```text
1. save exact timestamp
2. save source/destination/port
3. reconstruct payload
4. locate matching route/handler
5. trace user input to sink
6. reproduce on localhost
7. classify vulnerability
8. preserve a working PoC
9. patch minimally
10. adapt PoC into authorized opponent exploit if applicable
```

## High-signal patterns

### SQLi

```text
' OR
UNION SELECT
comment syntax
SQL errors
```

### Traversal/LFI

```text
../
%2e%2e
/etc/passwd
absolute file paths
```

### Command injection

```text
;
&&
||
$()
backticks
/bin/sh
```

### SSTI

Unexpected template expressions or computed output in fields that should be plain text.

### Deserialization

Large opaque serialized blobs, encoded object streams, pickle/PHP/Java serialization signatures.

### Pwn

Unusual binary payload lengths, repeated padding, addresses/pointers, staged protocol interactions, crashes immediately following a request.

## Build a replay artifact

For HTTP, convert the observed flow into a minimal `curl` or Python request. Remove irrelevant headers/cookies until only the exploit-critical pieces remain.

For TCP, create a deterministic socket script or pwntools-style transcript.

## Do not overfit attribution

The important question is not "which team sent this?" but:

```text
WHAT WORKED?
WHERE IS THE BUG?
CAN WE PATCH IT?
CAN WE USE THE SAME PRIMITIVE AGAINST AUTHORIZED OPPONENT SERVICES?
```

## Fast pcap notes format

Maintain:

```text
TIME | ENDPOINT | PATTERN | LOCAL REPRO? | VULN | PATCHED? | EXPLOIT SCRIPT
```

Example:

```text
09:48 | GET /note/1842 | cross-user ID | yes | IDOR | yes | exploits/note_idor.py
```

## Exit condition

Traffic intel has succeeded when one captured interaction produces at least one of:

- checker contract knowledge;
- confirmed active vulnerability;
- minimal patch;
- reliable reusable exploit.
