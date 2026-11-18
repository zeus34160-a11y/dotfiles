#!/bin/sh
# install.sh - reproduce this Void Linux (musl) desktop setup.
#
# Repository layout:
#   install.sh
#   Wallpapers/
#   config/                  (optional; configuration directories are copied when present)
#
# Run as your normal user, NOT root. sudo is used where needed.
# Package list based on manually installed packages from xbps-query -m.
# XBPS resolves each package's dependencies automatically.
# Packages unavailable in the target system's repositories are reported and skipped.

set -u

DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
FAILED_FILE="$HOME/install-failed-packages.txt"

if [ "$(id -u)" -eq 0 ]; then
    echo "Run this as your normal user, not root."
    exit 1
fi

command -v xbps-install >/dev/null 2>&1 || {
    echo "This script needs XBPS (Void Linux)."
    exit 1
}
command -v sudo >/dev/null 2>&1 || {
    echo "sudo is required. Install/configure sudo, then run this script again."
    exit 1
}

# Void repository setup -------------------------------------------------
: > "$FAILED_FILE"
# This machine is x86_64 musl. Void's official nonfree subrepository is
# useful for packages in the supplied package snapshot. Multilib is NOT
# enabled: Void only provides it for x86_64 glibc, not musl.
echo "==> Updating the official Void main repository"
sudo xbps-install -S || {
    echo "Repository synchronization failed. Check your Void mirror/network."
    exit 1
}

echo "==> Enabling the official Void nonfree repository"
sudo xbps-install -y void-repo-nonfree || {
    echo "Could not install void-repo-nonfree; continuing with main repository only."
    echo "void-repo-nonfree" >> "$FAILED_FILE"
}
sudo xbps-install -S || {
    echo "Repository synchronization failed. Fix repository configuration before continuing."
    exit 1
}

# Explicit bootstrap/build/runtime requirements. These are installed before
# the full snapshot list so the later download/build steps have their tools.
echo "==> Installing bootstrap and driftwm build dependencies"
BOOTSTRAP_PKGS="sudo ca-certificates curl git tar xz flatpak fontconfig gcc make pkg-config rust cargo libseat-devel libdisplay-info-devel libinput-devel eudev-libudev-devel libgbm-devel libxkbcommon-devel wayland-devel libdrm-devel"
for p in $BOOTSTRAP_PKGS; do
    if ! sudo xbps-install -y "$p"; then
        echo "$p" >> "$FAILED_FILE"
    fi
done

# Package names from manually installed packages (xbps-query -m).
# Versions are deliberately omitted so XBPS installs repository versions.

# Intel and AMD graphics support
PKGS='
    MesaLib-devel Waybar alsa-lib-devel alsa-tools alsa-utils
    base-devel bluetui bluez brightnessctl broot btop cargo
    cava clang cmake cmatrix curl dbus dolphin dunst elogind
    fastfetch feh figlet fish-shell flatpak font-sarasa-gothic
    foot fuzzel gcc git github-cli go gtkmm-devel json-c++
    kdenlive libcurl-devel libdisplay-info-devel libdrm-devel
    libgbm-devel libglvnd-devel libinput-devel libliftoff-devel
    librewolf libseat-devel libsecret-devel libva-devel
    libxcb-devel libxkbcommon-devel make meson mpv nano nasm
    ncurses-devel ninja nodejs openssl-devel patchelf pcre2-devel
    perl pipewire pipewire-devel pixman-devel psmisc
    pulseaudio-utils python python3-pip python3-pipx scrot
    seatd slurp sound-theme-freedesktop spdlog sqlite-devel
    sway wayland-devel wayland-protocols wf-recorder
    wireplumber wl-clipboard wlroots xcb-util-wm-devel
    xdg-desktop-portal xdg-desktop-portal-gtk yazi yt-dlp
    linux-firmware-intel linux-firmware-amd
    mesa-dri vulkan-loader
    mesa-vulkan-intel mesa-vulkan-radeon
    mesa-vaapi intel-video-accel

