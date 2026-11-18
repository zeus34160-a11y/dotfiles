#!/bin/sh
# install.sh - reproduce this Void Linux (musl) desktop setup.
#
# Repository layout:
#   install.sh
#   Wallpapers/
#   config/                  (optional; individual files are skipped if absent)
#
# Run as your normal user, NOT root. sudo is used where needed.
# This package list was generated from an xbps-query -l snapshot.
# It includes applications, libraries, development packages, and dependencies.
# Packages unavailable in the target system's repositories are reported and skipped.

set -u

DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
FAILED=""
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
sudo xbps-install -Syu || {
    echo "System update failed. Check your Void mirror/network first."
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

# All 991 package names from the supplied xbps-query -l output.
# Versions are deliberately omitted so XBPS installs repository versions.
PKGS='
    AppStream KDSoap LuaJIT MesaLib-devel OpenTimelineIO SDL2
    SDL3 SPIRV-LLVM-Translator22 Waybar accounts-qml-module acl acpid
    ada adwaita-icon-theme alacritty-terminfo alsa-firmware alsa-lib alsa-lib-devel
    alsa-tools alsa-ucm-conf alsa-utils at-spi2-atk at-spi2-atk-devel at-spi2-core
    at-spi2-core-devel atk atk-devel atkmm atkmm-devel attr
    autoconf automake avahi-libs avahi-libs-devel baloo-widgets base-devel
    base-files base-system bash bc binutils binutils-doc
    binutils-libs bison bluetui bluez botan breeze-icons
    brightnessctl broot brotli brotli-devel btop btrfs-progs
    bubblewrap bzip2 bzip2-devel c-ares ca-certificates cairo
    cairo-devel cairomm cairomm-devel cargo cava celt
    chromaprint clang clang21 clang21-headers clang22-headers cmake
    cmatrix colord-devel compiler-rt21 confuse coreutils cpio
    cppdap cups-devel curl dash dbus dbus-devel
    dbus-libs dbus-x11 dconf dejavu-fonts-ttf desktop-file-utils device-mapper
    dhcpcd diffutils dnssec-anchors docbook-xml docbook-xsl dolphin
    dosfstools double-conversion dracut duktape dunst dvdauthor
    e2fsprogs e2fsprogs-libs ed efibootmgr elfutils-devel elogind
    elogind-devel encodings ethtool eudev eudev-libudev eudev-libudev-devel
    exiv2 expat expat-devel f2fs-tools faac faad2
    fastfetch fcft fdk-aac feh ffmpeg ffmpeg6
    ffplay6 figlet file findutils fish-shell flatpak
    flex flite fltk fmt fmt-devel font-adobe-100dpi
    font-adobe-75dpi font-adobe-utopia-100dpi font-adobe-utopia-75dpi font-adobe-utopia-type1 font-alias font-bh-100dpi
    font-bh-75dpi font-bh-lucidatypewriter-100dpi font-bh-lucidatypewriter-75dpi font-bh-ttf font-bh-type1 font-bitstream-100dpi
    font-bitstream-75dpi font-bitstream-type1 font-cursor-misc font-daewoo-misc font-dec-misc font-ibm-type1
    font-isas-misc font-jis-misc font-misc-misc font-mutt-misc font-sarasa-gothic font-util
    fontconfig fontconfig-devel foot foot-terminfo freetype freetype-devel
    frei0r-plugins fribidi fribidi-devel fuse fuse3 fuzzel
    gawk gcc gdbm gdk-pixbuf gdk-pixbuf-devel gettext
    gettext-libs gi-docgen giflib gir-freedesktop git glib
    glibmm glibmm-devel glslang gmp gmp-devel gnome-desktop
    gnupg gnutls gnutls-devel go gpgmepp graphene
    graphite graphite-devel grep groff grub grub-x86_64-efi
    gsettings-desktop-schemas gst-plugins-bad1 gst-plugins-base1 gstreamer1 gtk+ gtk+3
    gtk+3-devel gtk-layer-shell gtk-update-icon-cache gtk4 gtkmm gtkmm-devel
    gzip harfbuzz-devel hicolor-icon-theme highway hwids iana-etc
    iceauth icu-devel imath imlib2 inih iniparser
    iproute2 iptables iputils ipw2100-firmware ipw2200-firmware iso-codes
    iw jansson jbigkit-devel jbigkit-libs json-c json-c++
    json-glib json-glib-devel jsoncpp kbd kddockwidgets kde-plasma-base
    kdenlive kdsoap-ws-discovery-client kernel-libc-headers kf6-attica kf6-baloo kf6-base
    kf6-kaccounts-integration kf6-karchive kf6-kbookmarks kf6-kcmutils kf6-kcodecs kf6-kcolorscheme
    kf6-kcompletion kf6-kconfig kf6-kconfigwidgets kf6-kcoreaddons kf6-kcrash kf6-kdbusaddons
    kf6-kdeclarative kf6-kdnssd kf6-kdoctools kf6-kfilemetadata kf6-kglobalaccel kf6-kguiaddons
    kf6-kguiaddons-geo-uri-handler kf6-ki18n kf6-kiconthemes kf6-kidletime kf6-kio kf6-kirigami
    kf6-kitemmodels kf6-kitemviews kf6-kjobwidgets kf6-knewstuff kf6-knotifications kf6-knotifyconfig
    kf6-kpackage kf6-kparts kf6-kservice kf6-ktextwidgets kf6-kuserfeedback kf6-kwallet
    kf6-kwidgetsaddons kf6-kwindowsystem kf6-kxmlgui kf6-prison kf6-purpose kf6-qqc2-desktop-style
    kf6-solid kf6-sonnet kf6-syndication kf6-syntax-highlighting kio-extras kmod
    kpartx ladspa-sdk-example-plugins lame lcms2 lcms2-devel ldb
    less libICE libSM libX11 libX11-devel libXScrnSaver
    libXau libXau-devel libXaw libXcomposite libXcomposite-devel libXcursor
    libXcursor-devel libXdamage libXdamage-devel libXdmcp libXdmcp-devel libXext
    libXext-devel libXfixes libXfixes-devel libXfont2 libXft libXft-devel
    libXi libXi-devel libXinerama libXinerama-devel libXmu libXpm
    libXpresent libXrandr libXrandr-devel libXrender libXrender-devel libXt
    libXtst libXtst-devel libXv libXxf86vm libaccounts-glib libaccounts-qt6
    libaio libao libaom libarchive libaspell libass
    libassuan libasyncns libatasmart libatomic libatomic-devel libavcodec6
    libavdevice6 libavfilter6 libavformat6 libavutil6 libb2 libblkid
    libblkid-devel libblockdev libbluray libbpf libbreeze-icons libbs2b
    libbytesize libcamera libcanberra libcap libcap-ng libcap-progs
    libcddb libcdio libcdio-paranoia libcdparanoia libclang-cpp21 libclang-cpp22
    libclang21 libcloudproviders libcolord libcrypto3 libcryptsetup libcups
    libcurl libcurl-devel libdatrie libdatrie-devel libdav1d libdaxctl
    libdb libdbusmenu-glib libdbusmenu-gtk3 libdca libde265 libdebuginfod
    libdecor libdeflate libdisplay-info libdisplay-info-devel libdmtx libdrm
    libdrm-devel libdvdcss libdvdnav libdvdread libebur128 libedit
    libefivar libei libelf libelogind libepoxy libepoxy-devel
    libev libevdev libevent libevent-devel libexecinfo libexecinfo-devel
    libexif libfdisk libffi libffi-devel libfftw libfl-devel
    libflac libfluidsynth libfontenc libfyaml libgbm libgbm-devel
    libgcc libgcc-devel libgcrypt libgcrypt-devel libgit2-1.9 libglib-devel
    libglvnd libglvnd-devel libgme libgomp libgpg-error libgpg-error-devel
    libgpgme libgs libgsm libgudev libgudev-devel libgusb
    libgusb-devel libharfbuzz libheif libhunspell1.7 libicu78 libicu78-devel
    libid3tag libidn2 libidn2-devel libimobiledevice libinput libinput-devel
    libjack libjbig2dec libjpeg-turbo libjpeg-turbo-devel libjpeg-turbo-tools libjxl
    libkexiv2 libkeyutils libkmod libksba liblastlog2 libldap
    libldns libliftoff libliftoff-devel liblilv libllvm21 libllvm22
    libllvm23 liblrdf libltdl liblz4 liblzma liblzma-devel
    libmad libmagic libmcpp libmd4c libmediainfo libmms
    libmnl libmodplug libmount libmount-devel libmpdclient libmpg123
    libmtp libmysofa libndctl libnetfilter_conntrack libnfnetlink libnftnl
    libnl3 libnotify libnvme libogg libopenal libopencv
    libopenexr libopenjpeg2 libopenmpt libpaper libparted libpcap
    libpciaccess libpciaccess-devel libpcre2 libpipewire libplacebo libplist
    libpng libpng-devel libpoppler libpostproc6 libproxy libpsl
    libpsl-devel libpulseaudio libpyldb-util libpyside6 libpytalloc-util libqmobipocket6
    libqrencode libqt6shadertools libraptor libreadline8 libresvg0 librewolf
    librist librsvg librtmp librubberband libsamplerate libsasl
    libseat libseat-devel libseccomp libsecret libsecret-devel libsensors
    libserd libsharpyuv libsharpyuv-devel libshiboken6 libsigc++ libsigc++-devel
    libsmartcols libsndfile libsndio libsodium libsord libsoxr
    libspa-alsa libspa-audioconvert libspa-audiomixer libspa-control libspa-v4l2 libspa-videoconvert
    libspdlog libspectre libspeex libsrt libsrtp libssh
    libssh2 libssh2-devel libssl3 libstdc++ libstdc++-devel libsvt-av1
    libswresample6 libswscale6 libtasn1 libtasn1-devel libtdb libthai
    libthai-devel libtheora libtinysparql libtirpc libtool libunbound
    libunistring libunistring-devel libupower-glib3 liburcu libusb libusb-devel
    libusbmuxd libutempter libutf8proc libuuid libuuid-devel libuv
    libva libva-devel libvala libvamp-plugin-sdk libvdpau libvidstab
    libvorbis libvpl libvpx libwacom libwavpack libwebp
    libwebp-devel libxbps libxcb libxcb-devel libxcvt libxkbcommon
    libxkbcommon-devel libxkbcommon-x11 libxkbfile libxkbregistry libxml2 libxml2-devel
    libxmlb libxshmfence libxslt libyaml libz3 libzbar
    libzen libzstd libzstd-devel linux linux-base linux-firmware-amd
    linux-firmware-broadcom linux-firmware-intel linux-firmware-network linux-firmware-nvidia linux6.18 llhttp
    lmdb lua52 lua54 lzo lzo-devel m4
    make man-pages mbedtls mcpp mdocml media-player-info
    mediainfo-cli mesa mesa-dri mesa-libclc mesa-libgallium mesa-opencl
    meson minizip mit-krb5-libs mkfontscale mlt7 mlt7-data
    movit mpfr mpv mtdev mujs musl
    musl-devel musl-fts nano nasm ncurses ncurses-base
    ncurses-devel ncurses-libs nerd-fonts-symbols-ttf nettle nettle-devel nghttp2
    nghttp2-devel nghttp3 nghttp3-devel ngtcp2 ngtcp2-devel ninja
    nodejs npth nspr nss nvi ocl-icd
    oclock oniguruma opencv openh264 openssh openssl
    openssl-devel opus opusfile orc os-prober ostree
    p11-kit p11-kit-devel pam pam-base pam-libs pango
    pango-devel pango-xft pangomm pangomm-devel patch patchelf
    pciutils pcre2-devel perl perl-Authen-SASL perl-Convert-BinHex perl-Crypt-URandom
    perl-Digest-HMAC perl-IO-Socket-SSL perl-IO-stringy perl-MIME-tools perl-MailTools perl-Net-SMTP-SSL
    perl-Net-SSLeay perl-TimeDate perl-URI pinentry pipewire pipewire-devel
    pixman pixman-devel pkg-config plasma-activities plasma-activities-stats playerctl
    polkit poppler-data poppler-qt6 popt portaudio procps-ng
    psmisc public-suffix pulseaudio-utils python python3 python3-Brotli
    python3-Jinja2 python3-Markdown python3-MarkupSafe python3-Pygments python3-alsa python3-argcomplete
    python3-cairo python3-certifi python3-charset-normalizer python3-click python3-filelock python3-gobject
    python3-idna python3-mutagen python3-packaging python3-parsing python3-pip python3-pipx
    python3-platformdirs python3-pycryptodomex python3-requests python3-setuptools python3-smartypants python3-toml
    python3-typogrify python3-urllib3 python3-userpath python3-websockets python3-yt-dlp-ejs qca-qt6
    qt6-concurrent qt6-core qt6-dbus qt6-declarative qt6-gui qt6-multimedia
    qt6-network qt6-networkauth qt6-pdf qt6-plugin-sqlite qt6-plugin-tls-openssl qt6-plugin-tls-qcertonly
    qt6-position qt6-printsupport qt6-qt5compat qt6-quick3d qt6-quicktimeline qt6-serialport
    qt6-speech qt6-sql qt6-svg qt6-wayland-client qt6-webchannel qt6-webengine
    qt6-widgets qt6-xml removed-packages rhash rnnoise run-parts
    runit runit-void rust rust-std samba-libs sbc
    scrot seatd sed sessreg setxkbmap shaderc
    shadow shared-mime-info signon-kwallet-extension signon-plugin-oauth2 signon-ui signond
    slurp smproxy snappy sof-firmware sound-theme-freedesktop soundtouch
    sox spandsp spdlog speexdsp sqlite sqlite-devel
    sratom sudo sway swaybg taglib talloc
    tar tevent texinfo tiff tiff-devel tpm2-tss
    traceroute transset trousers trousers-devel tslib tzdata
    uchardet udisks2 unbound-devel unzip upower usbutils
    util-linux util-linux-common v4l-utils vala vala-devel vmaf
    void-artwork void-repo-nonfree volume_key vulkan-loader wayland wayland-devel
    wayland-protocols webrtc-audio-processing wf-recorder which wifi-firmware wireplumber
    wl-clipboard wlroots wlroots0.20 wpa_supplicant x11perf x264
    x265 xauth xbacklight xbps xbps-triggers xcalc
    xcb-util xcb-util-cursor xcb-util-devel xcb-util-errors xcb-util-image xcb-util-keysyms
    xcb-util-renderutil xcb-util-wm xcb-util-wm-devel xcb-util-xrm xclipboard xclock
    xcmsdb xconsole xcursorgen xdg-dbus-proxy xdg-desktop-portal xdg-desktop-portal-gtk
    xdpyinfo xev xeyes xf86-input-evdev xf86-input-libinput xf86-input-synaptics
    xf86-input-vmmouse xf86-input-wacom xf86-video-amdgpu xf86-video-ati xf86-video-dummy xf86-video-fbdev
    xf86-video-nouveau xf86-video-vesa xfontsel xfsprogs xgamma xhost
    xinput xkbcomp xkbevd xkbutils xkeyboard-config xkill
    xload xlogo xlsatoms xlsclients xmessage xmlcatmgr
    xmodmap xorg-fonts xorg-input-drivers xorg-server xorg-server-common xorg-server-xwayland
    xorg-video-drivers xorgproto xpr xprop xrandr xrdb
    xrefresh xset xsetroot xtrans xvidcore xvinfo
    xwd xwininfo xwud xz yajl yazi
    yt-dlp yyjson zd1211-firmware zix zlib zlib-devel
    zxing-cpp
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
echo "==> Vesktop (Flatpak)"
if command -v flatpak >/dev/null 2>&1; then
    flatpak remote-add --user --if-not-exists flathub \
        https://dl.flathub.org/repo/flathub.flatpakrepo
    flatpak install --user -y flathub dev.vencord.Vesktop || \
        echo "vesktop-flatpak" >> "$FAILED_FILE"
else
    echo "   Flatpak is not installed; skipping Vesktop"
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
if command -v cargo >/dev/null 2>&1 && command -v git >/dev/null 2>&1; then
    if [ -d "$HOME/driftwm/.git" ]; then
        git -C "$HOME/driftwm" pull || echo "driftwm-pull" >> "$FAILED_FILE"
    else
        git clone https://github.com/malbiruk/driftwm "$HOME/driftwm" || \
            echo "driftwm-clone" >> "$FAILED_FILE"
    fi
    if [ -d "$HOME/driftwm" ]; then
        # driftwm requires Rust 1.88+ (edition 2024).
        RUST_VERSION="$(rustc --version 2>/dev/null | awk '{print $2}' | cut -d. -f1,2)"
        RUST_MAJOR="$(printf '%s' "$RUST_VERSION" | cut -d. -f1)"
        RUST_MINOR="$(printf '%s' "$RUST_VERSION" | cut -d. -f2)"
        if [ -z "$RUST_MAJOR" ] || [ "$RUST_MAJOR" -lt 1 ] || { [ "$RUST_MAJOR" -eq 1 ] && [ "${RUST_MINOR:-0}" -lt 88 ]; }; then
            echo "   System Rust is too old; installing the current stable Rust toolchain with rustup."
            if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain stable; then
                # shellcheck disable=SC1090
                [ ! -f "$HOME/.cargo/env" ] || . "$HOME/.cargo/env"
                PATH="$HOME/.cargo/bin:$PATH"
                export PATH
            else
                echo "rustup-install" >> "$FAILED_FILE"
            fi
        fi
        if rustc --version >/dev/null 2>&1; then
            (cd "$HOME/driftwm" && cargo build --locked --release) \
                && sudo install -Dm755 "$HOME/driftwm/target/release/driftwm" /usr/local/bin/driftwm \
                || echo "driftwm-build" >> "$FAILED_FILE"
        else
            echo "driftwm-rust-toolchain" >> "$FAILED_FILE"
        fi
    fi
else
    echo "   cargo or git missing; skipping driftwm build"
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
echo "==> Copying optional config files"
put() {
    if [ ! -f "$1" ]; then
        echo "   missing: $1 (skipped)"
        return
    fi
    mkdir -p "$(dirname -- "$2")"
    [ ! -e "$2" ] || cp "$2" "$2.bak"
    cp "$1" "$2"
}

put "$DIR/config/driftwm/config.toml" "$HOME/.config/driftwm/config.toml"
put "$DIR/config/foot/foot.ini"       "$HOME/.config/foot/foot.ini"
put "$DIR/config/fuzzel/fuzzel.ini"   "$HOME/.config/fuzzel/fuzzel.ini"
put "$DIR/config/dunst/dunstrc"       "$HOME/.config/dunst/dunstrc"
put "$DIR/config/dunst/sound.sh"      "$HOME/.config/dunst/sound.sh"
put "$DIR/config/broot/conf.hjson"    "$HOME/.config/broot/conf.hjson"

if [ -f "$HOME/.config/dunst/dunstrc" ]; then
    sed -i "s|/home/italy|$HOME|g" "$HOME/.config/dunst/dunstrc"
fi
[ ! -f "$HOME/.config/dunst/sound.sh" ] || chmod +x "$HOME/.config/dunst/sound.sh"

# File-picker portal preference (useful for Flatpak app upload dialogs).
mkdir -p "$HOME/.config/xdg-desktop-portal"
printf '[preferred]\\ndefault=gtk\\n' > "$HOME/.config/xdg-desktop-portal/portals.conf"

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
