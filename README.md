# jitguard-tf-modules

Terraform modules for [jitguard](https://github.com/JITGuard/jit-guard), a SaaS for
just-in-time AWS access.

These modules are **generic**. Account IDs, ARNs, regions, environments, table names and
every other account-specific value are supplied by the consuming repository through module
inputs. Nothing here is tied to an AWS account, and nothing here reads credentials — this
repository is public and its CI has no AWS access.

## Consuming

```
source = "git::https://github.com/JITGuard/jitguard-tf-modules.git//modules/lambda?ref=main"
```

The path is `//modules/<name>`.

### `?ref=main`, not a tag

Track `main`. The modules are consumed by Terraform that applies on every merge, and a
pinned tag means a module fix only reaches consumers when someone remembers to cut a
release. Consumers are expected to pair this with two things, or the policy silently
regresses:

- `terraform init -upgrade` in CI, or a stale module cache serves the previous module.
- A guard that rejects any `source` whose ref is not `main`.

`jitguard` carries that guard in `scripts/check-module-refs.mjs`, and disables tflint's
`terraform_module_pinned_source` rule with a documented reason so the two do not fight.

## Modules

| Module | Purpose |
|---|---|
| `modules/lambda` | Base function: IAM, log group, alias, env, optional VPC |
| `modules/api-lambda` | Lambda behind API Gateway, wired to routes |
| `modules/event-lambda` | Lambda triggered by an EventBridge rule |
| `modules/sqs-lambda` | Lambda consuming an SQS queue |

Each is a single-purpose wrapper over `modules/lambda`, adding only what its trigger needs.

## A note on `filename`

By decision, these modules deliberately do **not** set `filename` or `source_code_hash`.
Terraform owns the function, role, logs, environment and alias; code is published
out-of-band by a repo-local deploy script that moves the `live` alias. This keeps a handler
tweak from requiring a Terraform apply, and keeps Terraform from being a second writer of
the function. `ignore_changes = [filename, source_code_hash]` is the mechanism that makes
that work: it stops Terraform from overwriting the deployed bundle with the placeholder.

The module ships **no placeholder bundle of its own**. `modules/lambda` generates a
pathless one-line Node placeholder in-config, which is enough for the initial create before
the first out-of-band deploy. If a function uses a non-Node runtime, or you would rather
keep the placeholder in your own repository, set `placeholder_source_dir` to a directory
containing a suitable `index.mjs`. The `api-lambda`, `event-lambda` and `sqs-lambda`
wrappers forward the same input.

## Changing a module

A change here lands in every consumer on their next `init -upgrade`. Consumer `main` is
expected to stay deployable at all times, so treat a module change as a change to every
repo that consumes it: check the plans in this repo's dependents before merging.