'

# Install in batches. If a batch fails, retry its packages individually so
# one unavailable package does not prevent the rest from installing.
set -- $PKGS
while [ "$#" -gt 0 ]; do
    BATCH=""
    COUNT=0
    while [ "$#" -gt 0 ] && [ "$COUNT" -lt 30 ]; do
        BATCH="$BATCH $1"
        shift
        COUNT=$((COUNT + 1))
    done

    # Word splitting is intentional: BATCH contains package names only.
    # shellcheck disable=SC2086
    if ! sudo xbps-install -y $BATCH; then
        echo "==> Batch failed; retrying packages individually"
        for p in $BATCH; do
            if ! sudo xbps-install -y "$p"; then
                echo "$p" >> "$FAILED_FILE"
            fi
        done
    fi
done

# ---------------------------------------------------------------
echo "==> seatd service and group"
if [ -d /etc/sv/seatd ] && [ ! -e /var/service/seatd ]; then
    sudo ln -s /etc/sv/seatd /var/service/
fi
if getent group _seatd >/dev/null 2>&1; then
    sudo usermod -aG _seatd "$USER"
else
    echo "   _seatd group not found; skipping group change"
fi


# ---------------------------------------------------------------
echo "==> Installing Flatpak applications"
if command -v flatpak >/dev/null 2>&1; then
    if flatpak remote-add --user --if-not-exists flathub \
        https://dl.flathub.org/repo/flathub.flatpakrepo; then

        for app in dev.vencord.Vesktop org.vinegarhq.Sober; do
            if ! flatpak install --user -y flathub "$app"; then
                echo "$app" >> "$FAILED_FILE"
            fi
        done
    else
        echo "flathub-remote" >> "$FAILED_FILE"
    fi
else
    echo "   Flatpak is not installed; skipping Flatpak applications"
fi

# ---------------------------------------------------------------
echo "==> JetBrainsMono Nerd Font"
FONTDIR="$HOME/.local/share/fonts/JetBrainsMonoNerd"
if command -v curl >/dev/null 2>&1 && command -v tar >/dev/null 2>&1; then
    if [ ! -d "$FONTDIR" ]; then
        mkdir -p "$FONTDIR"
        curl -fL -o /tmp/JetBrainsMono.tar.xz \
            https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz \
            && tar -xf /tmp/JetBrainsMono.tar.xz -C "$FONTDIR" \
            || echo "JetBrainsMonoNerd-font" >> "$FAILED_FILE"
        command -v fc-cache >/dev/null 2>&1 && fc-cache -f
    fi
else
    echo "   curl or tar missing; skipping font download"
fi



# ---------------------------------------------------------------
echo "==> Building driftwm"

