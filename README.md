# Shadow.iso

A lightweight, minimal, customized **Kali Linux Live ISO** built on the official
Kali `live-build` framework, with a KDE-like (Breeze-themed) but RAM-friendly
custom desktop based on **Openbox**.

- Fully bootable Live ISO (UEFI + Legacy BIOS + USB)
- Built with Kali's official `live-build` workflow
- Automated builds via **GitHub Actions** (no local machine required)
- Targeted at low-end PCs with **512 MB – 1 GB RAM**
- **No KDE Plasma**, no full Kali security-tool collection
- Lightweight Shadow desktop: Openbox + tint2 + dmenu + Thunar + LightDM
- `apt` / `dpkg` fully functional — install any extra Kali tool later

## Profiles

| Profile   | Contents                                                       | Output                  |
|-----------|----------------------------------------------------------------|-------------------------|
| `minimal` | Kali base + Shadow desktop + base business/security tools      | `shadow-minimal.iso`    |
| `extended`| minimal + additional selected security tools                  | `shadow-extended.iso`   |

Both also produce a generic `shadow.iso` alias, a `.sha256`, and a `.buildinfo.txt`.

## Repository structure

```
shadow-iso/
├── .github/workflows/build-kali.yml   # GitHub Actions cloud build
├── auto/                              # forked from official kali-live (lb config/clean)
├── kali-config/
│   ├── common/
│   │   ├── package-lists/             # custom-base / custom-desktop / business-tools
│   │   ├── includes.chroot/           # lightdm, openbox, xsessions, themes, skel
│   │   └── hooks/live/9900-shadow-customize.hook.chroot
│   ├── variant-minimal/               # minimal profile (uses common lists)
│   └── variant-extended/              # extended profile (adds more tools)
├── build.sh                           # profile-aware wrapper (minimal|extended)
├── README.md
└── LICENSE
```

Customization is applied as **overlays** on top of the official Kali
configuration — upstream package lists and hooks are reused, not replaced.

## Requirements (local build)

- A Debian-based host (Kali/Debian/Ubuntu)
- `live-build` >= `1:20250814+kali2`, `debootstrap`, `xorriso`, `mtools`, `sudo`
- Root (or passwordless `sudo`)
- ~15 GB free disk and a decent network connection

## Build locally

```sh
# minimal profile
./build.sh minimal

# extended profile
./build.sh extended

# via env var
PROFILE=extended ./build.sh
```

Output lands in `images/shadow-<profile>.iso` (+ `.sha256`, `.buildinfo.txt`).

## GitHub Actions

1. Push this repo to GitHub.
2. **Actions → Build Shadow.iso → Run workflow**.
3. Choose `profile` (`minimal`/`extended`) and optionally `create_release`.
4. Download the `shadow-<profile>` artifact (ISO + SHA256 + buildinfo).
5. If `create_release=true`, a GitHub Release is created automatically
   (no secrets/tokens are hard-coded; `GITHUB_TOKEN` is used).

## Writing to USB

```sh
sudo dd if=images/shadow-minimal.iso of=/dev/sdX bs=4M status=progress conv=fsync
# or use: sudo cp shadow-minimal.iso /dev/sdX   (then sync)
```

## Testing

### QEMU (BIOS)
```sh
qemu-system-x86_64 -m 1024 -cdrom images/shadow-minimal.iso
```

### QEMU (UEFI)
```sh
qemu-system-x86_64 -m 1024 -machine q35 -bios /usr/share/ovmf/OVMF.fd \
  -cdrom images/shadow-minimal.iso
```

### Verify
```sh
sha256sum -c images/shadow-minimal.iso.sha256
```

## Desktop usage

- **Login**: LightDM → select **Shadow** session.
- **Launcher**: `Super+Space` (dmenu)
- **Terminal**: `Super+Enter` (st)
- **File manager**: `Super+E` (Thunar)
- **Show desktop**: `Super+D`
- **Workspaces**: `Super+1..4`
- **Close window**: `Alt+F4`
- **Logout / Reboot / Shutdown**: right-click desktop → Shadow menu, or
  `Super+L` lock, `XF86PowerOff`/`XF86Reboot` keys.

## Network / Wi-Fi
```sh
nmcli device status          # list devices
nmcli device wifi list       # scan Wi-Fi
nmcli device wifi connect SSID --ask
```

## USB / storage
```sh
lsblk
udisksctl status
# Thunar mounts/unmounts volumes automatically via udisks2 + gvfs
```

## Audio
```sh
wpctl status                 # PipeWire
```

## APT / install more tools
```sh
sudo apt update
sudo apt install <package>   # any Kali tool (e.g. metasploit-framework)
```

## RAM optimization

Idle target ≈ 250–400 MB. `zram` is enabled; Bluetooth, CUPS, Avahi,
ModemManager and PackageKit are **masked** by default (re-enable with
`systemctl unmask <svc> && systemctl enable --now <svc>`). `picom` is installed
but disabled.

Check RAM / services:
```sh
free -h
ps -eo pid,comm,rss,%mem,%cpu --sort=-rss | head -25
systemd-analyze blame
zramctl
swapon --show
systemctl --type=service --state=running
```

## Customizing

- **Business/security tools**: edit
  `kali-config/common/package-lists/business-tools.list.chroot`
  (base set) and `kali-config/variant-extended/package-lists/profile.list.chroot`
  (extended-only tools). Verify package names against the current Kali repo.
- **Desktop**: `kali-config/common/includes.chroot/etc/xdg/openbox/`
  (rc.xml, menu.xml, autostart), `.../etc/lightdm/`, `.../usr/share/themes/`,
  `.../usr/share/icons/`, `.../usr/share/backgrounds/`.
- **Theme**: Breeze GTK/Qt themes + Breeze icons are set by default in the hook
  and `/etc/environment.d/90-shadow.conf`.
- **Wallpaper**: replace `kali-config/common/includes.chroot/usr/share/backgrounds/shadow.png`.
- **Rebuild**: re-run `./build.sh <profile>`.

## Troubleshooting

- Build fails with `Can't build ... on ... system`: cross-arch builds are only
  supported amd64<->i386.
- `live-build` version error: install Kali's `live-build`
  (`>= 1:20250814+kali2`).
- No Wi-Fi in VM: pass a USB Wi-Fi adapter or use `e1000`/`virtio` NIC.
