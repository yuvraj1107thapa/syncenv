FROM ubuntu:22.04

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    openssh-server \
    avahi-daemon \
    avahi-utils \
    libnss-mdns \
    age \
    jq \
    netcat \
    iputils-ping \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Create syncenv user
RUN useradd -m -s /bin/bash -u 1000 syncenv && \
    echo 'syncenv:syncenv' | chpasswd && \
    usermod -aG sudo syncenv

# Configure SSH
RUN mkdir -p /var/run/sshd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config

# Allow syncenv user to run commands without password (for tests)
RUN echo 'syncenv ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/syncenv && \
    chmod 440 /etc/sudoers.d/syncenv

# Configure Avahi for mDNS (enable D-Bus)
RUN sed -i 's/#enable-dbus=yes/enable-dbus=yes/' /etc/avahi/avahi-daemon.conf
RUN sed -i 's/hosts:.*files dns/hosts: files mdns_minimal [NOTFOUND=return] dns mdns/' /etc/nsswitch.conf

# Copy syncenv binary (built from source)
ARG SYNCENV_BIN=target/syncenv
COPY ${SYNCENV_BIN} /usr/local/bin/syncenv

# Make scripts executable
RUN chmod +x /usr/local/bin/syncenv*

# Create syncenv directories for syncenv user
RUN mkdir -p /home/syncenv/.config/syncenv/keys/known_hosts && \
    mkdir -p /home/syncenv/.config/syncenv/logs && \
    mkdir -p /home/syncenv/.ssh && \
    chmod 700 /home/syncenv/.ssh && \
    chmod 755 /home/syncenv/.config && \
    chmod 700 /home/syncenv/.config/syncenv && \
    chmod 700 /home/syncenv/.config/syncenv/keys && \
    chown -R syncenv:syncenv /home/syncenv

# Entrypoint script
COPY tests/docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
