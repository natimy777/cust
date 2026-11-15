#!/usr/bin/env bash
set -euo pipefail

# ── Banner ───────────────────────────────────────────────────────────────────
figlet -f slant "Hyprland Rice" 2>/dev/null || true
echo "   my-hyprland-dotfiles installer"
echo

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Colors & helpers ─────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { echo -e "  ${GREEN}✓${NC}  $*"; }
warn()  { echo -e "  ${YELLOW}!${NC}  $*"; }
die()   { echo -e "  ${RED}✗  $*${NC}" >&2; exit 1; }
step()  { echo -e "\n${CYAN}▶ $*${NC}"; }
ask_yn() { local _a; read -rp "  $1 [Y/n] " _a; [[ -z "$_a" || "$_a" =~ ^[Yy]$ ]]; }

# ── Pre-flight checks ─────────────────────────────────────────────────────────
[[ "$EUID" -eq 0 ]]         && die "Do not run as root."
command -v pacman &>/dev/null || die "pacman not found — this installer is Arch Linux only."
[[ -f "$DOTFILES/packages-core.txt" ]]     || die "packages-core.txt not found in $DOTFILES"
[[ -f "$DOTFILES/packages-optional.txt" ]] || die "packages-optional.txt not found in $DOTFILES"

# ── What this installs ────────────────────────────────────────────────────────
echo -e "  Dotfiles from: ${CYAN}$DOTFILES${NC}"
echo
echo "  Components that will be configured:"
echo "    Hyprland 0.55+    Wayland compositor (Lua config)"
echo "    Waybar            status bar"
echo "    Rofi              app launcher, clipboard picker, emoji"
echo "    Kitty             terminal (optional)"
echo "    swaync            notification center"
echo "    wlogout           session logout screen"
echo "    Fastfetch         system fetch"
echo "    btop              system monitor"
echo "    Neovim            text editor (lazy.nvim, LSP, Treesitter) (optional)"
echo "    Zsh               shell (powerlevel10k, autosuggestions, syntax highlight) (optional)"
echo "    hyprlock          lock screen"
echo "    hypridle          idle / power management daemon"
echo "    yazi              terminal file manager (via kitty, optional)"
echo "    awww              wallpaper daemon"
echo "    cliphist          clipboard history (wl-paste)"
echo "    extras            cava, extra fonts, vim, figlet, cmatrix, imv, ncdu... (optional)"
echo
echo "  Assets (copied to $HOME/.config/assets):"
echo "    Wallpapers            whitehat/ + blackhat/ (add your own to these folders)"
echo "    Lock-screen avatars   avatars/whitehat.png + avatars/blackhat.png (replace with yours)"
echo "    wlogout icons         lock, logout, power, sleep, restart"
echo "    Icon + GTK theme      optional, AUR only (not bundled in repo)"
echo
read -rp "  Proceed? [y/N] " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

# ── Optional components ───────────────────────────────────────────────────────
echo
if ask_yn "Install Kitty terminal?";  then INSTALL_KITTY=true; else
    INSTALL_KITTY=false
    warn "Without Kitty, SUPER+T, SUPER+F, SUPER+I and the Wi-Fi button in swaync have no terminal to open. Make sure another terminal is installed and change 'terminal' in .config/hypr/conf/keybinds.lua."
fi
if ask_yn "Install Zsh + Powerlevel10k?"; then INSTALL_ZSH=true; else INSTALL_ZSH=false; fi
if ask_yn "Install Neovim?";          then INSTALL_NVIM=true;   else INSTALL_NVIM=false;  fi
if ask_yn "Install extras (cava, extra fonts, vim, figlet, cmatrix, imv, ncdu...)?"; then INSTALL_EXTRAS=true; else INSTALL_EXTRAS=false; fi
echo

SKIP_PKGS=()
$INSTALL_KITTY  || SKIP_PKGS+=(kitty yazi)
$INSTALL_ZSH    || SKIP_PKGS+=(zsh zsh-autosuggestions zsh-completions zsh-syntax-highlighting)
$INSTALL_NVIM   || SKIP_PKGS+=(neovim lazygit nodejs npm python-pip)
$INSTALL_EXTRAS || SKIP_PKGS+=(figlet cmatrix hunspell-it ttf-firacode-nerd ttf-cascadia-code-nerd ttf-cascadia-mono-nerd ttf-iosevka-nerd ttf-iosevkaterm-nerd ttf-fira-mono ttf-fira-sans cava easyeffects vim ex-vi-compat imv ncdu iotop vimix-cursors)

