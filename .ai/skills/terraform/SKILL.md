---
name: terraform
description: Design, implement, review, test, import, and troubleshoot Terraform or OpenTofu infrastructure. Use for .tf files, modules, providers, plans, state, drift, imports, lifecycle rules, workspaces, remote backends, Proxmox IaC, and infrastructure security reviews.
license: MIT
compatibility: OpenCode; requires Terraform or OpenTofu for validation. Optional: tflint, tfsec, checkov, terraform-docs, jq.
metadata:
  category: infrastructure
  language: repository-english-conversation-pt-br
  version: "1.0.0"
---

# Terraform and OpenTofu Infrastructure

Use this skill for Terraform and OpenTofu work. Treat state and plans as production-sensitive artifacts.


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

### 1. Discover the implementation

Inspect, when present:

- `versions.tf`, `providers.tf`, `backend.tf`
- root and child modules
- variable declarations and validation
- outputs and sensitive flags
- environment directories and `.tfvars`
- lock files and CI workflows
- README and architecture decisions
- state references without printing secret values

Determine whether the repository uses Terraform, OpenTofu, or compatibility with both. Preserve the existing choice unless the user requests a migration.

### 2. Establish the change contract

Before editing, identify:

- requested outcome
- target environment and scope
- resources that may be replaced or destroyed
- state/backend implications
- provider constraints
- expected inputs and outputs
- rollback or recovery path

For ambiguous production changes, prepare a plan instead of applying changes.

### 3. Implement with module discipline

- Keep modules focused and composable.
- Use typed variables with descriptions and validation.
- Mark secret outputs and variables as sensitive where appropriate.
- Avoid hard-coded environment values, credentials, IPs, and identifiers.
- Pin provider versions with intentional constraints.
- Commit provider lock files unless repository policy says otherwise.
- Prefer `for_each` with stable keys over index-based `count` for long-lived resources.
- Use `lifecycle` only for a documented reason.
- Avoid provisioners unless no declarative provider capability exists.
- Do not add `ignore_changes` to hide unmanaged drift without explaining the tradeoff.

### 4. Validate

Run the tools available in the repository, in this order where applicable:

```bash
tofu fmt -check -recursive
tofu init -backend=false
tofu validate
```

or:

```bash
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
```

Then run configured linters or security scanners:

```bash
tflint --recursive
tfsec .
checkov -d .
```

Do not invent tool success when a dependency or provider cannot be downloaded.

### 5. Review plans safely

When reviewing a plan:

- distinguish create, update-in-place, replace, and destroy
- call out force replacement and computed unknown values
- identify security, availability, cost, and data-loss risks
- check dependency ordering and unexpected provider behavior
- verify sensitive data is not printed
- compare the plan to the user request
- do not run `apply` without explicit approval

Prefer saved plans for apply workflows:

```bash
tofu plan -out=tfplan
tofu show -json tfplan > tfplan.json
```

### 6. Handle state carefully

Before any state mutation:

- back up state
- confirm workspace/backend
- identify exact resource addresses
- provide dry-run or inspection commands
- document recovery

State commands requiring explicit approval include:

```bash
tofu state rm
tofu state mv
tofu import
tofu force-unlock
```

Never edit state JSON manually unless recovery requires it and the user approves.

## Task-specific guidance

### Module generation

Create, when appropriate:

```text
main.tf
variables.tf
outputs.tf
versions.tf
README.md
examples/
tests/
```

Do not create empty files merely to satisfy a template.

### Importing existing infrastructure

1. Inspect provider import syntax.
2. Write the target resource configuration first.
3. Generate import blocks when supported.
4. Run a plan after import.
5. Reconcile every unexpected diff.
6. Never assume import means full configuration was recovered.

### Drift analysis

Separate:

- intentional external changes
- provider normalization
- computed values
- genuine unmanaged drift
- dangerous reconciliation

### Refactoring

Use `moved` blocks where supported to preserve resource identity. Avoid address changes that trigger replacement.

## Expected output

Use [the output template](assets/output-template.md) for substantial reviews. Consult [the checklist](references/checklist.md) before completion.
