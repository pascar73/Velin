# Golden Image — Agents-Optimised Ubuntu (DSH + Pi)

Installable ISO: minimal Ubuntu 24.04.5 server with the DSH (DeepSeek Harness) web UI and
Pi agent pre-bundled. First boot runs a setup wizard (tty1) that asks for the OpenRouter
API key (required) and DeepSeek key (optional), installs the agent stack, and starts DSH.

- ISO: golden-agent-24.04.5-amd64-20260928-2222.iso
- Checksums: SHA256SUMS
- Build tree + tests: /home/dsh001/golden-image (local)
- Plan & status: [[Local infrastructure management/golden-image-agent-distro-plan|golden-image-agent-distro-plan]]
- Wiki: [[WIKI/golden-image-agent-distro|golden-image-agent-distro]]

Boot: write ISO to USB (or attach to VM) → installer asks only username/password →
first boot autologins once into the setup wizard → done.

Console philosophy: the tty1 console is a **Pi kiosk** — first boot runs the setup
wizard (API keys), then the Pi TUI takes over and relaunches automatically. The user
manages the machine through Pi, not the shell; SSH stays available for administration.
