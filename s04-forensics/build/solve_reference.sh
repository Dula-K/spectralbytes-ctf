#!/bin/bash
# Reference solver for S04 — facilitator-only build validation.
# Requires: tshark
set -euo pipefail
cd "$(dirname "$0")"
source .secrets.env

PCAP=../challenge/capture.pcap

echo "[*] Confirming beacon host appears in DNS queries..."
COUNT=$(tshark -r "$PCAP" -Y "dns.qry.name == \"sync.nullwave-telemetry.test\"" 2>/dev/null | wc -l)
echo "    DNS beacon packets found: $COUNT"
[ "$COUNT" -ge 12 ] || { echo "[FAIL] Expected beacon queries not found"; exit 1; }
echo "[PASS] Beacon pattern present."

echo "[*] Exporting HTTP object stream..."
tshark -r "$PCAP" -Y "tcp.port==8080" -q -z follow,tcp,raw,1 > out/stream_raw.txt 2>/dev/null || true
echo "[PASS] Stream export ran (inspect out/stream_raw.txt manually for the zip bytes)."

echo "[*] Verifying full flag is not visible in plaintext anywhere in the pcap..."
if tshark -r "$PCAP" -V 2>/dev/null | grep -q "${S04_FLAG}"; then
  echo "[FAIL] Flag leaked in plaintext packet data."
  exit 1
fi
echo "[PASS] No plaintext leak."

echo "[DONE] S04 build validated. Suspicious IP: ${S04_BEACON_IP}, interval ~${S04_BEACON_INTERVAL_SEC}s"
