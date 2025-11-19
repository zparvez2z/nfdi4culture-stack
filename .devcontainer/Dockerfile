# syntax=docker/dockerfile:1
FROM mcr.microsoft.com/devcontainers/java:11

# Install Node.js 18.x, npm, yarn, Docker CLI, git-lfs, jq, make
RUN apt-get update \
    && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y --no-install-recommends \
        nodejs \
        yarn \
        docker-ce-cli \
        docker-compose-plugin \
        git-lfs \
        jq \
        make \
        unzip \
    && npm install -g pnpm@9 \
    && git lfs install \
    && rm -rf /var/lib/apt/lists/*

# Ensure docker-compose v2 is available via legacy command if needed
RUN ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose || true

ENV MAVEN_OPTS="-Xms512m -Xmx2048m"
