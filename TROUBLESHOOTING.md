# Troubleshooting

Common issues and fixes after installing this rice. These are problems encountered during real configuration - if you run into something not covered here, open an issue.

---

## wlogout build fails / AUR packages fail

`install.sh` builds wlogout with `makepkg`, which needs `base-devel` (it provides `fakeroot` and `debugedit`):

```bash
sudo pacman -S --needed base-devel
```

Typical errors:

- `Cannot find the fakeroot binary` / `debugedit binary` → install `base-devel` as above, then re-run `cd ~/wlogout-aur && makepkg -si`.
- A signature / `unknown public key` error → import the key listed in `validpgpkeys` of the PKGBUILD, then retry:

  ```bash
  gpg --recv-keys $(grep -oE '[0-9A-F]{40}' ~/wlogout-aur/PKGBUILD)
  ```

  Check that the key's owner name matches the upstream author before trusting it (`gpg --list-keys`).

Re-running `install.sh` is safe: it skips everything that is already done.

---

## Hyprland does not start / black screen after login

Hyprland is launched via `uwsm`. Make sure uwsm is configured correctly for your setup — see the [Arch wiki page on uwsm](https://wiki.archlinux.org/title/Hyprland#With_uwsm).

Common causes:

- **Missing polkit agent** - `polkit-kde-agent` must be installed and is autostarted in `.config/hypr/conf/autostart.lua`. Verify it is running: `pgrep polkit-kde-agent`.
- **XDG portal conflict** - only `xdg-desktop-portal-hyprland` should be active. Remove other portal packages if present: `sudo pacman -Rns xdg-desktop-portal-wlr` (keep `xdg-desktop-portal-gtk` if GTK apps need file pickers, it coexists with the Hyprland portal).
- **GPU driver missing** - install your driver before starting Hyprland (e.g. `mesa` for AMD/Intel, `nvidia-dkms` + `nvidia-utils` for Nvidia, plus `nvidia_drm.modeset=1` on the kernel command line).

Check the Hyprland log for the exact error:

```bash
cat /tmp/hypr/$(ls -t /tmp/hypr | head -1)/hyprland.log | tail -50
```

---

## Waybar does not appear

If Waybar crashes on launch, run it manually to see the error:

```bash
waybar 2>&1 | head -30
```

Common causes:

- **JSON syntax error in config** - validate with: `jq . ~/.config/waybar/config.jsonc`
- **Missing module binary** - e.g. `cliphist`, `wl-paste`, `jq` not installed. Check `packages-core.txt`.
- **Wrong Hyprland IPC socket** - make sure `HYPRLAND_INSTANCE_SIGNATURE` is set in the environment. It is set automatically by uwsm.

---

## Rofi does not open

Check that `rofi` is installed and is a Wayland-capable build (current `rofi` from the official repos is):

```bash
rofi -version
```

If the output has no Wayland support, you probably have an old X11-only build or a leftover `rofi-wayland` package; remove it and install the official one:

```bash
sudo pacman -Rns rofi-wayland   # only if installed
sudo pacman -S rofi rofi-calc rofi-emoji
```

---

## Theme not applied / wrong colors after theme-switch

If `theme-switch.sh` runs but colors do not update:

1. **Waybar** - the script sends `SIGUSR2` to reload. If Waybar is not running, start it first.
2. **Kitty** - receives `SIGUSR1`. If Kitty windows do not update, close and reopen them.
3. **swaync** - the script restarts it via `~/.config/swaync/restart`. Check that file is executable: `ls -la ~/.config/swaync/restart`.
4. **Hyprland** - `hyprctl reload` is called. Check `$XDG_RUNTIME_DIR/theme-switch-hypr.log` for errors.
5. **Wallpaper** - `awww` must be running. Verify: `pgrep awww`. It is autostarted in `autostart.lua`.

The theme files (`hypr/theme.lua`, `hypr/hyprlock.conf`, `waybar/theme.css`, ...) are generated per user by this script; if one is missing, running it recreates them.

Run the switch manually to see output:

```bash
bash ~/.config/waybar/scripts/theme-switch.sh macchiato
```

---

## Fonts look wrong / icons are missing boxes

Missing Nerd Font or emoji font. Verify the fonts are installed:

```bash
fc-list | grep -i "JetBrains"
fc-list | grep -i "Noto.*Emoji"
```

If missing, install them:

```bash
sudo pacman -S ttf-jetbrains-mono-nerd noto-fonts-emoji
```

Then rebuild the font cache:

```bash
fc-cache -fv
```

Log out and back in - some apps (Waybar, Kitty) cache the font list at startup.

---

## Zsh / Powerlevel10k prompt looks broken

- **First login after install** - `p10k configure` runs automatically on the first Zsh launch. Complete the wizard to generate `~/.p10k.zsh`.
- **Prompt characters are boxes** - the JetBrainsMono Nerd Font is not active in your terminal. Set it in Kitty: `font_family JetBrainsMono Nerd Font`.
- **Plugins missing** - `zsh-autosuggestions` and `zsh-syntax-highlighting` must be installed as system packages (they are in `packages-optional.txt`); `.zshrc` sources them from `/usr/share/zsh/plugins`. Check that the symlink is correct: `ls -la ~/.zshrc`.

---

## Neovim: Mason fails to install LSP servers

Mason needs the runtime dependencies from `packages-optional.txt` (`nodejs`, `npm`, `python-pip`) plus `gcc` and `make` from core. If you skipped Neovim during install and later want it:

```bash
sudo pacman -S neovim lazygit nodejs npm python-pip
bash ~/my-hyprland-dotfiles/install.sh   # re-run - it skips already-done steps
```

Inside Neovim, run `:Mason` to check server status and `:MasonInstall <server>` to install individually.

---

## Lock screen has no background or avatar

`hyprlock.conf` is generated by `theme-switch.sh` from the theme template. If the wallpaper folder is empty the lock screen falls back to a solid color, and the avatar comes from `~/.config/assets/avatars/`. Add images there and run `theme-switch.sh <theme>` once. Test the lock screen while still logged in: `hyprlock`.

---

## Uninstaller leaves something behind

`uninstall.sh` only removes symlinks that point into the repo. If a config directory was backed up (e.g. `~/.config/hypr.bak`) during install, remove it manually:

```bash
rm -rf ~/.config/hypr.bak
```

The uninstaller does not touch `~/.p10k.zsh` or any file not created by the installer.
