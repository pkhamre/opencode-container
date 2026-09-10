# syntax=docker/dockerfile:1

FROM debian:13-slim@sha256:d7e12182ce18b85b93007c1dedf31f2d29e01ccf3182cc4017c709b6259bc132 AS builder-tools

ARG USER_UID=1000
ARG USER_GID=1000
ARG NODE_MAJOR=24
ARG OPENCODE_VERSION=1.18.30

# Proxy passthrough; both cases because apt/curl/gpg prefer lowercase,
# npm/pip/git differ on which they read. Makefile normalizes so both arrive set.
ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY
ARG http_proxy
ARG https_proxy
ARG no_proxy
ENV HTTP_PROXY=${HTTP_PROXY} \
    HTTPS_PROXY=${HTTPS_PROXY} \
    NO_PROXY=${NO_PROXY} \
    http_proxy=${http_proxy} \
    https_proxy=${https_proxy} \
    no_proxy=${no_proxy}

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install --no-install-recommends -y \
    ca-certificates \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# The custom bundle is optional. Mounting the build context keeps it out of an
# image layer until its individual certificates are installed into the trust store.
RUN --mount=type=bind,source=.,target=/build-context,ro \
    set -eu; \
    if [ -s /build-context/custom-ca.crt ]; then \
      mkdir -p /usr/local/share/ca-certificates; \
      awk '\
        /-----BEGIN CERTIFICATE-----/ {\
          n++;\
          output=sprintf("/usr/local/share/ca-certificates/opencode-custom-ca-%03d.crt", n);\
          in_cert=1;\
        }\
        in_cert { print > output }\
        /-----END CERTIFICATE-----/ { close(output); in_cert=0 }\
      ' /build-context/custom-ca.crt; \
      found=0; \
      for certificate in /usr/local/share/ca-certificates/opencode-custom-ca-*.crt; do \
        [ -f "$$certificate" ] || continue; \
        found=1; \
        if ! openssl x509 -in "$$certificate" -noout >/dev/null 2>&1; then \
          echo "invalid PEM X.509 certificate in custom-ca.crt: $$certificate" >&2; \
          exit 1; \
        fi; \
      done; \
      if [ "$$found" -eq 0 ]; then \
        echo "custom-ca.crt does not contain a PEM X.509 certificate" >&2; \
        exit 1; \
      fi; \
      update-ca-certificates; \
    fi

# npm does not automatically use Debian's system CA bundle for registry TLS.
ENV NPM_CONFIG_CAFILE=/etc/ssl/certs/ca-certificates.crt

RUN apt-get update && apt-get install --no-install-recommends -y \
    curl \
    gnupg \
    git \
    python3 \
    python3-venv \
    xclip \
    wl-clipboard \
    ripgrep \
    jq \
    rustc \
    cargo \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" > /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && apt-get install --no-install-recommends -y nodejs && \
    rm -rf /var/lib/apt/lists/*

RUN echo "Installing OpenCode version: ${OPENCODE_VERSION}" && \
    curl -fsSL https://opencode.ai/install -o /tmp/install-opencode.sh && \
    echo "fc3c1b2123f49b6df545a7622e5127d21cd794b15134fc3b66e1ca49f7fb297e  /tmp/install-opencode.sh" | sha256sum -c - && \
    bash /tmp/install-opencode.sh --version "${OPENCODE_VERSION}" --no-modify-path && \
    rm -f /tmp/install-opencode.sh && \
    install -m 0755 /root/.opencode/bin/opencode /usr/local/bin/opencode

RUN npm install -g @upstash/context7-mcp@4.0.6

RUN node --version && \
    npm --version && \
    python3 --version && \
    python3 -m venv /tmp/test-venv && \
    rm -rf /tmp/test-venv && \
    opencode --version

COPY scripts/collect-runtime-deps.sh /usr/local/bin/collect-runtime-deps.sh
RUN chmod 0755 /usr/local/bin/collect-runtime-deps.sh

FROM builder-tools AS collector

ARG USER_UID=1000
ARG USER_GID=1000

RUN mkdir -p /opt/runtime-rootfs && \
    /usr/local/bin/collect-runtime-deps.sh /opt/runtime-rootfs \
      opencode node npm python3 xclip wl-copy wl-paste git \
      mkdir find grep rg jq cat head tail sed awk \
      ls cp mv rm chmod wc sort cut env date dirname basename \
      rustc cargo

RUN cd /opt/runtime-rootfs && \
    for dir in bin sbin; do \
      if [ -d "$${dir}" ] && [ ! -L "$${dir}" ]; then \
        mkdir -p "usr/$${dir}"; \
        if [ -n "$(ls -A "$${dir}" 2>/dev/null)" ]; then \
          cp -a "$${dir}"/. "usr/$${dir}"/; \
        fi; \
        rm -rf "$${dir}"; \
        ln -s "usr/$${dir}" "$${dir}"; \
      fi; \
    done && \
    mkdir -p lib/x86_64-linux-gnu && \
    cp -a usr/lib/x86_64-linux-gnu/. lib/x86_64-linux-gnu/

RUN mkdir -p /opt/runtime-rootfs/app/.local/share /opt/runtime-rootfs/app/.config/opencode /opt/runtime-rootfs/app/.cache && \
    chown -R ${USER_UID}:${USER_GID} /opt/runtime-rootfs/app && \
    printf 'opencode:x:%s:%s:OpenCode User:/app:/usr/bin/python3\n' "${USER_UID}" "${USER_GID}" >> /opt/runtime-rootfs/etc/passwd && \
    printf 'opencode:x:%s:\n' "${USER_GID}" >> /opt/runtime-rootfs/etc/group

FROM gcr.io/distroless/base-debian13@sha256:9ef50bca108839d5986e4d84b7f7b2d79024c9293b7c35b162c6c55485bd5868 AS final

ARG USER_UID=1000
ARG USER_GID=1000

WORKDIR /app

ENV HOME=/app
ENV XDG_CONFIG_HOME=/app/.config
ENV OPENCODE_CONFIG_DIR=/app/.config/opencode
ENV XDG_DATA_HOME=/app/.local/share
ENV PATH=/usr/local/bin:/usr/bin
ENV NPM_CONFIG_CAFILE=/etc/ssl/certs/ca-certificates.crt

COPY --from=collector /opt/runtime-rootfs/ /
COPY --chmod=0755 bootstrap.py /usr/local/bin/bootstrap.py

USER ${USER_UID}:${USER_GID}

ENTRYPOINT ["/usr/bin/python3", "/usr/local/bin/bootstrap.py"]
