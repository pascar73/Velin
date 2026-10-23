# Velin — architecture (v1)

**Public name:** Velin (**VEL-in**). Provisional.  
**SKUs (four):**

| SKU | Role | Notes |
|---|---|---|
| **VELIN server** | father | no display; fabric worker |
| **VELIN office desktop** | child | work packs; Teams/Entra path |
| **VELIN consumer desktop** | child | private-life artefacts; no corporate gateway |
| **VELIN mobile companion** | child `mobile` | Android v1, §5.4 |

Same overlay family. Office vs consumer = template catalogue + which father they pair with, not two desktops of apps.  
**Internal prefix:** `ael-*` units and `/etc/ael/` stay until a rename pass. Do not bikeshed that in this file.

**Date:** 2026-10-01  
**Base:** Ubuntu 24.04.5 LTS (matches this fleet) or 26.04.1 LTS for a greenfield product. Same overlay either way.  
**Rule:** subtractive. If a package is not on the allowlist, it is not in the image.

**Mission:** the whole stack (client *and* server) exists so people do not need Word, Excel, PowerPoint, Outlook, Windows, or macOS to get work and private-life artefacts done. Ask the agent; it writes; you read. SSH remains break-glass only.

The kernel stays upstream Ubuntu (`linux-image-generic` server / `linux-image-virtual` for VMs). Agentic does **not** live in kernel space. It lives in cgroup v2 slices, systemd units, and a thin user session.

---

## 1. What “no bloat” means

Banned in both SKUs:

- Snap (`snapd`, `snapd-seed`, gnome-software snap backend)
- Guest/cloud agents **that do not match the detected profile** (e.g. WALinuxAgent on QEMU, `open-vm-tools` on Azure). Matching agents are installed in §3.2.
- Popularity contest, apport GUI, whoopsie, ubuntu-report, landscape-client
- Tracker/Miner, zeitgeist, geoclue, evolution-data-server (client: only if the session actually needs it — default no)
- Cups, avahi, bluetooth (server: never; client: off unless the hardware SKU needs it)
- Games, LibreOffice, Thunderbird, Rhythmbox, cheese, totem, example content, GIMP, Inkscape, Evince-as-shell, Nautilus-as-shell, any Electron “office”
- Unattended Desktop “welcome” tours
- Default open ports other than SSH and the **agent fabric** (mTLS only; see §5). No DSH, no Pi debug, no VNC on the LAN.

Allowed only if named in the overlay:

- systemd, udev, journald, logind
- openssh-server
- nftables + ufw (default deny inbound except 22 and fabric 6473/tcp to enrolled peers)
- chrony
- sudo (server: wheel only; client: first user)
- Agent runtime: pinned Node (or the runtime Pi/DSH actually need), Pi, DSH, orchestrator, **fabric** (`ael-fabricd`)
- One local inference runtime if the SKU is “local models” (llama.cpp **or** vLLM — not both)

Target idle (bare metal / VM, no model loaded):

- **Server:** ≤ 400–600 MiB RSS, no graphical.target, multi-user only  
- **Client:** ≤ 1.0–1.2 GiB RSS before the agent UI attaches (no GNOME full stack)

dsh001 (2026-09-26) already proved the server shape: 1,684 → 908 packages, 519 MiB idle, 14 s boot, snaps purged, ufw SSH-only. That is the floor, not a stretch goal.

---

## 2. Kernel and isolation (same on both)

- cgroup v2: `agent.slice` (orchestrator + tools), `infer.slice` (optional local model, memory.max set so it cannot eat the OS), `system.slice` for PID 1.
- User namespaces + seccomp on tool children (DSH/Pi workers). DSH stays `127.0.0.1` only.
- No extra LSMs until we have a policy: AppArmor Ubuntu defaults, nothing theatrical.
- Transparent hugepages / swappiness: server tuned for inference if `infer.slice` exists; otherwise default.
- Do not ship every nvidia/dkms blob “just in case”. GPU SKU is a flavour, not the default ISO.

---

## 3. Server SKU — agentic-centric

Boot: `multi-user.target`. No display manager. No user lingering except `agent`.

PID 1 tree (conceptual):

1. systemd  
2. sshd  
3. `agent-orchestrator.service` (Pi or Hermes-class, pinned)  
4. `dsh.service` — `127.0.0.1:3080`, token in tmpfs, telemetry off  
5. optional `infer.service` in `infer.slice`

