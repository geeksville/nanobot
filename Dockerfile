FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

# Install Node.js 20 for the WhatsApp bridge
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates gnupg git sudo && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" > /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends nodejs
    #apt-get purge -y gnupg && \
    #apt-get autoremove -y && \
    #rm -rf /var/lib/apt/lists/*

# Create or use existing user with UID 1000, home set to /app
# Configure passwordless sudo for that user
RUN if getent passwd 1000 >/dev/null 2>&1; then \
        EXISTING_USER=$(getent passwd 1000 | cut -d: -f1) && \
        usermod -d /app "$EXISTING_USER"; \
    else \
        useradd -u 1000 -d /app -s /bin/bash appuser && \
        EXISTING_USER=appuser; \
    fi && \
    echo "$EXISTING_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    echo "export CONTAINER_USER=$EXISTING_USER" > /etc/profile.d/container_user.sh

# Create /opt/nakedclaw directory and set ownership to UID 1000
RUN mkdir -p /app && chown 1000:1000 /app

WORKDIR /app

# Install Python dependencies first (cached layer) - as root for system site-packages
COPY pyproject.toml README.md LICENSE ./
RUN mkdir -p nanobot bridge && touch nanobot/__init__.py && \
    uv pip install --system --no-cache . && \
    rm -rf nanobot bridge

# Copy the full source and install
COPY nanobot/ nanobot/
COPY bridge/ bridge/
RUN uv pip install --system --no-cache .

# Build the WhatsApp bridge
WORKDIR /app/bridge
RUN npm install && npm run build
WORKDIR /app

# Switch to the existing user with UID 1000
USER 1000:1000
ENV HOME=/app

# Create config directory (writable by UID 1000)
RUN mkdir -p /app/.nanobot

# Gateway default port
EXPOSE 18790

ENTRYPOINT ["nanobot"]
CMD ["status"]
