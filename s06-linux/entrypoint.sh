#!/bin/bash
set -e
mkdir -p /var/run/sshd
# /tmp is tmpfs, set in docker-compose.yml — nothing else here is host-mounted
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/spectral.conf
