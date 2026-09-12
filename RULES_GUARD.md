# RULES GUARD — Siege of Servers

Use this before running **any** command that touches the game network.

## Authorized topology

```text
Your laptop
   |
   | SSH password
   v
YOUR PUBLIC IP  -> SSH access only
YOUR UBUNTU VM
   |
   | attack traffic originates here
   v
OTHER TEAMS' PRIVATE IPs -> announced ports/services only
```

The scoreboard is for **viewing scores and submitting flags only**.

## Pre-command gate

Before any network action, answer all five:

1. Is the destination an organizer-confirmed **opponent Private IP**?
2. Is the destination port/service explicitly announced for the event?
3. Is this normal exploit/testing traffic rather than flooding or denial-of-service?
4. Is the destination definitely **not** the scoreboard/checker/organizer infrastructure?
5. Am I avoiding all firewall/traffic-blocking changes on my own VM?

If any answer is `NO` or `UNKNOWN`, stop and verify with the organizers.

## Straight-ban territory

Never use or modify traffic blocking such as:

```text
iptables
ufw
AWS Security Groups
nftables/firewalld if used to block incoming game traffic
any proxy/filter whose purpose is to make the VM non-attackable
```

Do not scan/attack/tamper with:

```text
scoreboard
checker system
organizer infrastructure
other teams' Public IPs
non-event systems
```

Do not DDoS or flood.

## Allowed defensive philosophy

Because network blocking is banned, defend by fixing the actual service:

```text
unsafe SQL       -> parameterized query
auth flaw        -> ownership/authorization check
shell injection  -> no shell interpretation
path traversal   -> canonical-path confinement
deserialization  -> safe format/schema
memory bug       -> bounds/lifetime fix
bad upload       -> safe storage + validation
```

Passive observation is preferred:

```bash
ss -lntup
ps auxf
journalctl -u SERVICE -f
sudo tcpdump -i any -nn -s0 port ANNOUNCED_PORT
```

## AI rule

The written rules allow **ChatGPT and Gemini**, prohibit **Claude**, and prohibit **all MCP tools/servers**. If the organizers issue a newer instruction during briefing, treat the newest organizer ruling as authoritative.

## VM safety rule

Organizers will not reset your VM if you break it. Therefore every change follows:

```text
backup -> diff -> change -> restart -> functional test -> commit
```

Never wipe a database just because the checker reports `CORRUPT`.

## Scope tag for every exploit

Put this at the top of exploit scripts:

```text
AUTHORIZED USE: Siege of Servers Attack–Defense CTF only.
Targets must come from the organizer-provided opponent Private-IP/port list.
```
