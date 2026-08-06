---
name: docker
description: Create, review, secure, optimize, and troubleshoot Dockerfiles, Docker Compose stacks, images, containers, networks, volumes, health checks, logging, and deployment workflows. Use for container builds, Compose, permissions, GPU access, rootless operation, and production hardening.
license: MIT
compatibility: OpenCode; requires Docker Engine or compatible tooling for execution. Optional: Docker Compose, Hadolint, Trivy, ShellCheck, cosign.
metadata:
  category: infrastructure
  language: repository-english-conversation-pt-br
  version: "1.0.0"
---

# Docker Platform Engineering

Use this skill for Docker image, Compose, runtime, and operational work.


## Communication and artifact language

- Communicate with the user in Brazilian Portuguese.
- Write every repository artifact in English.
- Keep code, comments, documentation, configuration, logs, errors, identifiers, test names, commit messages, and pull request text in English.
- Do not translate existing identifiers or external API fields unless the task explicitly requires it.

## Operating principles

1. Inspect the repository and current configuration before proposing changes.
2. Reuse existing conventions instead of introducing parallel patterns.
3. Prefer declarative, idempotent, reviewable, and reversible changes.
4. Separate facts observed in the repository from assumptions.
5. Do not expose secrets in output, logs, examples, commits, or generated files.
6. Run the narrowest useful validation before broad or destructive actions.
7. Never claim success without checking the relevant command output or resulting state.
8. Explain performed work and remaining risks in Brazilian Portuguese.

## Safety boundaries

- Do not apply destructive changes without explicit user approval.
- Do not delete infrastructure, state, data, backups, volumes, networks, users, or access rules merely to make validation pass.
- Do not rotate credentials, modify production access, run database restores, or change firewall policy without explicit approval.
- When a task can affect production, first produce a plan, expected impact, rollback procedure, and validation steps.


## Discover the stack

Inspect:

- Dockerfiles and build contexts
- `.dockerignore`
- Compose files and overrides
- environment files and secret handling
- entrypoints and health checks
- volume and network definitions
- user/UID/GID behavior
- resource limits and logging
- CI image build/publish workflow
- reverse proxy and service discovery conventions

Do not expose values from `.env`, Docker secrets, or mounted credentials.

## Dockerfile rules

- Pin base images intentionally; use digest pinning when repository policy requires reproducibility.
- Prefer small, trusted upstream images.
- Use multi-stage builds.
- Order layers for cache efficiency.
- Combine package installation and cache cleanup in one layer.
- Avoid `curl | sh` without checksum/signature validation.
- Run as a non-root user unless the workload requires root.
- Set explicit `WORKDIR`.
- Use exec-form `ENTRYPOINT`/`CMD`.
- Preserve signal handling and graceful shutdown.
- Copy only required files.
- Do not bake secrets into image layers.
- Add a health check only when it provides a reliable signal and is not better defined in orchestration.

## Compose rules

- Use named services and networks.
- Use named volumes for managed persistent data; use bind mounts intentionally.
- Avoid `privileged: true`.
- Drop capabilities and add only those required.
- Prefer read-only filesystems where compatible.
- Define health checks and condition startup on health only where Compose version supports it.
- Add restart policies deliberately.
- Avoid `latest` for production images.
- Configure resource limits according to deployment mode.
- Use `init: true` when PID 1 behavior requires it.
- Do not expose internal service ports unnecessarily.
- Use `127.0.0.1:host:container` bindings for host-only access where appropriate.
- Do not hard-code credentials in Compose.

## Security review

Check:

- root execution
- privileged mode
- Docker socket mounts
- host networking
- host PID/IPC namespaces
- sensitive host paths
- excessive capabilities
- writable root filesystem
- public ports
- image provenance
- secrets in layers/environment
- unbounded logs
- missing resource limits

Treat `/var/run/docker.sock` as root-equivalent access.

## Storage and permissions

Before changing UID/GID or mounts:

- identify host ownership
- identify container runtime user
- distinguish bind mount from named volume
- verify SELinux/AppArmor constraints
- preserve existing data
- document migration and rollback

Never recursively `chown` a broad host path without confirming scope.

## Networking

Distinguish:

- default bridge
- user-defined bridge
- host network
- macvlan/ipvlan
- external networks
- LXC nested Docker constraints

When the host can reach a service but a container cannot, test from inside the container and inspect Docker forwarding/NAT before blaming the application.

## Validation

Run applicable checks:

```bash
docker compose config
docker build --check .
hadolint Dockerfile
shellcheck entrypoint.sh
trivy config .
trivy image <image>
```

For Compose:

```bash
docker compose up -d
docker compose ps
docker compose logs --tail=200
```

Do not execute `docker system prune`, volume deletion, or destructive recreation without approval.

## Troubleshooting order

1. `docker compose config`
2. `docker compose ps`
3. container logs
4. inspect health and exit code
5. inspect mounts, networks, and environment names
6. test connectivity from inside the container
7. inspect host firewall/NAT
8. reproduce with the narrowest service

## Expected output

For changes, include impact on persisted data, ports, downtime, and rollback. Use [the output template](assets/output-template.md) and [the checklist](references/checklist.md).