First boot (non-interactive if cloud-init seed present, else console wizard):

- hostname, SSH CA or enrolled key  
- IdP or API keys into a root-only store (`/etc/ael/secrets`, 0700)  
- one health prompt: orchestrator + DSH both answer  

Done = SSH in and `agent status` shows green. Fabric listens for enrolled clients (mTLS). DSH is never on the LAN.

### 3.3 LLM path — child agent → father agent → Foundry (cascade)

Clients **do not** pick a model. The **child agent** sends the job to the **father agent** over fabric (`Job.Complete`). The father is the **LLM gateway**: it alone holds Foundry (`azure-foundry`) and routes.

**In the server image:** pinned Foundry plugin + `azure-identity`. **Not in any ISO:** keys, tenant, URL. Father first-run: skip or URL + key / Entra (prefer managed identity). Probe `/models`.

**Desk / Mobile:** OpenAI-shaped call to father over mTLS. Same path for all four SKUs’ children. No Foundry SDK required on the child for the default path. First login works as soon as pairing is done.

**Cascade (complexity, sequential, not a fan-out):**

1. Father classifies the request (cheap classifier / Jev-class scores — **not** the flagship). Classes: `housekeeping` | `artefact` | `hard`.
2. Map in `/etc/ael/cascade.yaml` (pinned names, not `latest`): e.g. housekeeping → small Foundry deployment; artefact → mid; hard → flagship. Local `infer.slice` may sit in front of Foundry if the SKU has it.
3. **Escalate once** if the small model returns low confidence / tool-failure / operator `force:hard`. Never spray the same prompt at three models.
4. Flagship is **not** for titles, health summaries, or cascade classification.

**Audit:** child CN, class, model id used, escalate yes/no, tokens in/out, latency — not the prompt body by default (operator may enable payload archive under data-class rules).

**Direct Foundry on the desk** (`Cap.LlmProfile`) is **opt-in break-glass** (father down, air-gap lab) — short-lived token, office class only, still audited. Default is **off**.

**Consumer:** work Foundry refused. **Fail closed:** father unreachable → queue, do not invent a second gateway on the laptop.

Server agent is the **worker**: it advertises capabilities (deploy, infer, files, tools allowlist) to paired clients. It does not scrape the client.

### 3.1 First launch — Pi agent environment briefing

When the **server** Pi agent starts the first time (and again after a hardware/cloud identity change), its first job is **situational awareness**. Only **in-guest, documented** sources. No probing other machines, no hypervisor escape, no scraping neighbour IMDS, no port-scanning the fabric.

**Gather (legit, local):**

- Virt: `systemd-detect-virt`, CPU hypervisor bit, DMI/chassis (`/sys/class/dmi/id/`), virtio vs bare metal vs container (`/proc/1/cgroup`).
- Cloud: only if the guest metadata endpoint is present on the documented link-local address (Azure IMDS, AWS IMDSv2 with hop limit, GCP metadata, OpenStack, etc.). Record cloud, region, instance size, image, placement group **if the API returns them to this VM**.
- Machine: CPU model/count, RAM, disks, NUMA, GPU if `lspci` sees one we own.
- Boot/OS: kernel, cmdline, hostname, machine-id, timezone, whether Secure Boot/TPM is visible.
- Network **of this host**: addresses, routes, DNS, default GW, whether we are behind a typical cloud DNS. No traceroute farm, no `nmap`.
- Identity already on disk: cloud-init, enrolled SSH CA, `/etc/ael/*` if any.

Write a signed briefing to `/var/lib/ael/context.json` (root, 0640) and load it into the agent’s working memory. Fabric capability snapshot includes a **short** form (SKU, virt, cloud or `bare-metal`, region or `unknown`).

**Do not gather:** other tenants, host hypervisor management, switch configs, other VMs’ disks, secrets from other users, public IP if IMDS does not offer it.

**Ask the operator (first-run wizard / console) for anything that is not on the box:**

- Organisation and environment name (prod / staging / lab)
- Intended role (infer worker, deploy worker, mixed)
- Data classification and whether PII may land on disk
- Who may pair (client roster / IdP group)
- Local model allowed or API-only
- Peers if no join token was seeded
- Confirmation: “I think I am an Azure D-series VM in {region}. Correct?”

Until that confirmation, the agent may **observe** but must not take mutating fabric jobs. After confirmation, `agent status` includes `context: confirmed`.

