#!/bin/sh
set -eu
DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
SCRIPT="$DIR/install.sh"

echo "==> Checking repository files"
for item in install.sh README.md Wallpapers config; do
    if [ -e "$DIR/$item" ]; then
        echo "OK: $item"
    else
        echo "MISSING: $item"
        exit 1
    fi
done

echo
echo "==> Checking installer syntax"
sh -n "$SCRIPT"
echo "OK: shell syntax"

echo
echo "==> Checking forbidden packages"
python3 - "$SCRIPT" <<'PYTHON'
import re, sys
from pathlib import Path
text = Path(sys.argv[1]).read_text()
match = re.search(r"PKGS='(.*?)'", text, re.S)
if not match:
    print("ERROR: Could not find PKGS list")
    sys.exit(1)
packages = set(match.group(1).split())
forbidden = {
    "linux", "linux-base", "linux-headers", "linux-firmware",
    "grub", "grub-x86_64-efi", "base-system", "base-files",
    "dracut", "runit"
}
found = sorted(packages & forbidden)
if found:
    print("ERROR: Forbidden packages:", ", ".join(found))
    sys.exit(1)
print("OK: no forbidden packages found")
PYTHON

echo
echo "All checks passed. No system changes were made."
