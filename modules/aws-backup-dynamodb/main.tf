# Cross-region DynamoDB backups (#1352).
#
# PITR is same-region only, so a full region loss has no restore path. This
# module backs each table in the source region on a schedule and copies every
# recovery point into a second region's vault, so losing the primary region is
# recoverable from the copy.
#
# The destination vault is created by a provider alias the caller passes in
# (`providers = { aws.destination = aws.dr }`). A module cannot declare a
# provider, only a `configuration_aliases` entry (versions.tf), so the caller
# owns the destination provider config.
#
# PREREQUISITE (not managed here, deliberately): cross-region copy of DynamoDB
# recovery points requires AWS Backup "advanced DynamoDB backup" to be enabled
# in BOTH regions of the account. It is an account+region singleton
# (`aws backup update-region-settings --resource-type-opt-in-preference
# DynamoDB=true --resource-type-management-preference DynamoDB=true`), which is
# why this module does not manage `aws_backup_region_settings`: a per-domain
# module would have several consumers fighting over one account-wide resource,
# and the resource is notorious for perpetual diffs (the supported resource-type
# list differs per region). The account owner enables it once; see the consuming
# repo's CONTEXT for the operational step.

locals {
  name_prefix = "${var.environment}-${var.name}"

  # A copy may outlive the source point; default to the same window unless the
  # caller asks otherwise.
  copy_retention_days = coalesce(var.copy_retention_days, var.retention_days)

  # Customer-managed keys the backup role must use: the vault keys, when
  # supplied. The permissions to read the *source tables* (which are encrypted
  # with the shared customer-data key) come from
  # AWSBackupServiceRolePolicyForBackup, whose DynamoDB KMS statement is scoped
  # to kms:ViaService dynamodb.*.amazonaws.com, so table keys are not listed.
  kms_key_arns = compact([
    var.vault_kms_key_arn,
    var.destination_vault_kms_key_arn,
  ])
}

data "aws_caller_identity" "current" {}

# Read the region behind the caller's `aws.destination` alias so the
# `destination_region` input can be checked against it below.
data "aws_region" "destination" {
  provider = aws.destination
}

resource "aws_backup_vault" "source" {
  name        = "${local.name_prefix}-backup-vault"
  kms_key_arn = var.vault_kms_key_arn
}

resource "aws_backup_vault" "destination" {
  provider    = aws.destination
  name        = "${local.name_prefix}-backup-vault"
  kms_key_arn = var.destination_vault_kms_key_arn

  lifecycle {
    # A destination_region that disagrees with the aliased provider would send
    # copies somewhere the caller does not expect, and only surface on restore.
    precondition {
      condition     = data.aws_region.destination.region == var.destination_region
      error_message = "destination_region '${var.destination_region}' must match the region configured on the aws.destination provider alias ('${data.aws_region.destination.region}')."
    }
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${local.name_prefix}-backup-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# AWS Backup's own service-role policies carry the per-service backup and
# restore actions (and the DynamoDB table decryption) that a hand-rolled policy
# would have to track as AWS adds actions.
resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# Only when a customer-managed vault key is supplied: the managed policies do
# not cover an arbitrary CMK the caller names, so grant the role use of exactly
# those keys. With the default `aws/backup` keys this policy does not exist and
# no key reference is made.
data "aws_iam_policy_document" "vault_keys" {
  count = length(local.kms_key_arns) > 0 ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:ReEncryptFrom",
      "kms:ReEncryptTo",
      "kms:DescribeKey",
      "kms:CreateGrant",
    ]
    resources = local.kms_key_arns
  }
}

resource "aws_iam_role_policy" "vault_keys" {
  count = length(local.kms_key_arns) > 0 ? 1 : 0

  name   = "vault-keys"
  role   = aws_iam_role.this.name
  policy = data.aws_iam_policy_document.vault_keys[0].json
}

resource "aws_backup_plan" "this" {
  name = "${local.name_prefix}-dynamodb-backup"

  rule {
    rule_name         = "cross-region-daily"
    target_vault_name = aws_backup_vault.source.name
    schedule          = var.schedule
    start_window      = var.start_window
    completion_window = var.completion_window

    lifecycle {
      delete_after = var.retention_days
    }

    copy_action {
      destination_vault_arn = aws_backup_vault.destination.arn

      lifecycle {
        delete_after = local.copy_retention_days
      }
    }
  }
}

resource "aws_backup_selection" "this" {
  name         = "${local.name_prefix}-dynamodb-tables"
  iam_role_arn = aws_iam_role.this.arn
  plan_id      = aws_backup_plan.this.id

  resources = var.tables
}
