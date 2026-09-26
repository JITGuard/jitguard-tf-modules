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

resource "aws_apigatewayv2_integration" "this" {
  api_id                 = var.api_id
  integration_type       = "AWS_PROXY"
  integration_uri        = module.lambda.function_alias_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "this" {
  for_each           = var.routes
  api_id             = var.api_id
  route_key          = each.key
  target             = "integrations/${aws_apigatewayv2_integration.this.id}"
  authorization_type = each.value.authorization_type
  authorizer_id      = each.value.authorizer_id
}

resource "aws_lambda_permission" "this" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.function_arn
  qualifier     = module.lambda.alias_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_execution_arn}/*/*"
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

output "route_ids" {
  value = values(aws_apigatewayv2_route.this)[*].id
}

output "integration_id" {
  value = aws_apigatewayv2_integration.this.id
}

output "role_arn" {
  value = module.lambda.role_arn
}
