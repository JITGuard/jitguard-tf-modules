# Plan-level tests for the cross-region DynamoDB backup module (#1352).
#
# Provider mocks keep this offline: the assertions are about the shape of the
# plan (a copy action into the destination vault, retention windows, table
# selection), not about AWS behaviour at apply time. The account owner still
# enables AWS Backup advanced DynamoDB backup in both regions; see main.tf.

mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "111122223333"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "eu-west-1"
    }
  }

  # Mocks do not render the real policy document, so supply valid JSON that
  # satisfies the IAM role's assume_role_policy validation.
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  # Mock values are validated like real ones; a generated value is not a valid
  # ARN, so give the source vault one.
  mock_resource "aws_backup_vault" {
    defaults = {
      arn = "arn:aws:backup:eu-west-1:111122223333:backup-vault:dev-core-backup-vault"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::111122223333:role/dev-core-backup-role"
    }
  }
}

mock_provider "aws" {
  alias = "destination"

  mock_data "aws_region" {
    defaults = {
      region = "eu-central-1"
    }
  }

  mock_resource "aws_backup_vault" {
    defaults = {
      arn = "arn:aws:backup:eu-central-1:111122223333:backup-vault:dev-core-backup-vault"
    }
  }
}

run "copies_every_recovery_point_to_the_destination_vault" {
  command = apply

  variables {
    name               = "core"
    environment        = "dev"
    tables             = ["arn:aws:dynamodb:eu-west-1:111122223333:table/dev-core-customer-audit"]
    destination_region = "eu-central-1"
    retention_days     = 14
  }

  assert {
    condition     = length(aws_backup_plan.this.rule) == 1
    error_message = "The plan must have exactly one rule."
  }

  assert {
    condition     = one([for r in aws_backup_plan.this.rule : one([for c in r.copy_action : c.destination_vault_arn])]) == aws_backup_vault.destination.arn
    error_message = "The rule must copy recovery points into the destination-region vault."
  }

  assert {
    condition     = one([for r in aws_backup_plan.this.rule : one([for l in r.lifecycle : l.delete_after])]) == 14
    error_message = "Source recovery points must expire after retention_days."
  }

  assert {
    condition     = one([for r in aws_backup_plan.this.rule : one([for c in r.copy_action : one([for l in c.lifecycle : l.delete_after])])]) == 14
    error_message = "The copy retention must default to retention_days."
  }

  assert {
    condition     = aws_backup_selection.this.resources == toset(["arn:aws:dynamodb:eu-west-1:111122223333:table/dev-core-customer-audit"])
    error_message = "The selection must contain exactly the tables passed in."
  }

  assert {
    condition     = aws_backup_selection.this.iam_role_arn == aws_iam_role.this.arn
    error_message = "The selection must run as the module-created backup role."
  }
}

run "copy_retention_can_outlive_the_source" {
  command = apply

  variables {
    name                = "core"
    environment         = "dev"
    tables              = ["arn:aws:dynamodb:eu-west-1:111122223333:table/dev-core-customer-audit"]
    destination_region  = "eu-central-1"
    retention_days      = 14
    copy_retention_days = 90
  }

  assert {
    condition     = one([for r in aws_backup_plan.this.rule : one([for l in r.lifecycle : l.delete_after])]) == 14
    error_message = "The source window must stay at retention_days."
  }

  assert {
    condition     = one([for r in aws_backup_plan.this.rule : one([for c in r.copy_action : one([for l in c.lifecycle : l.delete_after])])]) == 90
    error_message = "The copy window must honour copy_retention_days."
  }
}
