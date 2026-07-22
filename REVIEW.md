# Reviewing and Testing Ansible Changes

This document defines the minimum review and testing process for changes made to this Ansible repository.

The goal is to prevent configuration errors, accidental changes to multiple hosts, non-idempotent tasks, and infrastructure changes that work only on already-configured machines.

---

## 1. Review the Changes

Before running any playbook, inspect exactly what changed.

```bash
git status
git diff --stat
git diff
```

New untracked files are not shown by `git diff`. List them with:

```bash
git ls-files --others --exclude-standard
```

Pay special attention to changes under:

```text
roles/
playbooks/
inventories/
group_vars/
host_vars/
requirements.yml
ansible.cfg
```

During review, verify:

- The play targets the intended hosts.
- Variables have clear names and sensible defaults.
- Secrets are not committed in plain text.
- Tasks use Ansible modules instead of `shell` or `command` whenever possible.
- File paths, package names, repository URLs, and distribution codenames are correct.
- Destructive tasks are protected by conditions.
- Handlers are notified only when a real change occurs.
- Service restarts are necessary and intentional.
- Tasks are expected to be idempotent.

---

## 2. Validate YAML and Ansible Style

Run static validation before connecting to any host.

```bash
yamllint .
ansible-lint .
```

Resolve errors related to:

- Invalid YAML.
- Invalid or deprecated module parameters.
- Unknown modules.
- Missing task names.
- Risky use of `shell` or `command`.
- Tasks that always report changes.
- Incorrect permissions.
- Missing handlers.
- Undefined variables.

Warnings should also be reviewed. Do not ignore warnings without understanding why they are safe.

---

## 3. Validate the Ansible Configuration

Confirm that Ansible is loading the repository configuration:

```bash
ansible --version
ansible-config dump --only-changed
```

The `config file` field should point to the repository's `ansible.cfg`.

Example:

```text
config file = /home/user/workspace/homelab-iac/ansible.cfg
```

If it shows:

```text
config file = None
```

run the command from the repository root or explicitly configure `ANSIBLE_CONFIG`.

---

## 4. Validate the Inventory

Inspect the inventory before running a playbook:

```bash
ansible-inventory --graph
ansible-inventory --list
```

Verify:

- Hostnames and groups are correct.
- Host addresses point to the expected machines.
- The intended environment is selected.
- Production and test hosts are not mixed unintentionally.
- Group and host variables are applied to the correct targets.

Test connectivity:

```bash
ansible all -m ping
```

Prefer testing a single host first:

```bash
ansible <host> -m ping
```

Test privilege escalation:

```bash
ansible <host> -b -m command -a 'id'
```

Expected output should include:

```text
uid=0(root)
```

---

## 5. Validate Playbook Syntax

Run a syntax check before execution:

```bash
ansible-playbook playbooks/<playbook>.yml --syntax-check
```

With an explicit inventory:

```bash
ansible-playbook   -i inventories/<environment>/hosts.yml   playbooks/<playbook>.yml   --syntax-check
```

Also inspect the playbook execution scope:

```bash
ansible-playbook playbooks/<playbook>.yml --list-hosts
ansible-playbook playbooks/<playbook>.yml --list-tasks
ansible-playbook playbooks/<playbook>.yml --list-tags
```

Confirm that:

- Only the intended hosts are listed.
- The expected roles and tasks are included.
- Tags are correctly assigned.
- No unrelated play is executed.

---

## 6. Run in Check Mode

Use check mode before making real changes:

```bash
ansible-playbook   playbooks/<playbook>.yml   --check   --diff
```

Prefer limiting execution to one test host:

```bash
ansible-playbook   -i inventories/<environment>/hosts.yml   playbooks/<playbook>.yml   --limit <test-host>   --check   --diff
```

`--check` simulates supported changes.

`--diff` shows changes to managed files and templates.

Check mode has limitations. Some modules and commands cannot fully simulate their behavior. Review tasks containing:

```yaml
check_mode: false
```

Also review tasks using:

```yaml
ansible.builtin.command:
ansible.builtin.shell:
```

These tasks may need explicit safeguards and accurate `changed_when` and `failed_when` conditions.

---

## 7. Use a Safe Test Target

Infrastructure changes should be tested on one of the following:

