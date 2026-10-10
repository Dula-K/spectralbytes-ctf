FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        openssh-server supervisor python3 sudo openssl acl \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/run/sshd

# telemetry group is the one whose write access to formatter.py is the bug
RUN groupadd telemetry \
    && useradd -m -s /bin/bash -G telemetry s06player \
    && echo "s06player:$(openssl rand -hex 6)" > /etc/first_login_password.txt \
    && chpasswd < <(echo "s06player:$(cat /etc/first_login_password.txt | cut -d: -f2)")

RUN sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's/^#\?PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config \
    && sed -i 's/^#\?X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config \
    && sed -i 's/^#\?AllowTcpForwarding.*/AllowTcpForwarding no/' /etc/ssh/sshd_config \
    && sed -i 's/^#\?AllowAgentForwarding.*/AllowAgentForwarding no/' /etc/ssh/sshd_config

RUN mkdir -p /opt/spectral/lib
COPY app/collector.py /opt/spectral/collector.py
COPY app/formatter.py /opt/spectral/lib/formatter.py

# root-owned, telemetry group can't touch it
RUN chown root:root /opt/spectral/collector.py && chmod 744 /opt/spectral/collector.py

# this one's group-writable by telemetry and gets imported by the root process
RUN chown root:telemetry /opt/spectral/lib/formatter.py && chmod 664 /opt/spectral/lib/formatter.py
RUN chown root:telemetry /opt/spectral/lib && chmod 775 /opt/spectral/lib

# baking the flag straight into a RUN command would leave it sitting in an
# image layer for anyone with the image, so this uses a BuildKit secret mount
# instead — see the README for the build command
RUN --mount=type=secret,id=s06_flag \
    FLAG="$(cat /run/secrets/s06_flag 2>/dev/null || echo SB{S06_root_devbuild0})" \
    && echo "$FLAG" > /root/final.flag \
    && chown root:root /root/final.flag && chmod 600 /root/final.flag

# supervisord runs collector.py as root on a loop
COPY supervisord.conf /etc/supervisor/conf.d/spectral.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22
ENTRYPOINT ["/entrypoint.sh"]
