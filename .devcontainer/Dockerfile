# syntax=docker/dockerfile:1
FROM mcr.microsoft.com/devcontainers/java:11

# Install Node.js 18.x, npm, yarn, Docker CLI, git-lfs, jq, make
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
    && install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo $VERSION_CODENAME) stable" > /etc/apt/sources.list.d/docker.list \
    && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get update \
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

ENV MAVEN_OPTS="-Xms512m -Xmx2048m"