if command -v git >/dev/null 2>&1 && command -v curl >/dev/null 2>&1; then
    if [ -d "$HOME/driftwm/.git" ]; then
        git -C "$HOME/driftwm" pull || echo "driftwm-pull" >> "$FAILED_FILE"
    elif [ ! -e "$HOME/driftwm" ]; then
        git clone https://github.com/malbiruk/driftwm "$HOME/driftwm" || \
            echo "driftwm-clone" >> "$FAILED_FILE"
    else
        echo "   $HOME/driftwm exists but is not a Git repository; skipping"
        echo "driftwm-directory" >> "$FAILED_FILE"
    fi

    if [ -d "$HOME/driftwm/.git" ]; then
        RUST_VERSION="$(rustc --version 2>/dev/null | awk '{print $2}' | cut -d. -f1,2)"
        RUST_MAJOR="$(printf '%s' "$RUST_VERSION" | cut -d. -f1)"
        RUST_MINOR="$(printf '%s' "$RUST_VERSION" | cut -d. -f2)"

        if [ -z "$RUST_MAJOR" ] || [ "$RUST_MAJOR" -lt 1 ] || {
            [ "$RUST_MAJOR" -eq 1 ] && [ "${RUST_MINOR:-0}" -lt 88 ]
        }; then
            echo "   Installing current stable Rust with rustup."

            if curl -fL https://sh.rustup.rs -o /tmp/rustup-init.sh &&
                sh /tmp/rustup-init.sh -y --profile minimal --default-toolchain stable; then
                rm -f /tmp/rustup-init.sh
                [ ! -f "$HOME/.cargo/env" ] || . "$HOME/.cargo/env"
                PATH="$HOME/.cargo/bin:$PATH"
                export PATH
            else
                rm -f /tmp/rustup-init.sh
                echo "rustup-install" >> "$FAILED_FILE"
            fi
        fi

        if command -v cargo >/dev/null 2>&1 && rustc --version >/dev/null 2>&1; then
            (
                cd "$HOME/driftwm" &&
                cargo build --locked --release
            ) && sudo install -Dm755 \
                "$HOME/driftwm/target/release/driftwm" \
                /usr/local/bin/driftwm \
                || echo "driftwm-build" >> "$FAILED_FILE"
        else
            echo "driftwm-rust-toolchain" >> "$FAILED_FILE"
        fi
    fi
else
    echo "   git or curl missing; skipping driftwm build"
    echo "driftwm-dependencies" >> "$FAILED_FILE"
fi
# ---------------------------------------------------------------
echo "==> Copying Wallpapers to ~/Wallpapers"
if [ -d "$DIR/Wallpapers" ]; then
    mkdir -p "$HOME/Wallpapers"
    cp -r "$DIR/Wallpapers/." "$HOME/Wallpapers/"
else
    echo "   no Wallpapers folder found next to install.sh (skipped)"
fi

# ---------------------------------------------------------------
echo "==> Copying configuration directories"

copy_config_dir() {
    src="$1"
    dest="$2"

    if [ ! -d "$src" ]; then
        echo "   missing: $src (skipped)"
        return 0
    fi

    if ! mkdir -p "$(dirname -- "$dest")"; then
        echo "   Could not create parent directory for $dest"
        return 1
    fi

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        backup="${dest}.bak.$(date +%Y%m%d-%H%M%S)-$$"
        if ! mv "$dest" "$backup"; then
            echo "   Could not back up $dest"
            return 1
        fi
        echo "   backup created: $backup"
    fi

    if ! mkdir -p "$dest" || ! cp -a "$src/." "$dest/"; then
        echo "   Failed to copy configuration: $dest"
        return 1
    fi

    echo "   installed: $dest"
}

if [ -d "$DIR/config" ]; then
    for src in "$DIR"/config/*; do
        [ -d "$src" ] || continue
        name="${src##*/}"
        copy_config_dir "$src" "$HOME/.config/$name" || echo "config-copy-$name" >> "$FAILED_FILE"
    done
fi

[ ! -f "$HOME/.config/dunst/sound.sh" ] || chmod +x "$HOME/.config/dunst/sound.sh"

# File-picker portal preference (useful for Flatpak app upload dialogs).
mkdir -p "$HOME/.config/xdg-desktop-portal"
printf '[preferred]\ndefault=gtk\n' > "$HOME/.config/xdg-desktop-portal/portals.conf"

echo
if [ -s "$FAILED_FILE" ]; then
    echo "Finished with some packages or steps failing."
    echo "Failed items are listed in: $FAILED_FILE"
    sort -u "$FAILED_FILE" -o "$FAILED_FILE"
    cat "$FAILED_FILE"
else
    rm -f "$FAILED_FILE"
    echo "Done. All requested packages and steps completed."
fi

echo
echo "Log out and back in so group and portal changes take effect."
echo "Your Wallpapers folder was copied to: $HOME/Wallpapers"
echo "Start driftwm from a TTY with: driftwm"
