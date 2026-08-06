---
name: postgresql
description: Design, administer, review, migrate, back up, restore, secure, and troubleshoot PostgreSQL databases. Use for roles, privileges, schemas, extensions, migrations, indexes, query plans, vacuum, replication, Docker deployments, and disaster recovery.
license: MIT
compatibility: OpenCode; PostgreSQL client tools required for execution. Optional: pgBackRest, pgbench, pgbadger, Docker, jq.
metadata:
  category: infrastructure
  language: repository-english-conversation-pt-br
  version: "1.0.0"
---

# PostgreSQL Operations

Use this skill for PostgreSQL design, administration, performance, and recovery.


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


## Safety first

PostgreSQL tasks can cause irreversible data loss. Before mutation, identify:

- server and major version
- environment and database
- expected recovery point objective and recovery time objective
- backup status
- maintenance window
- transaction and lock impact
- rollback strategy

Never run destructive SQL against an ambiguous target.

## Discovery

Use read-only inspection first:

```sql
SELECT version();
SELECT current_database(), current_user;
SHOW server_version;
SHOW data_directory;
```

Inspect relevant catalogs without printing secrets:

- databases and owners
- roles and memberships
- schemas and privileges
- extensions
- table and index sizes
- active sessions and locks
- replication status
- autovacuum and statistics

## Roles and privileges

- Use dedicated login roles for applications.
- Use group roles for privilege composition.
- Avoid superuser for applications.
- Grant the minimum required privileges.
- Set ownership intentionally.
- Include default privileges for future objects where needed.
- Separate migration ownership from runtime access when feasible.
- Never embed passwords in SQL committed to the repository.

Review `PUBLIC` privileges on databases and schemas.

## Schema and migrations

- Use migration tooling already adopted by the repository.
- Make migrations forward-safe and review rollback feasibility.
- Avoid long table rewrites during peak traffic.
- Consider lock levels for DDL.
- Add constraints using low-lock patterns where required.
- Create large indexes concurrently when operationally appropriate.
- Never wrap `CREATE INDEX CONCURRENTLY` in a transaction.
- Validate data before adding stricter constraints.

## Query and index analysis

Use:

```sql
EXPLAIN (ANALYZE, BUFFERS, WAL, VERBOSE, SETTINGS)
```

only when executing the query is safe. For expensive or mutating statements, use plain `EXPLAIN` or a transaction-safe test environment.

Avoid indexes based solely on intuition. Check:

- query predicates and ordering
- selectivity
- write overhead
- duplicate/redundant indexes
- index size and usage
- statistics freshness
- parameterized query behavior

## Vacuum and maintenance

Do not disable autovacuum as a generic performance fix. Investigate:

- dead tuples
- transaction age
- long-running transactions
- table churn
- per-table thresholds
- bloat
- checkpoint and WAL behavior

Use `VACUUM FULL` only with explicit approval and downtime planning because it takes an exclusive lock and rewrites the table.

## Backup

A backup design must specify:

- logical versus physical backup
- full and incremental strategy
- WAL archiving/PITR
- encryption
- off-host storage
- retention
- monitoring
- restore validation

For small homelab deployments, logical dumps can complement but not always replace physical/PITR backups.

Examples:

```bash
pg_dump --format=custom --file=db.dump database
pg_dumpall --globals-only > globals.sql
```

Avoid exposing passwords in process arguments; use `.pgpass`, environment injection, or secret tooling safely.

## Restore

Before restore:

- verify source backup and checksum
- identify target version compatibility
- restore into an isolated target when possible
- preserve current target data
- confirm extensions and roles
- estimate disk space
- define validation queries

A restore test must verify application-level correctness, not only command exit status.

## Docker considerations

- persist the database data directory in a named volume or intentional bind mount
- do not change PostgreSQL major image tags without a migration plan
- distinguish image upgrade from data-directory upgrade
- add health checks using `pg_isready`
- set shared memory appropriately
- avoid exposing port 5432 publicly without need
- back up outside the container lifecycle

## Validation

Run the narrowest relevant checks:

```bash
psql -X -v ON_ERROR_STOP=1
pg_restore --list backup.dump
pg_dump --schema-only
```

For migrations, validate on a representative non-production copy first.

## Expected output

For operational work, include SQL/commands, lock and downtime implications, backup prerequisite, rollback, and validation. Use [the output template](assets/output-template.md) and [the checklist](references/checklist.md).
