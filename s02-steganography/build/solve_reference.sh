#!/bin/bash
# Reference solver for S02 — used only by the facilitator to validate a build.
# Confirms: correct passphrase extracts the flag, wrong passphrase fails.
set -euo pipefail
cd "$(dirname "$0")"
source .secrets.env

echo "[*] Testing extraction with CORRECT passphrase..."
steghide extract -sf out/badge.jpg -p "${S02_PASSPHRASE}" -xf out/recovered.txt -f
grep -q "${S02_FLAG}" out/recovered.txt && echo "[PASS] Correct passphrase recovers the flag."

echo "[*] Testing extraction with WRONG passphrase (expect failure)..."
if steghide extract -sf out/badge.jpg -p "wrong_password" -xf out/should_fail.txt -f 2>/dev/null; then
  echo "[FAIL] Wrong passphrase unexpectedly succeeded."
  exit 1
else
  echo "[PASS] Wrong passphrase correctly rejected."
fi

echo "[*] Checking the full flag is not present anywhere in visible metadata..."
if exiftool out/badge.jpg | grep -q "${S02_FLAG}"; then
  echo "[FAIL] Flag leaked in metadata."
  exit 1
else
  echo "[PASS] No flag leak in metadata."
fi

rm -f out/recovered.txt out/should_fail.txt
echo "[DONE] S02 build validated."
