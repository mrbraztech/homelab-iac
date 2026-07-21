# Homelab Infrastructure as Code

Infrastructure as Code (IaC) repository for managing my homelab using **Ansible**. The primary goal is to create a reproducible, secure, and maintainable environment following industry best practices.

This repository is designed to evolve over time. Initially it focuses on server bootstrapping and configuration management. Future phases will include infrastructure provisioning, secrets management, monitoring, and application deployment.

---

# Goals

* Automate server provisioning and configuration.
* Eliminate manual configuration drift.
* Keep infrastructure reproducible.
* Follow idempotent configuration management principles.
* Organize infrastructure using reusable Ansible roles.
* Build a foundation that can later integrate with OpenTofu.

---

# Project Status

Current phase:

* ✅ Project structure
* ✅ Inventory
* ✅ Bootstrap role
* ✅ Administrative user
* ✅ SSH key authentication
* ✅ System hardening (in progress)

Planned phases:

* Docker
* PostgreSQL
* Redis
* Reverse Proxy
* Monitoring
* AI Services
* Storage
* Backup
* OpenTofu integration

---

# Project Structure

```text
homelab-iac/
├── ansible.cfg
├── collections/
│   └── requirements.yml
├── inventories/
│   └── lab/
│       ├── hosts.yml
│       ├── group_vars/
│       └── host_vars/
├── playbooks/
│   └── bootstrap.yml
├── roles/
│   └── common/
├── docs/
└── README.md
```

---

# Repository Layout

## inventories/

Contains the inventory for each environment.

Current environment:

* lab

Each inventory contains:

* hosts
* group variables
* host variables

---

## playbooks/

Contains high-level playbooks.

Example:

* bootstrap.yml

Playbooks should orchestrate roles instead of containing implementation logic.

---

## roles/

Reusable infrastructure components.

Example roles:

* common
* docker
* postgresql
* redis
* nextcloud
* immich
* ai-rag
* monitoring

Each role should be self-contained and idempotent.

---

## docs/

Documentation about architecture, credentials, operational procedures, and recovery.

Examples:

* architecture.md
* credentials.md
* access.md
* disaster-recovery.md

---

# Development Principles

This project follows the following principles:

* Infrastructure as Code
* Idempotency
* Reusability
* Simplicity
* Security by default
* Small, focused roles
* English for code, variables, logs, and documentation

---

# Requirements

Controller machine:

* Linux
* Python 3
* Ansible
* Git
* OpenSSH

Managed hosts:

* Debian
* SSH access
* Python installed

---

# Installing Collections

```bash
ansible-galaxy collection install -r collections/requirements.yml
```

---

# Inventory Validation

```bash
ansible-inventory --graph
```

---

# Connectivity Test

```bash
ansible lab -m ping
```

---

# Syntax Validation

```bash
ansible-playbook playbooks/bootstrap.yml --syntax-check
```

---

# Dry Run

```bash
ansible-playbook playbooks/bootstrap.yml --check --diff
```

---

# Apply Configuration

```bash
ansible-playbook playbooks/bootstrap.yml
```

---

# Bootstrap Process

The bootstrap playbook is responsible for preparing a clean server by:

* Updating packages
* Configuring locale
* Configuring timezone
* Installing common packages
* Creating the administrative user
* Configuring sudo
* Installing SSH public keys
* Configuring SSH
* Enabling required services

After bootstrap, all administration should be performed using the administrative user instead of root.

---

# Security

The project adopts the following security practices:

* SSH key authentication
* Dedicated administrative user
* Password authentication disabled
* Root password login disabled
* Principle of least privilege
* Secrets stored outside the repository

Sensitive information must never be committed to Git.

---

# Coding Standards

* YAML files use two-space indentation.
* Task names must clearly describe their purpose.
* Every role must be idempotent.
* Variables should be defined in defaults whenever possible.
* Prefer Ansible modules over shell commands.
* Keep tasks small and focused.

---

# Future Roadmap

## Foundation

* Improve common role
* SSH hardening
* Firewall
* Linting
* Pre-commit hooks

## Platform

* Docker
* Compose
* Networks
* Storage

## Data Layer

* PostgreSQL
* Redis
* Backups

## Applications

* Nextcloud
* Immich
* AI-RAG
* Monitoring

## Infrastructure

* OpenTofu
* Secrets management
* CI/CD
* Disaster recovery

---

# Documentation

Additional documentation will be placed under the `docs/` directory.

Topics include:

* Architecture
* Credentials inventory
* Access procedures
* Network topology
* Disaster recovery
* Operating procedures

---

# License

This repository is intended for personal use and learning purposes.
