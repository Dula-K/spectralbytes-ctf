# My stages — S02, S04, S06

This is the working build for the three stages I'm responsible for
(H. D. Kaveendra, IT24102456, per section 12.1). It follows the spec in
sections 6.2, 6.4 and 6.6 of the report. I built and tested it so the test
runs double as evidence for the contribution matrix instead of just a commit
log.

```
spectralbytes/
├── docker-compose.my-stages.yml   merge into the main compose file
├── s02-steganography/
│   ├── Dockerfile
│   ├── challenge/                 what the player actually sees
│   └── build/
│       ├── generate_challenge.sh  makes badge.jpg, not shipped to players
│       └── solve_reference.sh     checks the build worked
├── s04-forensics/
│   ├── Dockerfile
│   ├── challenge/
│   └── build/
│       ├── generate_pcap.py       makes capture.pcap
│       └── solve_reference.sh
└── s06-linux/
    ├── Dockerfile
    ├── app/                       collector.py, formatter.py, player README
    ├── supervisord.conf
    ├── entrypoint.sh
    └── build/
        └── validate_reference.sh  run this one inside the container
```

## Building it

S02 needs the S01 codename and room number, and S04's archive uses the S03
passphrase — that's how the narrative chains together. Those stages aren't
built yet, so for now I'm passing placeholder values through env vars until
the others finish theirs.

```bash
cd s02-steganography/build
pip install pillow
sudo apt-get install -y steghide exiftool openssl
S01_CODENAME=nightglass S01_ROOM=7b ./generate_challenge.sh

cd ../../s04-forensics/build
pip install scapy
S03_PASSPHRASE=ctr_reuse_breaks_everything python3 generate_pcap.py

cd ../../s06-linux
echo "SB{S06_root_$(openssl rand -hex 4)}" > /tmp/s06_flag.txt
DOCKER_BUILDKIT=1 docker build --secret id=s06_flag,src=/tmp/s06_flag.txt -t spectralbytes-s06 .
rm /tmp/s06_flag.txt
```

Swap the placeholder env vars for the real S01/S03 output once those exist.

## Running and testing

```bash
docker compose -f docker-compose.my-stages.yml up -d --build
ssh s02player@localhost -p 2222
ssh s04player@localhost -p 2224
ssh s06player@localhost -p 2226
```

S02's `solve_reference.sh` checks that the right passphrase extracts the
flag, the wrong one fails, and the flag isn't sitting in the metadata where
someone could just read it. S04's does roughly the same thing for the
PCAP — confirms the beacon pattern is there and the flag never shows up in
plaintext packet bytes. For S06 I run the validator from inside the
container as `s06player`, since the whole point is proving the player-level
path actually works without ever touching root directly:

```bash
docker exec -u s06player -it spectralbytes-s06 bash
./build/validate_reference.sh
```

## Checking isolation

```bash
nmap -p- localhost -p 2222,2224,2226

docker inspect spectralbytes-s02 spectralbytes-s04 spectralbytes-s06 \
  --format '{{.Name}}: Privileged={{.HostConfig.Privileged}} Binds={{.HostConfig.Binds}}'
```

Only the three SSH ports should answer, and none of the three should show
privileged mode or host mounts.

## Resetting

```bash
docker compose -f docker-compose.my-stages.yml up -d --force-recreate s02-steganography s04-forensics s06-linux
```

S06's `/tmp` is a tmpfs, so whatever a player copies there disappears on
recreate automatically. `formatter.py` lives in the image layer, so
recreating the container also wipes out any edits a player made to it.

## Evidence to keep

- Build/up logs
- The PASS output from each validator
- An nmap scan showing just the three intended ports
- `docker inspect` output with no privileged flags or host mounts
- A full walkthrough of solving each of the three stages

## Still need to sort out

- S02 and S04 are built against placeholder S01/S03 values right now —
  needs the real ones once those stages exist.
- S06's flag only avoids leaking into the image layer if whoever builds it
  remembers `DOCKER_BUILDKIT=1`. If that gets forgotten the build falls
  back to a dev flag (`SB{S06_root_devbuild0}`), which obviously can't ship.
  Worth double-checking before the real build.
- S02's image installs `sudo` and `binutils`, neither of which it actually
  needs at runtime. Not urgent, but worth trimming if we want a tighter
  image for the writeup.
- Haven't run this alongside everyone else's stages and the CTFd container
  yet — need a full `docker compose up` with all six before Week 5.
