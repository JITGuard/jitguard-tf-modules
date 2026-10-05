# Public Terraform Modules and the Retired Deploy Keys

Status: Accepted (2026-09)

## Context

The shared Lambda modules originally lived in `jitguard-core`, which is
private. Terraform's `git::https://` module fetch does not inherit the
credential header that `actions/checkout` sets, so a private module source
needed its own credential. The workaround was a read-only deploy key on
`jitguard-core` plus a `CORE_MODULE_KEY` secret holding the private half in
each consumer repo (`jitguard`, `jitguard-auth`, `jitguard-billing`). The
private half was deliberately unrecoverable, and there was no record of why the
keys existed, which repos held the secret, or how to rotate one.

Two problems followed. The keys were an undocumented credential with a
non-obvious rotation path, and the module source was a moving target: the
private halves existed only inside those three secrets, so it could not be
proven no fourth copy existed anywhere.

## Decision

- **Modules are public.** They moved to `barneyparker/jitguard-tf-modules`, a
  public repository, and every consumer references them by tag-less ref:
  `git::https://github.com/barneyparker/jitguard-tf-modules.git//modules/<name>?ref=main`.
  A public source needs no credential, so no deploy key and no secret are
  involved.
- **The deploy keys and secrets are retired.** The three read-only deploy keys
  on `jitguard-core` were deleted and `CORE_MODULE_KEY` was removed from all
  three consumer repos. `jitguard-admin`, `jitguard-web` and `jitguard-public`
  never had a key or secret.
- **The rotation procedure is therefore void.** There is nothing to rotate. If
  a private module dependency is ever reintroduced, it gets a fresh ticket that
  records the key, the secret location, and the rotation steps, following the
  precedent of ADR-0021.

## Consequences

- `?ref=main` means there is no pinned module version to roll back to. A
  module change reaches every consumer on its next `terraform init`. The deploy
  workflows run `terraform init -upgrade` because Terraform caches git modules
  per source string, so without it a moving ref stays on the last fetched
  commit.
- Consumers accept the module interface as a shared contract; a breaking module
  change is a cross-repo change. The `check-module-refs` guard fails CI on a
  local or private module source.
- The stale comments describing the old deploy-key URL rewrite were removed
  from the deploy workflows.
