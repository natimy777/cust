# my-hyprland-dotfiles

[![CI](https://github.com/Kernel236/my-hyprland-dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/Kernel236/my-hyprland-dotfiles/actions/workflows/ci.yml)
[![Stars](https://img.shields.io/github/stars/Kernel236/my-hyprland-dotfiles?label=thanks%20for%20the%20%E2%AD%90&color=grey)](https://github.com/Kernel236/my-hyprland-dotfiles/stargazers)
[![Made with love](https://img.shields.io/badge/made%20with-%E2%9D%A4-red)](https://github.com/Kernel236/my-hyprland-dotfiles)

Hyprland rice for Arch Linux with a dual-theme system: **Catppuccin Macchiato** for daily use and **red-on-black**, for when the mood calls for it. Theme switching is live with one click in the bar or a keyboard shortcut, and every component updates without restarting anything.

The goal is a Hyprland setup that is ready for daily use out of a fresh Arch install. The architecture is modular without becoming overly complex: no config overrides, no duplicate files, and no need to rebuild everything just to customize it. 
It sits between a minimal base dotfile and a fully-featured rice like the most popular ones. Almost every config file includes inline comments pulled from the official documentation, so experimenting with options is quick and low-friction.
The aim is not just to look polished, but to stay practical, readable, and easy to extend.

---

## Preview

![preview](screenshots/preview.gif)

## Workflow demo

Full workflow demo on r/unixporn: [My first Hyprland full dual setup, no preconfig](https://www.reddit.com/r/unixporn/comments/1t1uams/my_first_hyprland_full_dual_setup_no_preconfig_no/) 
- New features have been added since that video.

---

## Screenshots

<table>
  <tr>
    <th>Catppuccin Macchiato</th>
    <th>Red on Black</th>
  </tr>
  <tr>
    <td><img src="screenshots/btop_catppuccin.png"/></td>
    <td><img src="screenshots/btop_matrix.png"/></td>
  </tr>
  <tr>
    <td><img src="screenshots/rofi_wallpaper_catppuccin.png"/></td>
    <td><img src="screenshots/rofi_wallpaper_matrix.png"/></td>
  </tr>
  <tr>
    <td><img src="screenshots/rofi_on_yazi_catppuccin.png"/></td>
    <td><img src="screenshots/rofi_on_yazi_matrix.png"/></td>
  </tr>
</table>

---

## Components

| Role | Tool |
|---|---|
| Compositor | Hyprland 0.55+ (Lua config) |
| Bar | Waybar |
| Terminal | Kitty |
| Notification center | sway-notification-center |
| App launcher | Rofi (Wayland) |
| Fetch | Fastfetch |
| Logout screen | wlogout |
| System monitor | btop |
| Wallpaper daemon | awww |
| Lock / idle | hyprlock + hypridle |
| Clipboard | cliphist + wl-paste |
| Editor | Neovim (lazy.nvim, LSP, Treesitter) |
| Shell | Zsh + Powerlevel10k |
| File manager | yazi |

**Font:** JetBrainsMono Nerd Font  
**Icons:** Tela-circle-dracula — AUR `tela-circle-icon-theme-dracula-git` (optional)  
**GTK theme:** Catppuccin — AUR `catppuccin-gtk-theme-mocha` (optional)  
AUR packages are never installed automatically: read each PKGBUILD first, then `makepkg -si`.

---

## Installation

> Arch Linux only. This setup assumes a mostly clean Arch base install with internet access. No AUR helper is needed.

1. Clone the repo:
   ```bash
   git clone https://github.com/Kernel236/my-hyprland-dotfiles ~/my-hyprland-dotfiles
   ```

2. Run the installer:
   ```bash
   cd ~/my-hyprland-dotfiles
   bash install.sh
   ```

   The installer will:
   - Check for missing packages and install them with `pacman` (names that are not in your enabled repos are listed and skipped instead of aborting the install)
   - Ask whether to install optional components: **Kitty**, **Zsh + Powerlevel10k**, **Neovim**, extras. Answering `n` skips the packages and the symlink for that component
   - Offer to build **wlogout** from the AUR: it shows you the PKGBUILD, asks for confirmation, imports the signing key the PKGBUILD declares, then runs `makepkg -si`
   - Create symlinks from `~/.config/` into the repo (existing configs are moved to `*.bak`, never overwritten)
   - Copy wallpapers and assets to `~/.config/assets`
   - Generate the per-user theme files (see *Theme switching*) and apply the macchiato theme

   The repo has to stay where you cloned it: `~/.config/*` are symlinks into it.

3. Log out and back in, then start Hyprland:
   ```bash
   uwsm start hyprland
   ```

Any future edit to the repo is reflected immediately. Symlinks keep `~/.config/` in sync with the repo.

Nvidia users: the Nvidia environment variables in `hyprland.lua` are only set when the proprietary driver is loaded, and you need `nvidia_drm.modeset=1` on the kernel command line.

To add the BlackArch repository (optional), follow the official instructions at https://blackarch.org/downloads.html#install-repo

If something does not work after install, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

---

## Uninstallation

`uninstall.sh` reverses everything the installer did while leaving the system bootable.

```bash
bash ~/my-hyprland-dotfiles/uninstall.sh
```

What it removes:
- Config symlinks in `~/.config/` (only if they point into this repo)
- Scripts in `~/.local/bin/` (same guard)
- `~/.config/assets` (asks first, it may contain your own wallpapers)
- `~/.zshrc` symlink and the powerlevel10k clone; switches the login shell back to bash only if it is zsh and you confirm

What it keeps:
- `sddm`, `hyprland`, `uwsm`, `kitty`, `base-devel`, `pacman-contrib`, and the audio stack, so the system stays bootable

Packages from packages-core.txt and packages-optional.txt are listed before removal and require a second confirmation. Once you install another DE you can cleanly remove Hyprland with:

```bash
sudo pacman -Rns hyprland uwsm xdg-desktop-portal-hyprland
```

---

## Theme switching

Switch theme from the bar (click the theme indicator) or directly from a terminal:

```bash
~/.config/waybar/scripts/theme-switch.sh macchiato
~/.config/waybar/scripts/theme-switch.sh matrix
```

The script swaps symlinks for Hyprland, Waybar, Kitty, swaync and Rofi, and generates `hyprlock.conf` and the fastfetch config (filling in your `$HOME`, the current wallpaper and avatar). All of these files are git-ignored: they differ per machine, so they are never committed. No restart needed.

---

## Neovim

Config lives in `.config/nvim/` and is symlinked to `~/.config/nvim` by the installer.

**Plugin manager:** lazy.nvim (auto-bootstrapped on first launch)

**LSP servers** (auto-installed via Mason on first launch):

| Language | Server |
|---|---|
| Python | pyright |
| Lua | lua-language-server |
| Bash | bash-language-server |
| C / C++ | clangd |
| HTML | html-lsp |
| CSS | css-lsp |
| Rust | rust-analyzer |

Remove the languages you do not use.

**Plugins:** Telescope, nvim-treesitter, nvim-cmp + LuaSnip, lualine, indent-blankline, nvim-autopairs, nvim-surround, catppuccin

**Theme:** Catppuccin Macchiato with transparent background. Opacity and blur are managed by Hyprland on the Kitty window.

**First launch:** Mason installs all LSP servers automatically (takes ~1-2 min on first launch).

---

## Wallpapers

Wallpapers are split by theme in `assets/backgrounds/`:

- `whitehat/` — used with macchiato
- `blackhat/` — used with matrix

This lite edition ships one original generated wallpaper per theme (`default-dusk-torii.jpg`, `default-neon-grid.jpg`). Drop any `.jpg`/`.png`/`.webp` into either folder (or into `~/.config/assets/backgrounds/<theme>/`) and it is picked up automatically, by the picker, the login wallpaper and the lock screen. Lock-screen avatars live in `assets/avatars/`; replace them with your own picture.

The wallpaper picker (`Super + Shift + W`) opens a Rofi gallery. A random wallpaper from the active theme folder is also set automatically on login.

---

## Keybinds

A cheatsheet overlay is available at any time with `Super + I`. All bindings are defined in `.config/hypr/conf/keybinds.lua`.

---

## Structure

```
my-hyprland-dotfiles/
├── .config/                mirrors ~/.config/ - each subdirectory is symlinked by install.sh
│   ├── hypr/               Hyprland config (Lua), hypridle, hyprlock, scripts, themes
│   ├── waybar/             bar config, per-module CSS, scripts, themes
│   ├── kitty/              terminal config and themes
│   ├── swaync/             notification center config and themes
│   ├── rofi/               launcher, wallpaper picker, themes
│   ├── fastfetch/          per-theme fetch configs
│   ├── wlogout/            logout screen layout and icons
│   ├── btop/               system monitor config
│   └── nvim/               Neovim config (lazy.nvim, LSP, Treesitter, catppuccin)
├── .zshrc                  Zsh config (powerlevel10k, autosuggestions, syntax highlighting)
├── .local/
│   └── bin/                rofi-launcher, rofi-wallpaper, rofi-clipboard
├── assets/                 wallpapers, lock-screen avatars, wlogout icons
├── screenshots/            preview GIFs for the README
├── packages-core.txt       required packages (always installed)
├── packages-optional.txt   optional packages (Kitty, Zsh, Neovim, extras - installer asks)
├── install.sh              installer - symlinks, packages, optional components
├── uninstall.sh            uninstaller - removes symlinks, assets, packages
├── README.md
└── TROUBLESHOOTING.md      common issues and fixes
```

---

## Security notes

- Nothing is downloaded or run behind your back: the only network use is `git clone` of powerlevel10k and lazy.nvim, the weather module (`wttr.in`, remove `custom/weather` from the waybar config to disable it), and the optional wlogout AUR build, which shows the PKGBUILD first.
- The clipboard history (`cliphist`) is stored on disk in `~/.cache/cliphist`, capped at 200 entries. Wipe it with `cliphist wipe`. Not every password manager marks what it copies as sensitive, so avoid copying secrets you do not want kept, or wipe afterwards.
- `uninstall.sh` never deletes `~/.config/assets` or changes your login shell without asking.
- Per-user generated files, logs and caches go to your own `$XDG_RUNTIME_DIR`, not to `/tmp`.
- Bundled third-party material is listed in [THIRD_PARTY.md](THIRD_PARTY.md).

