---
name: ansible
description: Create, review, test, and troubleshoot Ansible inventories, playbooks, roles, collections, templates, handlers, Vault usage, and automation pipelines. Use for idempotency, ansible-lint, Molecule, privilege escalation, host variables, and infrastructure configuration.
license: MIT
compatibility: OpenCode; requires Ansible for execution. Optional: ansible-lint, yamllint, Molecule, pytest-testinfra, pre-commit.
metadata:
  category: infrastructure
  language: repository-english-conversation-pt-br
  version: "1.0.0"
---

# Ansible Automation

Use this skill for Ansible configuration management and operational automation.


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


## Workflow

### 1. Discover repository conventions

Inspect:

- `ansible.cfg`
- inventory layout and group hierarchy
- `group_vars/` and `host_vars/`
- collections and `requirements.yml`
- roles and playbooks
- Vault conventions
- lint and pre-commit configuration
- Molecule scenarios
- CI workflows

Determine the supported Ansible Core and Python versions before introducing syntax or modules.

### 2. Design for idempotency

- Prefer Ansible modules over `shell` and `command`.
- Use fully qualified collection names when repository policy requires them.
- Add `changed_when` and `failed_when` when command execution is unavoidable.
- Use handlers for restart/reload actions.
- Notify handlers only when configuration changes.
- Avoid unconditional service restarts.
- Use `creates`, `removes`, or explicit state checks for non-idempotent commands.
- Do not hide failures with `ignore_errors` unless the behavior is intentionally optional and documented.
- Use check mode compatible patterns when feasible.

### 3. Structure roles

A role may include:

```text
defaults/main.yml
vars/main.yml
tasks/main.yml
handlers/main.yml
templates/
files/
meta/main.yml
README.md
molecule/
```

Use defaults for user-overridable values and vars only for internal constants. Keep task files focused and use descriptive names.

### 4. Handle variables and secrets

- Avoid duplicated variables across inventory levels.
- Document precedence-sensitive choices.
- Prefix role variables to avoid collisions.
- Do not commit plaintext secrets.
- Use Ansible Vault, environment injection, or an established secret manager.
- Apply `no_log: true` only to tasks that may expose secrets; do not use it broadly enough to destroy diagnostics.
- Never display decrypted Vault content.

### 5. Use safe privilege escalation

- Apply `become` at the narrowest reasonable scope.
- Do not assume SSH root access.
- Avoid modifying sudoers without syntax validation.
- Preserve existing connection and bastion conventions.

### 6. Validate

Run the narrowest relevant checks:

```bash
ansible-playbook --syntax-check playbook.yml
ansible-inventory --graph
ansible-inventory --list
ansible-lint
yamllint .
```

For a safe target and supported playbook:

```bash
ansible-playbook playbook.yml --check --diff --limit target
```

Treat check mode as advisory because not all modules support it accurately.

When Molecule exists:

```bash
molecule test
```

### 7. Operational execution

Before a production run:

- confirm inventory and limit
- confirm tags and skipped tags
- review serial/batch behavior
- identify restarts and downtime
- verify rollback or rescue path
- confirm backups for edited critical files

Prefer:

```bash
ansible-playbook site.yml --limit exact-host --tags specific-tag --check --diff
```

before a broad apply.

## Common review targets

- non-idempotent shell usage
- permissions and ownership
- unsafe variable defaults
- missing handlers
- service ordering
- package cache behavior
- template validation
- accidental secret exposure
- inventory ambiguity
- tasks without names
- broad `become: true`
- inappropriate `latest` package state
- ignored errors
- missing tags for operational control

## Expected output

For generated roles, include a concise English README with variables, dependencies, examples, and supported platforms. Use [the output template](assets/output-template.md) for substantial reviews and [the checklist](references/checklist.md) before completion.