Re-run the gather pass if machine-id, virt type, or IMDS instance-id changes (clone / migrate). Ask again if the story disagrees with the last confirmation.

### 3.2 Adapt — install what this environment needs, remove the rest

After `context: confirmed`, `ael-adapt.service` (oneshot, first boot and on profile change) reconciles packages against the briefing. **Ubuntu signed repos + `/etc/ael/versions.lock` only.** No `curl | sh`, no PPA lottery, no compiling random GitHub.

**Never remove:** kernel, systemd, sshd, nftables, orchestrator, DSH, fabric, `ael-adapt` itself.

**Profile → add (examples):**

- `qemu` / `kvm` (QNAP VM Station, Proxmox, libvirt): `qemu-guest-agent` so the hypervisor can quiesce, sync time, and talk virtio-serial. Virtio modules are kernel, not extra blobs.
- `vmware`: `open-vm-tools` (open-vm-tools-desktop **not** on server).
- `microsoft` / Hyper-V: `hyperv-daemons`.
- `azure`: Azure guest utilities / WALinuxAgent **only on Azure**.
- `amazon`: `amazon-ec2-utils`; IMDSv2 hop-limit 2; no SSM unless the operator asked.
- `google`: `google-guest-agent` only on GCE.
- `lxc` / `container`: no hypervisor guest agent.
- `none` (bare metal): no guest agent. Optional `smartmontools` / `ipmitool` **only if** IPMI/BMC is on *this* machine’s DMI, not found by scanning the LAN.

**Remove:** every guest/cloud agent that is not in the active profile. Also the global ban list (snaps, whoopsie, …).

**Download:** `apt-get install` of the profile set if missing. If the mirror is unreachable, record `adapt: deferred` and keep observing; do not fail the box.

**Operator veto:** first-run can pin `ael.adapt=manual`. Then Pi **proposes** the package delta and waits. Default for server images in enterprise is apply-after-confirm (same wizard as §3.1).

Log the delta to `/var/log/ael/adapt.log` and refresh `context.json` (`packages_added`, `packages_removed`, `profile`).

---

## 4. Client SKU — first-run agents, not a desktop remix

Not Ubuntu Desktop. A **session**:

- Display: **greetd** (not GDM/SDDM/LightDM) + one Wayland compositor.
  - **Kiosk / first-run:** **cage** — agent UI full-screen.
  - **Desktop client (default for “modern, flexible, fast”):** **niri** — scrollable-column Wayland compositor, low idle, no animation zoo, still a real desktop (windows, workspaces, laptop/ultrawide). Agent session is workspace 1; terminal is a bind, not the product.
  - **Omarchy-class look (optional flavour):** **Hyprland** with animations **off** in the fleet image. More IPC and ricing; more moving parts. Not the enterprise default.
- One session user. systemd `--user` starts `agent-session.service` **before** the panel.
- First login: full-screen first-run (identity, keys/OAuth, local vs API model). Until that finishes, there is no empty desktop to explore.
- After first-run: the agent UI is the shell. Terminal is available (SSH-equivalent locally). It is not the default.

First-run success = user can ask the **local** agent to do one job **and** see paired servers (or complete pairing). No browser install step.

SSH remains for break-glass. The agent is not the recovery path.

The client agent is the **operator**: it talks to server agents over the fabric, never to DSH on the server. One user mention / one intent → one server (no silent fan-out).

### 4.1 Agents write; humans only read

The client is **not a desktop**. No office, no editors, no “apps” in the dock. Agents create artefacts with libraries + **templates**. The session ships **readers** (preview in the agent UI). That is the whole UX.

**Banned as packages:** LibreOffice, OnlyOffice, WPS, Calligra, GIMP, Inkscape, Scribus, Evince/Nautilus as a product, any Electron office. `xdg-open` may hand a file to the in-UI reader only.

**Readers (not editors):** PDF.js, spreadsheet grid, XML tree, Markdown preview — all inside the Artefacts pane. Optional break-glass: `zathura` (PDF), nothing that can *author*.

**Templates are the product.** `/usr/share/ael/templates/` is a curated design system, not Office clip-art. Quality bar: editorial print (same class as a house book), never Calibri-on-blue. If a template would look at home in Microsoft’s gallery, it is rejected.

Pin: **one type pair, one geometry, one ink set** (see `TEMPLATES.md`). Agents fill slots; they do not invent layout. Output: `~/Velin/<date>-<slug>/` + `.meta.json`.

