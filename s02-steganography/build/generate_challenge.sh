#!/bin/bash
# Makes the S02 badge image. Run this on your own machine, not inside the
# container — needs python3 + Pillow, steghide, exiftool and openssl.
# Drops badge.jpg in challenge/ and the flag/passphrase in .secrets.env
# (keep that one out of Git).

set -euo pipefail
cd "$(dirname "$0")"

mkdir -p out ../challenge

# These should come from S01's actual output once that's built. Using env
# var overrides for now so I can test this stage on its own.
S01_CODENAME="${S01_CODENAME:-nightglass}"
S01_ROOM="${S01_ROOM:-7b}"
PASSPHRASE="${S01_CODENAME}_${S01_ROOM}"

FLAG="SB{S02_steg_$(openssl rand -hex 4)}"

# fake badge photo
python3 - "$PWD/out/badge.jpg" <<'PY'
import sys
from PIL import Image, ImageDraw, ImageFont

out = sys.argv[1]
img = Image.new("RGB", (800, 500), (24, 28, 36))
d = ImageDraw.Draw(img)
d.rectangle([0, 0, 800, 70], fill=(10, 12, 16))
d.text((20, 20), "SPECTRAL DYNAMICS — FACILITIES ACCESS", fill=(230, 230, 230))
d.text((20, 120), "Maintenance Badge Photo", fill=(200, 200, 200))
d.text((20, 150), "Captured during HVAC inspection, Bldg 3", fill=(150, 150, 150))
d.rectangle([550, 150, 760, 400], outline=(90, 160, 220), width=3)
d.text((560, 170), "ACCESS", fill=(90, 160, 220))
d.text((560, 195), "BADGE", fill=(90, 160, 220))
img.save(out, "JPEG", quality=92)
PY

# hide the flag in it
echo "Operator note: ${FLAG}" > out/secret.txt
steghide embed -cf out/badge.jpg -ef out/secret.txt -p "${PASSPHRASE}" -z 1 -f

# comment clue goes in EXIF, not the password itself
exiftool -overwrite_original \
  -Comment="Maintenance capture, auto-uploaded. If this needs extraction, use the usual steg-family tool. Passphrase = codename_room (all lowercase, underscore-joined)." \
  out/badge.jpg

sha256sum out/badge.jpg > out/badge.jpg.sha256
rm -f out/secret.txt

cp out/badge.jpg ../challenge/badge.jpg
cp out/badge.jpg.sha256 ../challenge/badge.jpg.sha256

cat > .secrets.env <<EOF
S02_FLAG=${FLAG}
S02_PASSPHRASE=${PASSPHRASE}
EOF

echo "[S02] Built badge.jpg"
echo "[S02] Flag (keep secret):       ${FLAG}"
echo "[S02] Passphrase (keep secret): ${PASSPHRASE}"
echo "[S02] Secrets written to build/.secrets.env (do not commit)"
