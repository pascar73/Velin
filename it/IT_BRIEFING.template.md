# AEL community — IT briefing (generated on the father)

This file is **emitted by the father** after install + first child handshake. Forward it to leaders. Do not put secrets in it.

## Project

- Father (server): `{{FATHER_HOSTNAME}}`
- Fabric: mTLS, cert CN = hostname
- Chat: {{MATRIX_OR_TEAMS}} team `AEL {{FATHER_HOSTNAME}}`

## How to talk to an agent

Each machine **is** its name. The certificate CN is the username.

| Hostname / @mention | Role | Last seen | Health |
|---|---|---|---|
| `@{{FATHER_HOSTNAME}}` | father / server | {{TS}} | {{HEALTH}} |
| `@{{CHILD_HOSTNAME}}` | child / client | {{TS}} | {{HEALTH}} |

In `ops`: `@{{CHILD_HOSTNAME}} status`  
In `alerts`: read-only health and security  
In `agent-{{CHILD_HOSTNAME}}`: that machine only

Leaders keep their own Entra account. Agents do **not** log in as people.

## Add people

IT adds humans to the Team. AEL will not invite the directory.

Mutating actions still require a confirm on the **physical/client session**. Chat is not a remote shell.