# ── Step 1: Package check ─────────────────────────────────────────────────────
step "1/6  Checking packages"

total=0
missing=()
while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*# || -z "${line// }" ]] && continue
    pkg="${line%%#*}"
    pkg="${pkg//[[:space:]]}"
    [[ -z "$pkg" ]] && continue
    [[ " ${SKIP_PKGS[*]} " == *" $pkg "* ]] && continue
    (( total++ )) || true
    pacman -Q "$pkg" &>/dev/null || missing+=("$pkg")
done < <(cat "$DOTFILES/packages-core.txt" "$DOTFILES/packages-optional.txt")

installed=$(( total - ${#missing[@]} ))
echo "  $installed / $total packages already installed"

if [[ ${#missing[@]} -gt 0 ]]; then
    warn "${#missing[@]} missing packages:"
    printf '      %s\n' "${missing[@]}"
    echo

    # A single unknown package name makes `pacman -S` abort the whole transaction, so
    # drop names the sync databases do not know and report them instead.
    installable=(); unavailable=()
    if pacman -Si pacman &>/dev/null; then
        for pkg in "${missing[@]}"; do
            if pacman -Si "$pkg" &>/dev/null; then installable+=("$pkg"); else unavailable+=("$pkg"); fi
        done
    else
        warn "pacman sync databases look empty; run 'sudo pacman -Sy' first if installation fails."
        installable=("${missing[@]}")
    fi
    if [[ ${#unavailable[@]} -gt 0 ]]; then
        warn "Not found in the enabled repos, skipped (rename, AUR-only or repo disabled):"
        printf '      %s\n' "${unavailable[@]}"
        echo
    fi

    if [[ ${#installable[@]} -gt 0 ]]; then
        read -rp "  Install ${#installable[@]} packages with pacman? [y/N] " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            sudo pacman -S --needed "${installable[@]}"
        else
            warn "Skipping. Some features may not work."
        fi
    fi
else
    info "All $total packages present."
fi

# wlogout (SUPER+ESC and the swaync power button) is AUR-only. Build it from the AUR
# repo, but only after you have read the PKGBUILD and confirmed.
build_wlogout() {
    local dir="$HOME/wlogout-aur" keys
    command -v makepkg &>/dev/null || { warn "makepkg not found (install base-devel), skipping wlogout."; return 0; }
    if [[ ! -d "$dir/.git" ]]; then
        git clone https://aur.archlinux.org/wlogout.git "$dir" || { warn "Could not clone the AUR repo, skipping wlogout."; return 0; }
    fi
    echo "  Opening the PKGBUILD so you can read it (q to close)..."
    ${PAGER:-less} "$dir/PKGBUILD"
    ask_yn "PKGBUILD looks fine, build and install wlogout?" || { warn "Skipped wlogout."; return 0; }
    # Import the signing key(s) the PKGBUILD itself declares, so the source tarball is verified.
    keys=$(grep -oE '[0-9A-F]{40}' "$dir/PKGBUILD" | sort -u || true)
    if [[ -n "$keys" ]]; then
        # shellcheck disable=SC2086
        gpg --recv-keys $keys || warn "Could not fetch the signing key; makepkg may fail on signature verification."
    fi
    ( cd "$dir" && makepkg -si ) || warn "wlogout build failed (see TROUBLESHOOTING.md)."
}

if ! command -v wlogout &>/dev/null; then
    echo
    warn "wlogout is not installed (AUR only)."
    if ask_yn "Build wlogout from the AUR now?"; then build_wlogout; else
        echo "      Later: git clone https://aur.archlinux.org/wlogout.git ~/wlogout-aur && less ~/wlogout-aur/PKGBUILD"
    fi
fi

# ── Symlink helper ────────────────────────────────────────────────────────────
link() {
    local src="$1" dst="$2"
    if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
        info "already linked  $dst"
        return
    fi
    if [[ -e "$dst" && ! -L "$dst" ]]; then
        local bak="${dst}.bak"
        [[ -e "$bak" || -L "$bak" ]] && bak="${dst}.bak.$(date +%Y%m%d-%H%M%S)"
        warn "backing up  $dst → $bak"
        mv "$dst" "$bak"
    fi
    [[ -L "$dst" ]] && rm "$dst"
    mkdir -p "$(dirname "$dst")"
    ln -sf "$src" "$dst"
    info "linked  $src  →  $dst"
}

# ── Step 2: Config symlinks ───────────────────────────────────────────────────
step "2/6  Symlinking $HOME/.config dirs"
link "$DOTFILES/.config/hypr"       "$HOME/.config/hypr"
link "$DOTFILES/.config/waybar"     "$HOME/.config/waybar"
if $INSTALL_KITTY; then
    link "$DOTFILES/.config/kitty" "$HOME/.config/kitty"
    link "$DOTFILES/.config/yazi"  "$HOME/.config/yazi"
fi
link "$DOTFILES/.config/swaync"     "$HOME/.config/swaync"
link "$DOTFILES/.config/rofi"       "$HOME/.config/rofi"
link "$DOTFILES/.config/fastfetch"  "$HOME/.config/fastfetch"
link "$DOTFILES/.config/wlogout"    "$HOME/.config/wlogout"
link "$DOTFILES/.config/btop"       "$HOME/.config/btop"
if $INSTALL_NVIM;  then link "$DOTFILES/.config/nvim"  "$HOME/.config/nvim";  fi

# ── Step 3: Zsh + Oh My Zsh ──────────────────────────────────────────────────
if $INSTALL_ZSH; then
    step "3/6  Setting up Zsh"

    # Powerlevel10k is not in the official repos: clone it from the author's repository.
    P10K_DIR="$HOME/.local/share/powerlevel10k"
    if [[ ! -d "$P10K_DIR" ]]; then
        info "Cloning Powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
    else
        info "Powerlevel10k already present"
    fi

    # .zshrc loads the plugins straight from /usr/share/zsh/plugins and does not use
    # Oh My Zsh, so Oh My Zsh is not installed. link() backs up an existing .zshrc to .zshrc.bak.
    link "$DOTFILES/.zshrc" "$HOME/.zshrc"

    # Change default shell to zsh if not already set
    zsh_path="$(command -v zsh || true)"
    if [[ -z "$zsh_path" ]]; then
        warn "zsh is not installed, leaving your login shell unchanged."
    elif [[ "$SHELL" != "$zsh_path" ]]; then
        chsh -s "$zsh_path"
        info "Default shell changed to zsh (takes effect on next login)"
    else
        info "Default shell already zsh"
    fi

    echo
    warn "First zsh launch will run 'p10k configure' to set up the prompt."

else
    info "Skipping Zsh setup."
fi

# ── Step 4: Local bin scripts ─────────────────────────────────────────────────
step "4/6  Symlinking $HOME/.local/bin scripts"

mkdir -p "$HOME/.local/bin"
for script in "$DOTFILES/.local/bin/"*; do
    [[ -f "$script" ]] || continue
    chmod +x "$script"
    link "$script" "$HOME/.local/bin/$(basename "$script")"
done

# ── Step 5: Assets ────────────────────────────────────────────────────────────
step "5/6  Copying assets to $HOME/.config/assets"
if [[ ! -d "$HOME/.config/assets" ]]; then
    echo "  Copying assets (backgrounds, wlogout icons)..."
    cp -r "$DOTFILES/assets" "$HOME/.config/assets"
    info "assets copied → $HOME/.config/assets"
else
    echo "  Syncing new files into $HOME/.config/assets (existing files untouched)..."
    cp -rn "$DOTFILES/assets/." "$HOME/.config/assets/"
    info "assets synced"
fi
echo
echo "  Icon theme and GTK theme (optional, AUR only) — read each PKGBUILD before building:"
echo "    tela-circle-icon-theme-dracula-git"
echo "    catppuccin-gtk-theme-mocha"

# ── Step 6: Initialize theme ──────────────────────────────────────────────────
step "6/6  Initializing macchiato theme"
echo "  Running theme-switch.sh macchiato (safe outside Hyprland, it only reloads what is running)..."
if bash "$DOTFILES/.config/waybar/scripts/theme-switch.sh" macchiato; then
    info "theme initialized"
else
    warn "theme-switch.sh failed; run it by hand to see why: bash $DOTFILES/.config/waybar/scripts/theme-switch.sh macchiato"
fi

echo
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Done! Log out and back in, then:  uwsm start hyprland${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
