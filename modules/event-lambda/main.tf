module "lambda" {
  source = "../lambda"

  handler                      = var.handler
  environment_variables        = var.environment_variables
  extra_policy_documents       = var.extra_policy_documents
  data_access_tables           = var.data_access_tables
  data_access_kms_keys         = var.data_access_kms_keys
  grant_scan                   = var.grant_scan
  data_access_read_only        = var.data_access_read_only
  data_access_read_only_tables = var.data_access_read_only_tables
  memory_size                  = var.memory_size
  timeout                      = var.timeout
  environment                  = var.environment
  name                         = var.name
  placeholder_source_dir       = var.placeholder_source_dir
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowEventBridgeRuleInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.function_arn
  qualifier     = module.lambda.alias_name
  principal     = "events.amazonaws.com"
  source_arn    = var.eventbridge_rule_arn
}

output "function_name" {
  value = module.lambda.function_name
}

output "function_arn" {
  value = module.lambda.function_arn
}

output "function_alias_arn" {
  value = module.lambda.function_alias_arn
}

output "role_arn" {
  value = module.lambda.role_arn
}