**First-run demo:** sample XML register → `demo.xlsx` + one-page `demo.pdf` from the **board-pack** template. If either file is missing or fails visual QA (margin, type, no default-Office look), first-run is not done.

Server SKU: same libraries + templates, no compositor, no readers GUI.

---

## 5. Fabric — client and server agents are peers when connected

They do not “mount each other”. They do not share DSH. **Orchestrators** form a small mesh.

**On connect (enrolled):**

- Mutual TLS with device certs from first-boot / IdP (`/etc/ael/pki/`).
- Presence: `online | idle | busy | draining`. Heartbeat ~5 s, drop after 15 s.
- Capability snapshot: SKU, tools allowlist, infer present or not, disk/RAM headroom. Client UI shows **named servers**, not raw IPs.
- Session: client agent holds a capability ticket; server agent executes only allowlisted tools. Mutate = confirm or dry-run on the client session.

**Discovery (no Avahi, no open mDNS):**

1. Default: **roster** — admin pastes a join token / scans a QR / cloud-init `ael.peers=`.
2. Optional LAN: `ael-fabricd` UDP beacon, **encrypted with the org key**, not `_http._tcp`. Unknown beacons ignored.
3. No Telegram, no public DHT, no bot-to-bot loop.

**Wire:**

- Port: `6473/tcp` (example) nftables allow only from enrolled nets or WireGuard `ael0`.
- DSH and inference stay on `127.0.0.1` on the machine that owns them. Remote work is “client agent → server agent → local DSH”.
- Empty allowlist = deny. One client intent does not fan out across servers.

**Awareness in the client session:** a persistent peer strip: server name, presence, last capability hash. Disconnect = UI goes stale, jobs fail closed.

**Awareness on the server:** `agent peers` lists enrolled clients; unenrolled SYN is dropped.

### 5.1 Father / child handshake and fleet health

One **server (father)** may have many **clients (children)**. The relationship is explicit, not “whoever is on the LAN”.

**Do not invent a crypto protocol.** Reuse boring parts. Invent only the *Velin RPCs* (health, vault, artefacts, jobs) as a small schema on top.

| Layer | Reuse | Do not |
|---|---|---|
| Path | TCP on LAN; **WireGuard** `ael0` for regions / Mobile | Custom UDP crypto, Avahi as trust |
| Transport | **TLS 1.3** + **mTLS** (device certs, CN = hostname) | SSH as fabric, Matrix as fabric, MQTT as the control plane |
| RPC | **Connect-RPC** (HTTP/2 + protobuf) or gRPC — same idea | Homegrown length-prefix JSON on a raw socket |
| Pairing | One-time **join token** (step-ca / Tailscale-auth-key shape): TTL, single use, bound to father `machine-id` | Rolling custom PAKE, QR that embeds a long-lived secret |
| Identity | hostname = cert CN = `@mention` | SPIFFE in v1 (too much ops). mDNS names. |
| Discovery | Roster + QR / cloud-init. Optional **org-key** beacon | Open mDNS, public DHT |

**Why not SPIFFE/NATS/Tailscale-as-product:** SPIRE is a second control plane. NATS is another daemon. Tailscale/Headscale is fine *later* as the `ael0` implementation, not as the agent API. Matrix is for **humans** (§5.2).

**Pairing (reuse TLS, one custom step)**

1. Father runs a short-lived provisioner (like `step ca token`): join token, TTL, single use, bound to this father.
2. Child first-run opens **TLS 1.3** to 6473 **without** a father-trusted client cert (**enrolment-only**). Join token is **never** in ClientHello/ALPN (that is cleartext). After the handshake, token goes in encrypted Connect `Join`. Father CA fingerprint comes from the QR/seed. Rate-limited, nftables.
3. Father issues the child cert (CN = hostname). Child stores father CA. Roles `father` | `child`. A child never becomes father to siblings.
4. From then on: **only mTLS**. Token is spent.
5. First Connect `Hello`: protocol version, SKU class, `versions.lock`, capability hash, health schema. Mismatch → `compat: degrade`, no silent new methods.
6. Both write `/var/lib/ael/roster.json`. Re-handshake on cert rotation or protocol bump.

Stolen token after use is useless. Unknown SYN after pairing is dropped.

**Agent channel**

