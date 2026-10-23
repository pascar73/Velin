# Velin — default packages and kernel modules (re-assessed)

**Date:** 2026-10-01  
**Rule:** if it is not in this file, it is not in the factory image. Office vs consumer = **manifest + father class**, not a second package set. Mobile is an APK, not these lists.

Ubuntu 24.04.5 LTS (`linux-image-virtual` on VM, `linux-image-generic` on metal). No extra kernel tree.

---

## 1. Verdict vs the old “server + one client” list

| Change | Why |
|---|---|
| **rclone on server only** | OneDrive/Drive adapters; clients must not ship Graph/Drive SDKs |
| **git on server (+ client for vault working copy)** | Vault is Markdown on disk |
| **No Obsidian, no Electron** | Vault-shaped files, readers in the agent UI |
| **No Chromium/Chrome as a product** | Breaks the RAM budget; PDF.js needs a **small** WebView — see §5 |
| **niri is not in Ubuntu 24.04** | Pin a **built binary** in the factory image, or fall back to **sway** (in-archive) until 26.04 |
| **wireguard-tools + module** | `ael0` for regions / mobile |
| **btrfs-progs** | Omarchy-style receive |
| **Guest agents still adapt-only** | Not in the default image |
| **No cups/avahi/bluetooth** on server; bluetooth **off** on desktop until hardware SKU |
| **ca-certificates, openssl** | mTLS + rclone HTTPS |
| **One PDF engine** | typst **or** weasyprint, not both; not reportlab; not Chrome CDP |

dsh001 floor still holds for **server**. Desktop idle 1.0–1.2 GiB is **unproven** until the WebView is chosen.

---

## 2. Kernel

**Packages**

- VM image: `linux-image-virtual`, `linux-modules-virtual`
- Metal image: `linux-image-generic`, `linux-modules-extra-generic` **only on metal** (wifi/nic). Do not put `linux-modules-extra` on the VM flavour.
- `linux-firmware` on metal only
- **Not default:** `linux-modules-nvidia-*`, `dkms`, `nvidia-driver-*`, `linux-oem-*`

**Modules — load (builtin or initramfs)**

| Module | Who | Why |
|---|---|---|
| `ext4` | installer ESP/fallback | ESP is vfat; root is btrfs |
| `btrfs` `xor` `raid6_pq` `zstd` | all | root |
| `vfat` `nls_cp437` `nls_iso8859-1` | all | ESP |
| `virtio_pci` `virtio_blk` `virtio_net` `virtio_scsi` `virtio_console` `virtio_balloon` | VM | QEMU/KVM |
| `overlay` | all | (optional) |
| `wireguard` | all | `ael0` |
| `tun` | all | WG |
| `dm_mod` `dm_crypt` | optional | LUKS off by default — **omit from default initramfs** |
| `nf_tables` `nft_ct` `nft_limit` `xt_tcpudp` | all | nftables |
| `kvm` `kvm_intel`/`kvm_amd` | **not** default | only a hypervisor flavour |

**Blacklist / do not ship in default initramfs**

- `nouveau`, `nvidia*`, `amdgpu` on **server VM**
- Desktop metal: `amdgpu`/`i915`/`xe` as needed for **that** hardware ISO, not a union of all GPUs
- `bluetooth` `btusb` on server; desktop: present, **blocked** until SKU
- `nfs` `cifs` `smb` — vault is fabric, not CIFS. **No** `cifs-utils` in default (rclone talks HTTPS)
- `firewire`, `pcspkr`

**sysctl (not packages):** ip_forward=0 on clients; server may forward `ael0` only.

---

## 3. `ael-base` (every Linux SKU)

Keep tiny:

- `systemd` `udev` `dbus` `kmod` `util-linux` `coreutils` `bash` `dash` `grep` `sed` `gawk` `tar` `gzip` `xz-utils` `ca-certificates` `openssl`
- `openssh-server` `openssh-client`
- `nftables` `iptables` (nft backend) — `ufw` **optional**; prefer raw nftables, drop ufw if it pulls extra
- `chrony`
- `sudo`
- `iproute2` `iputils-ping` `less` `vim-tiny` **or** none — `nano` not required
- `btrfs-progs` `e2fsprogs` `dosfstools` `efibootmgr` `systemd-boot` (or `grub-efi` if UKI not ready — pick **one**)
- `wireguard-tools`
- `apparmor` (Ubuntu default profiles only)
- `unattended-upgrades` **security pocket only**, no GUI

**Purge:** `snapd` `snapd-seed` `popularity-contest` `apport` `whoopsie` `ubuntu-report` `landscape-client` `cloud-init` **on metal desktop**; keep `cloud-init` on **server/VM**. `lxd` `lxc` `docker.io` `podman` — **not default**.

---

## 4. `ael-agent` + `ael-fabric` (every Linux SKU)

- Pinned **Node** (whatever DSH/Pi actually need — one major, locked in `versions.lock`)
- Pi / orchestrator tarball (not npm-global `latest`)
- DSH pinned; bind `127.0.0.1` only
- `ael-fabricd` (our binary)
- `python3` `python3-venv` `python3-pip` **or** vendor wheels in `/opt/ael` — prefer vendored, no pip-to-PyPI at runtime