- A disposable virtual machine.
- A clone of the target machine.
- A machine with a recent snapshot.
- A dedicated test inventory.
- A non-critical host with equivalent operating system and configuration.

Before testing a potentially disruptive role, create a snapshot.

Example snapshot name:

```text
before-ansible-<role>-test
```

Do not run a new or unreviewed playbook against every host.

Always use `--limit` during the first real execution:

```bash
ansible-playbook   -i inventories/<environment>/hosts.yml   playbooks/<playbook>.yml   --limit <test-host>
```

Add `--ask-become-pass` when required:

```bash
ansible-playbook   -i inventories/<environment>/hosts.yml   playbooks/<playbook>.yml   --limit <test-host>   --ask-become-pass
```

---

## 8. Run the Playbook

After static validation and check mode succeed, run the playbook against one test host:

```bash
ansible-playbook   -i inventories/<environment>/hosts.yml   playbooks/<playbook>.yml   --limit <test-host>
```

The first execution must finish with:

```text
failed=0
unreachable=0
```

Review every changed task. A successful return code does not guarantee that the resulting configuration is correct.

---

## 9. Validate the Result

Validate the resulting system state independently from the tasks that created it.

Examples:

```bash
ansible <test-host> -b -m command -a 'systemctl is-active <service>'
ansible <test-host> -b -m command -a 'systemctl is-enabled <service>'
ansible <test-host> -b -m command -a '<application> --version'
```

For configuration files:

```bash
ansible <test-host> -b -m command -a 'cat /path/to/configuration'
```

For listening ports:

```bash
ansible <test-host> -b -m shell -a 'ss -lntup'
```

For service logs:

```bash
ansible <test-host> -b -m shell   -a 'journalctl -u <service> -b --no-pager'
```

Application-specific functional tests should also be performed. A process being active does not necessarily mean the service is usable.

---

## 10. Test Idempotency

Every configuration role should be idempotent.

Run the same playbook a second time with the same inventory, variables, and limit:

```bash
ansible-playbook   -i inventories/<environment>/hosts.yml   playbooks/<playbook>.yml   --limit <test-host>
```

The expected second-run summary is:

```text
changed=0
failed=0
unreachable=0
```

Example:

```text
ok=15 changed=0 unreachable=0 failed=0 skipped=2 rescued=0 ignored=0
```

If the second execution reports changes, identify the task responsible.

Common causes of non-idempotency include:

- Unconditional `command` or `shell` tasks.
- Running `apt update` as a command.
- Downloading files without checksums or conditions.
- Recreating files through shell commands.
- Running application setup commands every time.
- Incorrect file ownership or mode declarations.
- Templates containing dynamic timestamps.
- Handlers being notified on every execution.
- Missing `creates`, `removes`, `changed_when`, or conditions.
- Repository keys being downloaded or converted on every run.

Do not accept persistent changes without documenting why they are unavoidable.

---

## 11. Test Reboot Persistence

For roles that install services, configure networking, mount filesystems, manage containers, or change boot behavior, test a reboot.

```bash
ansible <test-host> -b -m reboot
```

After the host returns:

```bash
ansible <test-host> -m ping
ansible <test-host> -b -m command -a 'systemctl is-active <service>'
ansible <test-host> -b -m command -a 'systemctl is-enabled <service>'
```

Also rerun the playbook after reboot:

```bash
ansible-playbook   -i inventories/<environment>/hosts.yml   playbooks/<playbook>.yml   --limit <test-host>
```

It should remain idempotent.

---

## 12. Docker Role Validation

When reviewing or testing changes to the Docker role, validate at least the following.

### Repository configuration

Confirm that the repository matches the target operating system:

```bash
ansible <test-host> -b -m shell   -a "grep -Rni docker /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null"
```

For Ubuntu 24.04, the repository should use:

```text
noble
```

It should not incorrectly reference older releases such as:

```text
focal
jammy
```

### Package and service state

```bash
ansible <test-host> -b -m command -a 'docker version'
ansible <test-host> -b -m command -a 'docker compose version'
ansible <test-host> -b -m command -a 'systemctl is-active docker'
ansible <test-host> -b -m command -a 'systemctl is-enabled docker'
```

### Functional container test

```bash
ansible <test-host> -b -m command   -a 'docker run --rm hello-world'
```