After handshake, Pi on the child talks to Pi on the father as **Connect methods** on the same mTLS socket (`Health.Push`, `Vault.Sync`, `Job.Submit`, `Job.Complete`, `Cap.Get`). Language still happens **on each box**; fabric carries structured calls, not chat logs. DSH stays `127.0.0.1`. **LLM:** child → father → Foundry cascade (§3.3). `Cap.LlmProfile` is break-glass only.

**Child → father health (monitoring, not spyware)**

The child agent pushes a signed **health envelope** every 30 s (and on alert). Father merges it into `/var/lib/ael/fleet/<child-id>/` and can answer “how are the laptops?”.

Envelope includes:

- Identity: hostname, SKU, versions.lock, last adapt profile  
- Resources: CPU%, load, RAM, swap, disk %, inode %, optional GPU  
- Hardware: thermals if sysfs has them, SMART if the disk is *this* machine’s, battery on client, RAID/md if present  
- Security posture: nftables default policy, listening ports (ours vs unexpected), failed SSH count, unattended-upgrades state, disk encryption yes/no, Secure Boot/TPM visible, fabric cert days-left, agent unit failed?  
- Agent: orchestrator/DSH up, last job, allowlist hash  

**Not in the envelope:** keystrokes, screen, browser history, user documents, microphone. Health is ops telemetry, not EDR-as-surveillance.

**Cybersecurity controls on this channel**

- mTLS + device allowlist; unknown child dropped  
- Health is **append-only metrics**, not a remote shell  
- Father cannot run arbitrary commands on a child unless the child’s allowlist and a **confirm** on that client session say so  
- Alerts (disk >90 %, unit failed, new listener, cert <7 days) are first-class; Pi on the father can summarise them in language  
- Child going silent: father marks `unreachable` after 3 missed envelopes  

**Corporate class — encrypted, safe, auditable**

Encryption is TLS 1.3 **only** (no 1.2, no plaintext fallback). Cipher suites: the Ubuntu 24.04 **system** defaults (`ssl-cert` / OpenSSL 3), not a home-grown list. WireGuard `ael0` when the path is not the LAN. Certs are **short-lived** (days, not years); father is the CA; rotation is a first-class RPC. Tokens, keys, vault bodies never in logs.

**Audit (father is the system of record)**  
Append-only `/var/lib/ael/audit/` (root 0750, `adm` group). journald + optional syslog/SIEM (Azure Monitor / Sentinel later — not in the ISO). Child **cannot** delete the father’s trail. Same event IDs on both ends for correlation.

Log **always:** join (success/fail, token id **hash** not the token), cert issue/revoke, roster change, SKU-class mismatch, `Hello` degrade, every `Job.Submit` / `Vault.Sync` / mutate confirm or deny, nftables drop of unknown peer, Foundry probe result (not the key).  
Log **never:** join token, API keys, Entra JWT, file contents, chat text.

Each record: UTC, father CN, child CN, Entra UPN if a human confirmed, method, request-id, outcome, bytes not payload. Retention: 90 days default, operator-set. Hash-chain the files so silent truncate is visible.

Empty allowlist still **deny**. No fan-out. Confirm-on-mutate is itself an audit row.

Father `agent fleet` = inventory + health + posture of every child. That is what a proper server knows about its deployed clients.

### 5.2 Human chat (Telegram-class) — safe from first boot

Agents already talk on fabric. **Humans** need a chat UX on day one, including other regions. That must not put bot tokens in the ISO.

**Native (default, enterprise):** the father runs a small **Matrix** homeserver (Conduit-class, not a Synapse farm). Clients join `https://father/.well-known/matrix`. E2EE rooms: `ops`, `alerts`, one room per child. Regions = one father per region, federate, or WireGuard `ael0`.

**Corporate messengers (optional gateways, same safety as Telegram):** ISO still has **no** tokens. First-run pastes app credentials + **channel/team allowlist**. Empty allowlist = that gateway off. Mention-gated, mutate still confirms on the client. Fabric stays canonical.

Priority for this ICP (PE / Microsoft-heavy firms):

1. **Microsoft Teams** — default ask. Azure bot / Incoming Webhook / Graph. SSO with Entra ID.  
2. **Slack** — Enterprise Grid, Socket Mode, channel allowlist.  
3. **Mattermost** — self-hosted, air-gap friendly, closest to “Telegram but on-prem”.  
4. **Google Chat** — only if the tenant is Workspace-native.  
5. **Webex** — only if that is already the corporate standard.