**Not:** docker, podman, k3s, nginx on the LAN, Caddy as a public server.

---

## 5. `ael-artefacts` (server + both desktops)

Vendored / pinned:

- `python3-openpyxl` `python3-lxml` `python3-docx` (check Ubuntu names) + `python-pptx` if packaged else wheel
- **One** of: `typst` static binary **or** `weasyprint` + `python3-weasyprint` + `pango`/`cairo` (heavier). **Prefer typst** to avoid Chromium.
- Fonts: `fonts-ibm-plex`; Libre Baskerville — Debian `fonts-libre-baskerville` if in Ubuntu, else ship files under `/usr/share/ael/fonts/`
- **Not:** LibreOffice, OnlyOffice, pandoc+texlive, `chromium-browser`, `firefox`, `cups`

**WebView (desktop only, the budget risk):**  
Need PDF.js + vault pane. Options, pick **one** in the factory image:

1. `webkit2gtk-4.1` + a tiny wrapper (preferred vs Chrome)
2. `wlr-which` + `cage` running one GTK window

Do **not** install `chromium` / `google-chrome` / `microsoft-edge`.

---

## 6. `ael-vault`

**Server:** `git` `git-lfs` **not required**; `rclone` (OneDrive + Drive backends compiled in — stock rclone is enough). Empty `/etc/ael/rclone.conf.example`. No fuse **required** if we sync to disk; `fuse3` only if we later mount remotes — **omit by default** (mounts leak).

**Clients:** no rclone. Fabric sync daemon only (`ael-vault-sync`).

---

## 7. `ael-server` extra

- `python3` stack above
- Hermes **`azure-foundry` plugin** + vendored `azure-identity` (pinned in `versions.lock`). Empty stub config. **No** Foundry URL/key in the ISO. **Default LLM path:** children call the father (`Job.Complete`); father cascades. Direct `Cap.LlmProfile` is break-glass only.
- `qemu-guest-agent` **not** here — `ael-adapt`
- `smartmontools` only after adapt on metal
- **Not:** greetd, seatd, mesa, pipewire, fonts-noto-extra, `xdg-desktop-portal`, `azure-cli`

Optional flavour (not default ISO): `llama.cpp` **or** vLLM, never both.

---

## 8. `ael-client` (office = consumer packages)

- `seatd` `greetd` `cage` (first-run)
- Compositor: **pinned `niri` binary** in `/usr/local` **or** Ubuntu `sway` + `swaybg` if we refuse out-of-archive. Hyprland **not** default.
- `foot` or `alacritty` — **one** terminal, break-glass
- `xdg-utils` minimal; `zathura` + `zathura-pdf-poppler` **optional** break-glass reader
- `mesa-vulkan-drivers` / `libgl1-mesa-dri` matching the ISO’s GPU (VM: `virtio-gpu` → `mesa`)
- `pipewire` `wireplumber` `pipewire-audio` — **consumer + office** for a real session; **not** on server. Keep Pulse compat off if unused.
- `wl-clipboard`
- **Not:** GDM, GNOME, NetworkManager-gnome, `nautilus`, `gvfs` extra backends, `evolution-data-server`, `geoclue-2.0`, `cups`, `avahi-daemon`, `bluez` (enable via adapt if laptop SKU), `firefox`, `thunderbird`

Office vs consumer: **same packages.** Catalogue JSON + pairing class only.

---

## 9. `ael-adapt` (not in the image; pulled from Ubuntu signed repos)

| Profile | Packages |
|---|---|
| qemu/kvm | `qemu-guest-agent` |
| vmware | `open-vm-tools` (server: no `-desktop`) |
| hyperv | `hyperv-daemons` |
| azure | WALinuxAgent **only on Azure** |
| metal laptop | `bluez` `linux-firmware` wifi as needed |
| metal + IPMI | `ipmitool` if DMI says so |

---

## 10. Explicitly never default

`snapd`, LibreOffice, GIMP, Inkscape, Docker, Podman, k8s, Synapse/Conduit (Matrix = flavour), Teams **desktop**, Slack, `cifs-utils`, `nfs-common`, `samba`, `nginx`, `apache2`, `postfix`, `avahi`, `cups`, `ubuntu-desktop`, `gnome-shell`, `sddm`, `lightdm`, `xorg` (Wayland only), `obsidian`, `code`, `docker-compose`, `azure-cli`, `powershell`, Power BI Desktop.

Microsoft Graph / Fabric / Azure OpenAI: small vendored client in `ael-teamsd` / `ael-msgraphd` on the **father** after consent — not the Azure CLI.

---

## 11. Mobile

Zero of the above. One APK. TLS + fabric client + PDF/grid reader. No GMS.

---

## 12. Initramfs hook list (default)

`btrfs`, `vfat`, virtio set (VM), `nf_tables`, **not** `cryptsetup` unless LUKS SKU.
