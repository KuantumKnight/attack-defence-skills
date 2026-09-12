# Skill: Language-Specific Dangerous Patterns

## Trigger

Use when you know the implementation language and want a high-signal grep before reading code deeply.

## Python

```bash
rg -n 'eval\(|exec\(|os\.system|subprocess|shell=True|pickle\.loads|yaml\.load|render_template_string|send_file|sqlite|execute\(|requests\.(get|post)|open\(' .
```

High-risk:

```python
os.system("cmd " + user)
subprocess.run(user, shell=True)
pickle.loads(request.data)
yaml.load(untrusted)
render_template_string(user)
db.execute("..." + user)
```

Safer patterns:

```text
subprocess argv + shell=False
parameterized SQL
fixed template + variables
safe schema/JSON instead of pickle
resolved-path confinement
```

## PHP

```bash
rg -n 'eval\(|system\(|exec\(|shell_exec|passthru|include\(|require\(|unserialize\(|mysqli_query|PDO|move_uploaded_file|file_get_contents' .
```

High-risk:

```php
system($_GET['cmd']);
include($_GET['page']);
unserialize($_POST['data']);
$query = "SELECT ..." . $_GET['id'];
```

Use prepared statements and fixed include paths.

## Node.js / JavaScript / TypeScript

```bash
rg -n 'eval\(|child_process|exec\(|spawn\(|execFile\(|deserialize|__proto__|constructor|prototype|sequelize\.query|mongoose|jwt|fs\.readFile|path\.join|axios|fetch\(' .
```

High-risk:

```text
exec("cmd " + input)
recursive deep merge of arbitrary keys
raw SQL string composition
JWT claims trusted without verification
path.join(base, attacker) without confinement
```

Prefer `execFile`/`spawn` with argument arrays when process execution is necessary.

## Java

```bash
rg -n 'Runtime\.getRuntime|ProcessBuilder|ObjectInputStream|readObject|createStatement|executeQuery|ScriptEngine|Files\.read|Paths\.get|HttpClient' .
```

High-risk:

```java
Runtime.getRuntime().exec(userInput)
new ObjectInputStream(untrusted).readObject()
Statement + concatenated SQL
```

Prefer `PreparedStatement` for SQL and avoid native Java deserialization of attacker-controlled data.

## Go

```bash
rg -n 'os/exec|exec\.Command|database/sql|fmt\.Sprintf|template\.HTML|filepath\.Join|os\.ReadFile|http\.Get|url\.Parse' .
```

High-risk:

```go
exec.Command("sh", "-c", user)
fmt.Sprintf("SELECT ... %s", user)
template.HTML(user)
```

Prefer placeholders in `database/sql`, direct argv execution, and `html/template` auto-escaping.

## C / C++

```bash
rg -n 'gets\(|strcpy\(|strcat\(|sprintf\(|vsprintf\(|scanf\(|memcpy\(|memmove\(|system\(|popen\(|printf\([^,]*\)|read\(|recv\(' .
```

High-risk:

```text
unbounded copy into fixed buffer
attacker-controlled size into read/recv
printf(user)
unchecked signed length/index
use-after-free/double-free paths
system/popen with attacker data
```

Runtime:

```bash
file ./service
checksec --file=./service
strings -a ./service | less
strace -f -s 256 ./service
ltrace -f -s 256 ./service 2>/dev/null
```

## Flask/FastAPI/Django hot spots

```text
routes/views
request.args/request.form/request.json
raw SQL
render_template_string
send_file/path handling
session/JWT/current_user
object lookup by URL ID
```

## Express/Nest hot spots

```text
req.params / req.query / req.body
middleware order
auth guards
ORM raw queries
child_process
object merge/update code
file upload/download endpoints
```

## Spring hot spots

```text
@GetMapping/@PostMapping
@RequestParam/@PathVariable/@RequestBody
repository query construction
role annotations vs actual ownership checks
ObjectInputStream
ProcessBuilder
```

## Language-independent taint rule

Always think:

```text
SOURCE -> TRANSFORM -> SINK
```

Sources:

```text
HTTP params/body/headers/cookies
TCP payload
uploaded files
DB values originally controlled by users
```

Sinks:

```text
SQL
shell/process execution
filesystem path
HTML/template source
deserializer
network destination
memory-copy length/index
authorization decision
```

A grep hit is not a vulnerability until you can show attacker-controlled data reaches the sink under realistic service flow.

## 3-pass audit

```text
PASS 1: grep dangerous sinks
PASS 2: map routes/inputs
PASS 3: connect input -> sink -> flag store
```

This is faster than reading files top to bottom.