Telegram remains a lab/personal gateway, not the enterprise pitch.

**Teams + Entra, right after first boot (not a later project):**

Linux is not Windows Autopilot. Do **not** bake a client secret into the ISO.

Sequence after sshd/fabric are up:

1. First-run asks **tenant ID** (or reads `ael.entra.tenant=` from cloud-init).  
2. **Identity:** Canonical **authd** (Entra login on Ubuntu) or device-code SSH — operator completes Entra in a browser. Box is then a named Entra device/user, not a rogue bot.  
3. **Teams app:** device-code / admin-consent URL for *our* multi-tenant (or customer-single-tenant) bot. Graph grants: send channel messages, read mentions, *nothing else*.  
4. Operator picks **one team + one channel** (allowlist). Empty = Teams stays off.  
5. `ael-teamsd` starts only when consent + allowlist exist. Mention-gated; fabric still canonical.

If the tenant admin refuses consent, the install is still valid; Teams is simply `deferred`. No waiting forever on Graph.

**What we pre-install (Teams is tenant-gated; we cannot skip IT):**

- **Server:** `ael-teamsd` only — small Graph/Bot client, `ca-certificates`, no Teams desktop. Holds our **public app ID** (no secret). Wizard: tenant → device-code/admin-consent URL → pick one channel if Graph allows → allowlist. If the tenant **blocks custom apps**, wizard stops with that sentence and `deferred`.
- **Client:** **no** Teams Electron. Browser/`xdg-open` for consent if the operator is at the desk. `authd` optional for Entra user login. Chat stays in Teams on their Windows/Mac; this box is the bot, not another Teams client.

We cannot make it “add a calendar box”. We **can** make IT’s path four clicks and our path zero Azure portals for the operator.

### 5.3 Community bootstrap — generated when the fleet exists

Not during the 60 s disk copy. **After** father first-run **and** at least one child has completed handshake.

`ael-communityd` on the father writes `/var/lib/ael/community/` and (if Teams/Matrix is not `deferred`) creates the human rooms. Purpose: give the **IT / Entra admin** a one-page brief they can forward to **leaders** — “the agents are in the same place you already talk.”

**Identity (one name everywhere)**

- Linux hostname = fabric **cert CN** (and SAN DNS) = chat **display name** = `@mention`  
- Example: machine `london-pas-1` → cert `CN=london-pas-1` → Teams/Matrix user-visible name `london-pas-1`  
- Humans keep their Entra UPN. Agents never steal a person’s UPN.  
- Father is `@<father-hostname>` (SKU `server`). Each child is `@<child-hostname>` (SKU `client`).  
- Roster file `/var/lib/ael/roster.json` is the source of truth; chat is a projection.

**Rooms the bootstrap creates** (Matrix always; Teams only after §5.2 consent)

| Room / channel | Who | For |
|---|---|---|
| `ops` | humans + father | day-to-day |
| `alerts` | father (read-mostly for humans) | health / security |
| `agent-<hostname>` | that machine’s agent + invited humans | 1:1 with one child |
| `fleet` | father + all children (agents only; humans optional) | agent-to-agent in language, still on fabric for RPCs |

One Microsoft **Team** named after the project / father (`Velin <father-hostname>`). Children are **not** extra Teams tenants.

**What the admin gets immediately** (`/var/lib/ael/community/IT_BRIEFING.md` + `.pdf` later)

1. Father hostname, cert fingerprint, fabric port  
2. Table of children: hostname, SKU, last seen, health  
3. How leaders talk: `@london-pas-1 status` in `ops`  
4. Link / QR to join the Team (IT still has to add people — we do not auto-invite the whole company)  
5. Statement: mutating commands still confirm **on the machine**, not in chat

Re-runs when a child joins or leaves (idempotent). No new Graph permissions beyond §5.2.

### 5.4 Velin Mobile — Android first, self-contained

Not a third Linux SKU. A **pocket operator** for the father (and later a paired desk). iOS later; **v1 is Android only**.

**Self-contained means:**

- One signed **APK**. Sideload or F-Droid-class store. **No** Google Play Services, Firebase, Crashlytics, ads, or vendor cloud.
- **No** runtime downloads of models, WebViews-as-product, or “optional modules”. If a library is needed, it is **in the APK**.
- **No** account at our company. Enrolment is the same join token / QR as a child, mTLS device cert on the phone.
- Talks **only** to the enrolled father on fabric (WireGuard `ael0` or 6473). No DSH, no Pi debug port, no Telegram SDK.

