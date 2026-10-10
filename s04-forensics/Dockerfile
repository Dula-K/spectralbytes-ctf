FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        openssh-server tshark wireshark-common file unzip sudo openssl \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/run/sshd \
    && groupadd -f wireshark

RUN useradd -m -s /bin/bash s04player \
    && echo "s04player:$(openssl rand -hex 6)" > /etc/first_login_password.txt \
    && chpasswd < <(echo "s04player:$(cat /etc/first_login_password.txt | cut -d: -f2)") \
    && usermod -aG wireshark s04player

RUN sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's/^#\?PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config \
    && sed -i 's/^#\?X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config \
    && sed -i 's/^#\?AllowTcpForwarding.*/AllowTcpForwarding no/' /etc/ssh/sshd_config

COPY challenge/ /home/s04player/challenge/
RUN chown -R s04player:s04player /home/s04player

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
