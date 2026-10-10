FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        openssh-server steghide exiftool file binutils sudo openssl \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/run/sshd

# challenge account for players
RUN useradd -m -s /bin/bash s02player \
    && echo "s02player:$(openssl rand -hex 6)" > /etc/first_login_password.txt \
    && chpasswd < <(echo "s02player:$(cat /etc/first_login_password.txt | cut -d: -f2)")

# Harden sshd: no root login, no empty passwords, password auth only (lab use)
RUN sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's/^#\?PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config \
    && sed -i 's/^#\?X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config \
    && sed -i 's/^#\?AllowTcpForwarding.*/AllowTcpForwarding no/' /etc/ssh/sshd_config

COPY challenge/ /home/s02player/challenge/
RUN chown -R s02player:s02player /home/s02player

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