**What it does:** roster + presence, `@mention` by hostname, read artefacts (PDF/grid), health **summary** the father already has (not a second sensor). Mutate still confirms **on the machine that would change**. Default: the app cannot approve a mutate.

**What it does not:** office suite, camera-as-spyware, always-on location, a local LLM in v1.

Phone is a child of kind `mobile`, not a laptop. Envelope: battery + app version + cert days-left only.

### 5.5 Shared vault (default memory)

The father ships an **Obsidian-shaped vault**: a git-friendly tree of Markdown (wikilinks, YAML frontmatter, one folder per area). That **is** agent memory. Not a proprietary DB. Not Obsidian Electron on the server.

**Canonical copy:** `/var/lib/ael/vault/` on **VELIN server** (root 0750, `agent` group). Children do not each own a second brain.

**Share:** office desktop, consumer desktop, and mobile **sync over fabric** (mTLS), same roster as pairing. Office vs consumer namespaces are **class-checked** (same fail-closed rule as SKU pairing). Mobile is read-heavy; writes are allowlisted paths only.

**Readers:** Artefacts pane / vault pane on Desk; same on Mobile. No requirement to install Obsidian.

**Cloud (opt-in, not a second source of truth):** the image includes **rclone** + empty remote templates for **OneDrive** and **Google Drive** (and later others). No OAuth tokens in the ISO. First-run: skip, or complete device-code on the **server**. Sync is vault ↔ remote, scheduled, never the control plane. Clients never talk to Graph/Drive APIs directly (keeps Mobile free of Play Services).

**Mutate:** vault writes are files. Empty allowlist still denies remote-from-chat. Confirm on the machine that holds the canonical copy (the father) unless the child’s allowlist says otherwise.

### 5.6 Microsoft estate (whole product line)

Velin does **not** become Windows. The **whole line** uses Microsoft **through the father**. One Graph/Azure session, four SKUs. No secrets in the ISO.

| SKU | Microsoft path |
|---|---|
| **VELIN server** | Owns Entra device-code, Teams bot, rclone OneDrive, Graph (allowlisted sites), optional **Azure AI Foundry** (`azure-foundry`), optional Fabric semantic-model queries, Key Vault if on Azure. |
| **VELIN office desktop** | Entra sign-in (authd). Sees tenant files **via vault/fabric**, not a OneDrive client. Teams is chat UX; fabric stays control plane. |
| **VELIN consumer desktop** | **No** work tenant. Optional **personal** OneDrive (MSA) on *its* father, same rclone. Work Graph/Azure/Fabric **refused**. |
| **VELIN mobile** | Never calls Microsoft. Reads the same vault after the father has synced OneDrive. No GMS. |

Consumer vs office remains fail-closed. Humans = Entra/MSA UPN. Agents = hostname/cert CN.

No client secrets, refresh tokens, or tenant IDs in the ISO. First-run / Key Vault / cloud-init seed only.

| Surface | How | Not |
|---|---|---|
| **Entra ID** | Device-code / Canonical **authd**. Box is a named identity. | Baking a password. Autopilot clone. |
| **Teams** | §5.2 `ael-teamsd`. Mention-gated, one team+channel. | Teams Electron, Incoming Connectors as the long-term path. |
| **OneDrive** | rclone on the **father**, vault ↔ remote. Device-code on server. | Per-laptop OneDrive sync client, `cifs`. |
| **SharePoint / M365 files** | Graph **Files.ReadWrite.All** on *allowlisted* sites/libraries only, from the father. | Full tenant crawl. |
| **Azure** | Adapt: WALinuxAgent **only on Azure**. IMDS for §3.1. Optional: Key Vault for `/etc/ael/secrets` (managed identity). Azure Files = rclone flavour. | `azure-cli` in the default image. Arc on every laptop. |
| **Azure AI Foundry** (Hermes provider `azure-foundry`) | Office **father** only. Same module as Hermes: user-supplied `base_url`, `api_key` **or** `auth_mode: entra_id` (managed identity on Azure). Chat Completions / Anthropic Messages / Responses as the resource requires. | Shipping weights. Making Foundry the control plane. Calling Foundry from Desk/Mobile. Microsoft Fabric (semantic model) is a **different** door. |
| **Microsoft Fabric / Power BI** | Father queries the **semantic model** (RLS respected via delegated user, or SP only where RLS is off). OneLake is **not** a second vault. | Warehouse SQL as the agent’s brain. A second semantic model. Power BI Desktop. |
| **Intune / Autopilot-ish** | cloud-init / Intune custom config: tenant ID, channel IDs, vault remote name. | Client secret in the policy payload. |

