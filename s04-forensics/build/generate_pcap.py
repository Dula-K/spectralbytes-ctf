#!/usr/bin/env python3
"""
Builds the S04 pcap. Needs scapy (`pip install scapy`), run on your own
machine, not in the container.

Writes capture.pcap to challenge/ — background traffic, a periodic DNS
beacon, and one HTTP transfer carrying a zip with the flag. All the IPs are
from the documentation ranges in RFC 5737/3849 since none of this is real
traffic.
"""
import os
import random
import secrets
import zipfile
from pathlib import Path

from scapy.all import wrpcap, Ether, IP, TCP, UDP, DNS, DNSQR, DNSRR, Raw

random.seed(44)  # keeps the packet layout the same between runs

HERE = Path(__file__).parent
OUT_DIR = HERE / "out"
CHALLENGE_DIR = HERE.parent / "challenge"
OUT_DIR.mkdir(exist_ok=True)
CHALLENGE_DIR.mkdir(exist_ok=True)

# comes from S03 once that's built, placeholder for now
S03_PASSPHRASE = os.environ.get("S03_PASSPHRASE", "ctr_reuse_breaks_everything")

FLAG = f"SB{{S04_pcap_{secrets.token_hex(4)}}}"

BENIGN_SRC = "192.0.2.10"
BENIGN_DST = "198.51.100.20"
BEACON_SRC = "203.0.113.77"  # this is the one players should flag
GATEWAY_MAC_A = "02:00:00:00:00:01"
GATEWAY_MAC_B = "02:00:00:00:00:02"

packets = []
t = 0.0

# background noise so the beacon isn't the only thing in the capture
for i in range(40):
    t += random.uniform(0.05, 0.4)
    pkt = (
        Ether(src=GATEWAY_MAC_A, dst=GATEWAY_MAC_B)
        / IP(src=BENIGN_SRC, dst=BENIGN_DST)
        / TCP(sport=random.randint(1024, 65000), dport=443, flags="PA")
        / Raw(load=b"benign telemetry heartbeat " + str(i).encode())
    )
    pkt.time = t
    packets.append(pkt)

# the actual beacon, roughly every 30s with some jitter so it's not a
# dead giveaway in a quick skim
BEACON_DOMAIN = "sync.nullwave-telemetry.test"
beacon_times = []
bt = 5.0
for i in range(12):
    bt += 30 + random.uniform(-2, 2)
    beacon_times.append(bt)

for bt in beacon_times:
    q = (
        Ether(src=GATEWAY_MAC_A, dst=GATEWAY_MAC_B)
        / IP(src=BEACON_SRC, dst="198.51.100.53")
        / UDP(sport=random.randint(1024, 65000), dport=53)
        / DNS(rd=1, qd=DNSQR(qname=BEACON_DOMAIN))
    )
    q.time = bt
    packets.append(q)
    r = (
        Ether(src=GATEWAY_MAC_B, dst=GATEWAY_MAC_A)
        / IP(src="198.51.100.53", dst=BEACON_SRC)
        / UDP(sport=53, dport=q[UDP].sport)
        / DNS(
            id=q[DNS].id, qr=1, qd=q[DNS].qd,
            an=DNSRR(rrname=BEACON_DOMAIN, rdata="198.51.100.90"),
        )
    )
    r.time = bt + 0.02
    packets.append(r)

# the archive that gets pulled over HTTP below
note_path = OUT_DIR / "case_notes.txt"
note_path.write_text(
    "Gateway handoff — restricted distribution\n"
    "------------------------------------------\n"
    f"{FLAG}\n"
    "Next hop: internal incident portal (see attached route memo).\n"
)
zip_path = OUT_DIR / "case_archive.zip"
with zipfile.ZipFile(zip_path, "w") as zf:
    zf.setpassword(None)
    zf.writestr("case_notes.txt", note_path.read_text())
# python's zipfile doesn't do real AES encryption, only ZipCrypto via a
# third-party lib. Leaving it unencrypted for now and relying on the
# narrative passphrase convention — can swap in pyzipper later if we want
# an actual password on the archive.
zip_bytes = zip_path.read_bytes()

# one HTTP transfer, dropped in partway through the beacon sequence
http_time = beacon_times[6] + 1.5
req = (
    Ether(src=GATEWAY_MAC_B, dst=GATEWAY_MAC_A)
    / IP(src=BENIGN_DST, dst=BEACON_SRC)
    / TCP(sport=51234, dport=8080, flags="PA", seq=1000)
    / Raw(load=b"GET /export/case_archive.zip HTTP/1.1\r\nHost: gateway.internal\r\n\r\n")
)
req.time = http_time
packets.append(req)

header = (
    b"HTTP/1.1 200 OK\r\n"
    b"Content-Type: application/zip\r\n"
    f"Content-Length: {len(zip_bytes)}\r\n\r\n".encode()
)
resp = (
    Ether(src=GATEWAY_MAC_A, dst=GATEWAY_MAC_B)
    / IP(src=BEACON_SRC, dst=BENIGN_DST)
    / TCP(sport=8080, dport=51234, flags="PA", seq=2000, ack=1000 + len(req[Raw].load))
    / Raw(load=header + zip_bytes)
)
resp.time = http_time + 0.05
packets.append(resp)

packets.sort(key=lambda p: p.time)
pcap_path = CHALLENGE_DIR / "capture.pcap"
wrpcap(str(pcap_path), packets)

with open(HERE / ".secrets.env", "w") as f:
    f.write(f"S04_FLAG={FLAG}\n")
    f.write(f"S04_BEACON_IP={BEACON_SRC}\n")
    f.write(f"S04_BEACON_INTERVAL_SEC=30\n")

print(f"[S04] wrote {pcap_path}, {len(packets)} packets")
print(f"[S04] flag (keep secret): {FLAG}")
print(f"[S04] suspicious IP: {BEACON_SRC}, beacon interval ~30s")
