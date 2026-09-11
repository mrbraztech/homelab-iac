FROM opencode-base:latest

ARG DEBIAN_FRONTEND=noninteractive
ARG USER_UID=1000
ARG USER_GID=1000

USER root

# Python, pip and tools required by Ansible and OpenTofu.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash-completion \
        gnupg \
        python3 \
        python3-pip \
        python3-venv \
        rsync \
        shellcheck \
    && rm -rf /var/lib/apt/lists/*

# Install OpenTofu from its official Debian repository.
RUN mkdir -p /etc/apt/keyrings \
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

# Additional directories for project-specific tools.
RUN mkdir -p \
        "${HOME}/.ansible/tmp" \
        /opt/pipx \
        /opt/venv \
    && python3 -m venv /opt/venv \
    && chown -R "${USER_UID}:${USER_GID}" \
        "${HOME}" \
        /opt/pipx \
        /opt/venv

ENV VIRTUAL_ENV=/opt/venv
ENV PATH="/opt/venv/bin:${PATH}"

USER ${USER_UID}:${USER_GID}

# Install pipx and repository-wide Python CLI tools.
RUN pip install --no-cache-dir --upgrade pip pipx \
    && PIPX_HOME=/opt/pipx \
       PIPX_BIN_DIR=/opt/venv/bin \
       pipx install ansible-core \
    && PIPX_HOME=/opt/pipx \
       PIPX_BIN_DIR=/opt/venv/bin \
       pipx install ansible-lint \
    && PIPX_HOME=/opt/pipx \
       PIPX_BIN_DIR=/opt/venv/bin \
       pipx install yamllint \
    && PIPX_HOME=/opt/pipx \
       PIPX_BIN_DIR=/opt/venv/bin \
       pipx install pre-commit

# Validate the main tools while building the image.
RUN python --version \
    && ansible --version \
    && ansible-lint --version \
    && yamllint --version \
    && pre-commit --version \
    && tofu version \
    && opencode --version

CMD ["opencode"]
