#!/usr/bin/env python3
"""
Runs as root every ~20s via supervisord (see supervisord.conf) and pulls in
its formatting helper from /opt/spectral/lib. That directory is writable by
the telemetry group, which is the whole point of this box — whoever's in
that group can change what root runs next.

The scoped solve here is: edit formatter.py so the next root run copies
/root/final.flag to /tmp/final.flag, mode 0644, and stop there.
"""
import sys

sys.path.insert(0, "/opt/spectral/lib")

import formatter  # noqa: E402  (intentionally late import — this is the trust boundary)


def collect():
    reading = {"sensor": "gateway-03", "status": "nominal"}
    formatted = formatter.format_reading(reading)
    print(formatted)


if __name__ == "__main__":
    collect()
