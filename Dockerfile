FROM python:3.13-slim-bookworm

ARG DEBIAN_FRONTEND=noninteractive
ARG USER_NAME=opencode
ARG USER_UID=1000
ARG USER_GID=1000

USER root

# Common infrastructure and development tools.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        bash-completion \
        ca-certificates \
        curl \
        git \
        gnupg \
        iproute2 \
        iputils-ping \
        jq \
        less \
        make \
        netcat-openbsd \
        openssh-client \
        procps \
        rsync \
        shellcheck \
        sudo \
        tree \
        unzip \
        vim-tiny \
        wget \
        zip \
    && rm -rf /var/lib/apt/lists/*

# Install OpenTofu from its official Debian repository.
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://get.opentofu.org/opentofu.gpg \
        -o /etc/apt/keyrings/opentofu.gpg \
    && curl -fsSL https://packages.opentofu.org/opentofu/tofu/gpgkey \
        | gpg --batch --dearmor \
        -o /etc/apt/keyrings/opentofu-repo.gpg \
    && chmod a+r \
        /etc/apt/keyrings/opentofu.gpg \
        /etc/apt/keyrings/opentofu-repo.gpg \
    && printf '%s\n%s\n' \
        'deb [signed-by=/etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg] https://packages.opentofu.org/opentofu/tofu/any/ any main' \
        'deb-src [signed-by=/etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg] https://packages.opentofu.org/opentofu/tofu/any/ any main' \
        > /etc/apt/sources.list.d/opentofu.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends tofu \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user matching the host UID/GID.
RUN groupadd --gid "${USER_GID}" "${USER_NAME}" \
    && useradd \
        --uid "${USER_UID}" \
        --gid "${USER_GID}" \
        --create-home \
        --shell /bin/bash \
        "${USER_NAME}"

ENV HOME="/home/${USER_NAME}"
ENV PATH="${HOME}/.local/bin:${HOME}/.opencode/bin:/usr/local/bin:${PATH}"

# Install pipx and repository-wide Python CLI tools.
RUN python -m pip install --no-cache-dir --upgrade pip pipx \
    && PIPX_HOME=/opt/pipx \
       PIPX_BIN_DIR=/usr/local/bin \
       pipx install ansible-core \
    && PIPX_HOME=/opt/pipx \
       PIPX_BIN_DIR=/usr/local/bin \
       pipx install ansible-lint \
    && PIPX_HOME=/opt/pipx \
       PIPX_BIN_DIR=/usr/local/bin \
       pipx install yamllint \
    && PIPX_HOME=/opt/pipx \
       PIPX_BIN_DIR=/usr/local/bin \
       pipx install pre-commit

# Prepare writable directories before switching users.
RUN mkdir -p \
        /workspace \
        "${HOME}/.ssh" \
        "${HOME}/.config/opencode" \
        "${HOME}/.cache/opencode" \
        "${HOME}/.local/share/opencode" \
        "${HOME}/.local/state/opencode" \
        "${HOME}/.ansible/tmp" \
    && chown -R "${USER_UID}:${USER_GID}" \
        /workspace \
        "${HOME}" \
        /opt/pipx

USER ${USER_NAME}

# Install OpenCode for the non-root user.
RUN curl -fsSL https://opencode.ai/install | bash \
    && opencode --version

WORKDIR /workspace

# Validate the main tools while building the image.
RUN python --version \
    && ansible --version \
    && ansible-lint --version \
    && yamllint --version \
    && pre-commit --version \
    && tofu version \
    && opencode --version

CMD ["opencode"]