output "function_name" {
  value = aws_lambda_function.this.function_name
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.this.name
}

output "function_arn" {
  value = aws_lambda_function.this.arn
}

output "function_alias_arn" {
  value = aws_lambda_alias.live.arn
}

output "alias_name" {
  value = aws_lambda_alias.live.name
}

output "function_qualified_arn" {
  value = aws_lambda_function.this.qualified_arn
}

output "role_arn" {
  value = aws_iam_role.this.arn
}

output "role_name" {
  value = aws_iam_role.this.name
}