### User access

When the role adds a user to the Docker group, verify group membership:

```bash
ansible <test-host> -m command -a 'id'
```

A new login session or reboot may be required before Docker group membership becomes active.

Then test Docker without privilege escalation:

```bash
ansible <test-host> -m command -a 'docker ps'
```

### Docker daemon configuration

When `/etc/docker/daemon.json` is managed, validate its contents:

```bash
ansible <test-host> -b -m command   -a 'cat /etc/docker/daemon.json'
```

Confirm that Docker restarts only when this file changes.

---

## 13. Review Secrets and Sensitive Data

Before committing:

```bash
git diff --cached
git grep -nEi   '(password|passwd|secret|token|api[_-]?key|private[_-]?key)'
```

Verify that the repository does not contain:

- Passwords.
- API tokens.
- Private keys.
- Personal access tokens.
- Unencrypted vault values.
- Internal credentials in inventory files.
- Sensitive `.env` files.

Use Ansible Vault or an external secret manager for sensitive values.

Example:

```bash
ansible-vault encrypt group_vars/<group>/vault.yml
```

---

## 14. Suggested Validation Sequence

Run the following sequence from the repository root:

```bash
git status
git diff --stat
git diff
git ls-files --others --exclude-standard

yamllint .
ansible-lint .

ansible --version
ansible-config dump --only-changed
ansible-inventory --graph
ansible all -m ping

ansible-playbook playbooks/<playbook>.yml --syntax-check
ansible-playbook playbooks/<playbook>.yml --list-hosts
ansible-playbook playbooks/<playbook>.yml --list-tasks

ansible-playbook   -i inventories/<environment>/hosts.yml   playbooks/<playbook>.yml   --limit <test-host>   --check   --diff

ansible-playbook   -i inventories/<environment>/hosts.yml   playbooks/<playbook>.yml   --limit <test-host>

ansible-playbook   -i inventories/<environment>/hosts.yml   playbooks/<playbook>.yml   --limit <test-host>
```

For service-related changes, finish with:

```bash
ansible <test-host> -b -m reboot
ansible <test-host> -m ping
```

Then rerun the playbook and confirm `changed=0`.

---

## 15. Acceptance Criteria

A change is ready to merge when all applicable criteria are satisfied:

- [ ] The diff was manually reviewed.
- [ ] No secret or sensitive value was committed.
- [ ] YAML validation passes.
- [ ] `ansible-lint` passes or exceptions are documented.
- [ ] The inventory resolves correctly.
- [ ] Connectivity and privilege escalation work.
- [ ] The playbook passes `--syntax-check`.
- [ ] The target host list was reviewed.
- [ ] Check mode was reviewed when supported.
- [ ] The first execution completed with `failed=0` and `unreachable=0`.
- [ ] The resulting service or application was functionally tested.
- [ ] The second execution completed with `changed=0`.
- [ ] Reboot persistence was tested when applicable.
- [ ] The playbook remains idempotent after reboot.
- [ ] The change was initially tested using `--limit`.
- [ ] Documentation and variables were updated when necessary.

---

## 16. Pull Request Evidence

A pull request that changes infrastructure should include:

- A summary of the change.
- The affected hosts or groups.
- The playbook and roles executed.
- The exact test command used.
- The first-run recap.
- The second-run idempotency recap.
- Functional validation results.
- Whether a reboot was tested.
- Known limitations or manual follow-up steps.

Example:

```text
Test host: docker-test-01
Playbook: playbooks/docker.yml

First run:
ok=18 changed=7 unreachable=0 failed=0

Second run:
ok=18 changed=0 unreachable=0 failed=0

Functional checks:
- Docker service active and enabled
- Docker Compose available
- hello-world container completed successfully
- Docker usable by the configured non-root user
- Host rebooted and validated successfully
```

---

## Important Safety Rules

- Never test a new playbook against all hosts first.
- Always review `--list-hosts`.
- Use `--limit` during initial execution.
- Create a snapshot before disruptive tests.
- Never use `docker compose down -v`, filesystem formatting, package purging, or destructive database commands without explicit review.
- Do not assume check mode makes every task safe.
- A successful playbook is not enough; validate the resulting service.
- A second run with `changed=0` is the primary idempotency criterion.