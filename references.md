# Authoritative external references

External sources this repo treats as authoritative for its **shared Terraform
modules**. Code, Terraform and tests must be reconciled with them; record
material drift in the ticket and update the affected doc (see
[`AGENTS.md`](AGENTS.md)).

Last reviewed: 2026-10-24.

## Terraform

| Source | Establishes | Used by |
| --- | --- | --- |
| [AWS provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) | Resource/argument semantics for every module. | all `modules/` |
| [Terraform tests](https://developer.hashicorp.com/terraform/language/tests) | `terraform test` + mocked providers used for the backup module. | `modules/aws-backup-dynamodb/tests/` |
| [Module providers / `configuration_aliases`](https://developer.hashicorp.com/terraform/language/modules/develop/providers) | Why the destination-region provider is supplied by the caller. | `modules/aws-backup-dynamodb/versions.tf` |

## AWS Backup & DynamoDB

| Source | Establishes | Used by |
| --- | --- | --- |
| [Cross-region backup](https://docs.aws.amazon.com/aws-backup/latest/devguide/cross-region-backup.html) | Copy actions and destination-vault behaviour. | `modules/aws-backup-dynamodb/main.tf` |
| [Advanced DynamoDB backup](https://docs.aws.amazon.com/aws-backup/latest/devguide/advanced-dynamodb-backup.html) | The account/region opt-in prerequisite the module documents. | `modules/aws-backup-dynamodb/` |
| [DynamoDB PITR](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/PointInTimeRecovery.html) | PITR is same-region only — the reason the module exists. | `modules/aws-backup-dynamodb/` |
| [AWS Backup vaults](https://docs.aws.amazon.com/aws-backup/latest/devguide/vaults.html) | Vault/KMS and (optional) vault-lock semantics. | `modules/aws-backup-dynamodb/` |

## Maintenance

- Add a row when a new provider/resource contract becomes load-bearing.
- Re-check on provider/AWS deprecations; update the date and the module README.
- Cite the entry in the module README where the behaviour is non-obvious (the opt-in prerequisite, provider aliases).
