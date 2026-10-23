# Velin — wrap-up 2026-10-01

**Name (provisional):** **Velin**. Four SKUs: **VELIN server** · **VELIN office desktop** · **VELIN consumer desktop** · **VELIN mobile companion**. Not a kernel fork. Not TUI-only. Internal code `ael-*` until rename.

Closed LOOP_003 v1 (2026-09-30) already rejected: custom distro as a company, no-shell TUI, UI as the only recovery path. **This wrap-up does not reopen that.** This is a **different product**: Ubuntu flavours + agent fabric + artefact session.

## Heart of the product (why anyone buys)

**Mission:** relieve people of Word, Excel, PowerPoint, Outlook, and of Windows/macOS as the place work happens. Those are tools of the past. The old loop — learn the suite, shout through a hundred emails a day — is dead. Velin is the first **installation** (client *and* server) engineered **only** around this: you ask an agent; it writes the artefact; you read it. Work and private life. No forcing anyone through Excel/Word/PowerPoint.

Office theatre is the symptom: PowerPoint-to-PowerPoint, Outlook piles, Calibri decks that are “fine” until they are not. The **pack** (memo, register, model, board paper, letter, invoice) is the job. Those jobs are better when an agent writes them to a house design system.

That is also the investor story: a SKU (father + children), template library as IP, a fleet that replaces the suite rather than competing with Windows on apps. If a generated file would look at home in a default Office template, it is a defect.

**Still true from LOOP_003 v1:** SSH stays as break-glass. The agent is not the only recovery path. DSH stays loopback. Mutate still confirms on the machine.

## Decisions locked today

1. **Base:** Ubuntu 24.04.5 LTS (this fleet) or 26.04.1 greenfield. Arch is out for enterprise.
2. **Shape:** four SKUs — **VELIN server** (father), **VELIN office desktop**, **VELIN consumer desktop**, **VELIN mobile companion**. Same overlay family.
3. **No bloat:** allowlist only. No snaps, no LibreOffice, no GNOME, no guest/cloud agents that do not match the detected profile.
4. **Server:** multi-user, no display manager. Pi/orchestrator + DSH on loopback. First job = in-guest environment briefing (`context.json`), then `ael-adapt` (install matching guest agent, purge the rest). Ubuntu signed repos only.
5. **Client session:** greetd. First-run **cage**. Daily desktop **niri**. Hyprland optional, animations off. Sway as recovery tiling. Agent UI is workspace 1.
6. **Client is not a desktop of apps.** Agents **write** artefacts. Humans **read** (PDF.js / grid / XML in the Artefacts pane). Optional `zathura` only. Templates are the product (`TEMPLATES.md`): one type pair, A4 16mm, navy/beige/orange scalpel. First-run demo: XML register → `demo.xlsx` + `demo.pdf`.
7. **Fabric:** `ael-fabricd` mTLS on 6473/tcp. DSH never on the LAN. Roster + join token. No Avahi.
8. **Father/child:** one-time token, cert CN = hostname = `@mention`. Child health envelope 30s (metrics, not spyware). Mutate = child allowlist **and** confirm on that session. No fan-out.
9. **Install:** Omarchy method — factory root `btrfs receive`, **no apt at install**. Gate: sshd + fabric **<60 s**. LUKS off unless asked.
10. **Human chat:** ISO has **no** tokens. Native Matrix on father. Enterprise gateway: Teams (Entra consent, deferred if IT blocks). Slack / Mattermost optional. Telegram is lab only.
11. **IT pack:** `entra-teams-prep.ps1` + cloud-init seed (IDs only, no client secret).
12. **Community bootstrap after first child handshake:** one Team, rooms `ops` / `alerts` / `agent-<host>` / `fleet`. `IT_BRIEFING.md` for leaders.

## Files

- `ARCHITECTURE.md` (v1)
- `TEMPLATES.md`
- `it/README.md`, `it/entra-teams-prep.ps1`, `it/cloud-init-seed.yaml`, `it/IT_BRIEFING.template.md`

## What AgentHermes must do this loop

Review the architecture as **implementation critic**: what is wrong, missing, too heavy, or in conflict with LOOP_003 v1 `PURSUE_IF` (SSH kept, loopback DSH, allowlist, deny-by-default, confirm-on-mutate, no fan-out). Add ideas. Do **not** build an ISO in this loop.

## Open questions (Hermes should hit these)

- niri + cage + artefact WebView: idle RAM vs the 1.0–1.2 GiB client budget
- typst vs weasyprint vs DS2 HTML+CDP on a machine with no Chrome-as-product
- Matrix Conduit on the father vs “just Teams deferred”
- btrfs-send of an Ubuntu root: Secure Boot/UKI, ESP, first-boot machine-id
- Health envelope vs GDPR / employee-laptop privacy
- Whether “no editors” survives a real IC workflow (humans will still want Excel)