**One Entra app** (single-tenant for a customer install): Graph files + Teams mention/send + Azure OpenAI if used + Fabric executeQueries if used. Admin consent once (`entra-teams-prep.ps1` grows these scopes, still no secret in the image).

**Identity:** human = Entra UPN. Agent = hostname/cert CN. Do not merge those.

---

## 6. Shared overlay (the actual distro)

```
ael-base          # strip list + nftables + sshd + journald persistent
ael-agent         # pinned orchestrator + DSH + Node pin + telemetry off
ael-fabric        # ael-fabricd, mTLS, roster, presence, capability tickets
ael-adapt         # profile packages: qemu-guest-agent, cloud agents, purge mismatches
ael-server        # multi-user, agent uid, no greetd, fabric worker + azure-foundry (no secrets)
ael-client        # greetd + compositor + first-run + user agent slice + fabric operator (LLM via father)
ael-artefacts     # openpyxl, python-docx, python-pptx, lxml, one PDF engine, templates, Artefacts pane
ael-vault         # markdown vault on father; fabric sync; rclone OneDrive/Drive templates (empty)
ael-infer-optional
```

Build path: **image copy, not apt at install time** (see §7). Two ISOs: `ael-server.iso` and `ael-client.iso`, each carrying a pre-built root.

Version pin file in the image: `/etc/ael/versions.lock` (Node, Pi, DSH, orchestrator). Floating `latest` is a defect.

Package and module allowlist: **`PACKAGES.md`** (re-assessed against four SKUs + vault). If it is not in that file, it is not in the image.

---

## 7. Fast installer — under one minute (Omarchy method)

Omarchy (DHH) does **not** pacstrap the OS on the target. The ISO ships a **factory root image** built once; the installer **receives** it onto disk. Their btrfs-send path unpacks in ~17 s; full installs in the 30–60 s range on fast NVMe. Manual `curl | bash` Omarchy is the slow path — we do not copy that.

We do the same on Ubuntu:

**At ISO build time (slow, once, on our builder):** debootstrap + overlay + pins → a btrfs subvolume → `btrfs send --compressed-data` (or erofs/squashfs if we must). Checksum beside the stream. Kernel, agents, fabric already in the image.

**At install time (must be <60 s disk-to-ready, ISO already on SSD/NVMe):**

1. Pre-flight: checksum the stream **before** wiping the disk (Omarchy lesson: never destroy the drive then discover a truncated image).
2. GPT: ESP 512M + rest btrfs `@` (zstd). No LVM. LUKS optional and **off** for the <60 s SKU unless the operator asked (crypto is the usual minute-killer).
3. `btrfs receive` the factory stream onto `@`. Sequential NVMe write-bound, not CPU-bound, not network-bound. **No `apt` during install.**
4. Inject per-machine only: `systemd-machine-id-setup`, hostname, ESP + systemd-boot/UKI already in the image, fstab UUID.
5. Reboot or `systemctl switch-root` / kexec. First boot: §3.1 briefing + §3.2 adapt (guest agent only), not a second OS install.

Target: **partition + receive + bootloader < 45 s**; **multi-user with sshd and fabric listening < 60 s** from “install” on a modern SSD. Adapt/cloud packages may trail; the box is already *up*.

Not ubiquity, not subiquity walking 800 packages, not network debootstrap.

---

## 8. Explicit non-goals

- Custom kernel tree  
- TUI-only with no shell  
- Snaps “because Canonical”  
- Shipping model weights inside the ISO  
- Two inference stacks on one SKU
- Exposing DSH/Pi on the LAN
- Avahi/mDNS “just so they find each other”
- Client agent SSHing in as the control plane  

---

## 9. Next build (when you say go)

1. Factory root image for **server** (allowlist + units + fabric), `btrfs send` stream + sha256.  
2. Installer that checksums, partitions, receives, boots — timed on NVMe/QEMU virtio-blk. Gate: <60 s to sshd.  
3. Client factory image + pair-to-father on first-run.  
4. Proof: child health envelope on the father. No DSH on the LAN.
