SpectralBytes — S06: Root of the Signal
==========================================

This is the final box. A supervised root process collects telemetry
periodically. Somewhere in this system is a trust boundary that shouldn't
exist.

You have no host access, no Docker socket, and no privileged container
capabilities. Everything you need is inside this box.

Task:
  1. Enumerate your identity, groups, running processes and the
     permissions on anything under /opt/spectral.
  2. Work out what the root collector imports, and from where.
  3. If you can modify what it imports, make the NEXT scheduled run do
     exactly one thing: copy /root/final.flag to /tmp/final.flag with
     safe (world-readable) permissions. Nothing more.
  4. Wait for the next collection interval, read /tmp/final.flag, submit it.

Rules of engagement for this box:
  - Stay inside the intended action (copy the flag file). Don't attempt to
    gain an interactive root shell, modify other root-owned files, or
    touch anything outside this container — it won't work, and it isn't
    the point of the exercise.

Flag format: SB{S06_root_XXXXXXXX}
