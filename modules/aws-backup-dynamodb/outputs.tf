output "plan_arn" {
  value       = aws_backup_plan.this.arn
  description = "ARN of the AWS Backup plan that schedules the backups."
}

output "plan_id" {
  value       = aws_backup_plan.this.id
  description = "ID of the AWS Backup plan."
}

output "source_vault_name" {
  value       = aws_backup_vault.source.name
  description = "Name of the source-region backup vault holding the primary recovery points."
}

output "source_vault_arn" {
  value       = aws_backup_vault.source.arn
  description = "ARN of the source-region backup vault."
}

output "destination_vault_name" {
  value       = aws_backup_vault.destination.name
  description = "Name of the destination-region backup vault holding the cross-region copies."
}

output "destination_vault_arn" {
  value       = aws_backup_vault.destination.arn
  description = "ARN of the destination-region backup vault."
}

output "backup_role_arn" {
  value       = aws_iam_role.this.arn
  description = "ARN of the IAM role AWS Backup assumes for backup and copy jobs."
}
