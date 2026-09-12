# Skill: Web/API Audit — Speed First

## Trigger

Use when the announced service is HTTP/HTTPS, REST, GraphQL, or a web-backed application.

## Objective

Find the shortest exploit path to another user's stored flag **without breaking your own checker**.

## 5-minute audit order

```text
1. routes/endpoints
2. auth/session model
3. object ownership checks
4. SQL/ORM queries
5. shell/process calls
6. filesystem paths
7. templates/deserialization/uploads/fetches
8. hidden/admin/debug endpoints
```

## Route discovery

```bash
rg -n '@app\.(route|get|post|put|delete)|app\.(get|post|put|delete)|router\.(get|post|put|delete)|@GetMapping|@PostMapping|http\.HandleFunc|Blueprint\(' .
```

For each route, mark:

```text
AUTH?  INPUT?  OBJECT ID?  SINK?  FLAG-STORE RELATED?
```

## 1. IDOR / missing authorization

This is the first thing to test because it is often the fastest flag read.

Look for handlers like:

```text
get_note(id)
get_message(id)
download(file_id)
profile(user_id)
secret(object_id)
```

Bad logic:

```text
request is authenticated
-> query object by supplied ID
-> return object
```

Required logic:

```text
request is authenticated
-> query object
-> verify object.owner == current_user OR explicit allowed ACL
-> return object
```

Test on your own service by creating two users and trying to read user A's object as user B.

## 2. SQL injection

Search:

```bash
rg -n 'SELECT|INSERT|UPDATE|DELETE|execute\(|query\(|raw\(|createStatement|fmt\.Sprintf' .
```

High-risk pattern:

```text
SQL text + user-controlled string
```

Quick local probes only against your own copy first:

```text
'
"
' OR '1'='1
' OR 1=1--
```

Patch with parameterized queries, not quote blacklists.

## 3. Command injection

Search:

```bash
rg -n 'os\.system|subprocess|shell=True|exec\(|execFile|child_process|Runtime\.getRuntime|ProcessBuilder|os/exec|Command\(' .
```

Trace user-controlled values into shell/process APIs.

Bad:

```text
shell("tool " + user_input)
```

Preferred:

```text
execve-style argv: ["tool", user_input]
```

## 4. Path traversal / arbitrary file read

Search:

```bash
rg -n 'send_file|send_from_directory|open\(|ReadFile|file_get_contents|fs\.readFile|Files\.read|filepath\.Join|Path\(' .
```

Probe locally:

```text
../../../../etc/passwd
..%2f..%2f..%2fetc%2fpasswd
```

Patch by canonicalizing and verifying the final path remains under the intended base directory.

## 5. Authentication/session flaws

Inspect:

```text
login
registration
password reset
JWT creation/verification
session cookies
role checks
admin checks
```

Search:

```bash
rg -n 'jwt|JWT|session|cookie|secret|admin|role|is_admin|password|bcrypt|argon|verify' .
```

Fast questions:

```text
Can I change user_id/role in a token?
Is signature verification disabled or optional?
Is there a hardcoded signing secret?
Does admin check trust request input?
Does logout actually revoke anything checker-critical?
```

## 6. SSTI

High-risk pattern:

```text
user input becomes template SOURCE, not just template DATA
```

Search:

```bash
rg -n 'render_template_string|Template\(|from_string|render\(|compile\(' .
```

Patch by using a fixed template and passing data as variables.

## 7. Unsafe deserialization

Search:

```bash
rg -n 'pickle\.loads|yaml\.load|unserialize|ObjectInputStream|readObject|deserialize|marshal|gob\.NewDecoder' .
```

Ask whether attacker-controlled bytes can reach the deserializer.

If yes, replace with a safe format/schema where checker compatibility permits.

## 8. SSRF

Search:

```bash
rg -n 'requests\.get|requests\.post|urllib|http\.Get|fetch\(|axios|HttpClient|URL\(' .
```

Trace whether the user controls destination URL/host.

Patch with strict destination allow-lists when the feature genuinely requires server-side fetching.

## 9. Upload flaws

Map:

```text
filename
content type
actual file bytes
storage directory
served/executed later?
path construction
```

Safe patch properties:

```text
server-generated filename
stored outside executable webroot where possible
size limit
format validation when functionality requires it
no user path traversal
```

## 10. Prototype pollution / object merge bugs

Node-focused search:

```bash
rg -n '__proto__|constructor|prototype|merge|assign|deep' .
```

Watch recursive merge code that copies arbitrary attacker keys.

## Request reproduction

Always preserve a working request as a replayable command:

```bash
curl -si -X POST http://127.0.0.1:PORT/endpoint \
  -H 'Content-Type: application/json' \
  -H 'Cookie: session=...' \
  -d '{"key":"value"}'
```

Then change **one variable at a time**.

## Exploit-to-patch sequence

```text
identify endpoint
-> make minimal local proof
-> find flag-store relationship
-> build reliable exploit
-> test against ONE authorized opponent Private IP
-> patch your copy
-> baseline functionality test
-> watch next checker
-> automate offense
```

## Stop conditions

Park a hypothesis if:

- you cannot show attacker-controlled data reaches the suspected sink;
- checker functionality would require a major redesign to patch;
- another hypothesis offers a faster path to flags.

Speed comes from killing weak hypotheses early.