variable "name" {
  type        = string
  description = "Domain or service name used to name the vault, plan and role (e.g. core, billing). Combined with environment as <environment>-<name>."

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name))
    error_message = "name must be lowercase alphanumeric or hyphens so it is valid in an AWS Backup vault name."
  }
}

variable "environment" {
  type        = string
  description = "Environment name (e.g. dev, prod)."
}

variable "tables" {
  type        = list(string)
  description = "DynamoDB table ARNs to back up. Each is backed up in the source region, then copied to the destination vault."

  validation {
    condition     = length(var.tables) > 0
    error_message = "At least one table ARN is required: a backup plan whose selection has no resources backs up nothing."
  }
}

variable "destination_region" {
  type        = string
  description = "Region the aws.destination provider alias is configured for. Must match that provider; a precondition fails the plan otherwise."
}

variable "schedule" {
  type        = string
  default     = "cron(0 2 * * ? *)"
  description = "Backup schedule, in AWS Backup cron format (six fields). Defaults to daily at 02:00 UTC."
}

variable "retention_days" {
  type        = number
  default     = 35
  description = "Days a recovery point is kept in the source vault before it expires."
}

variable "copy_retention_days" {
  type        = number
  default     = null
  description = "Days a recovery point is kept in the destination vault. Defaults to retention_days when unset."
}

variable "start_window" {
  type        = number
  default     = 60
  description = "Minutes after the scheduled start that a backup job must begin."
}

variable "completion_window" {
  type        = number
  default     = 180
  description = "Minutes after the scheduled start that a backup job must finish."
}

variable "vault_kms_key_arn" {
  type        = string
  default     = null
  description = <<-EOT
    KMS key that encrypts recovery points in the source vault. Leave null to use
    the AWS-managed `aws/backup` key, which needs no key in any other region and
    keeps cross-region copies working out of the box. Set a customer-managed key
    only if you also manage it in the destination region, and expect the module
    to grant the backup role use of it.
  EOT
}

variable "destination_vault_kms_key_arn" {
  type        = string
  default     = null
  description = <<-EOT
    KMS key that encrypts recovery points copied into the destination vault. Leave
    null to use the AWS-managed `aws/backup` key in the destination region. AWS
    Backup re-encrypts every copy with the destination vault key, so a
    customer-managed key here must exist in destination_region.
  EOT
}
