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
}

resource "aws_iam_role_policy" "sqs_poll" {
  name = "${module.lambda.function_name}-sqs-poll"
  role = module.lambda.role_name

  policy = data.aws_iam_policy_document.sqs_poll.json
}

data "aws_iam_policy_document" "sqs_poll" {
  statement {
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
    ]
    resources = [var.sqs_queue_arn]
  }
}

resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn = var.sqs_queue_arn
  function_name    = module.lambda.function_alias_arn
  batch_size       = 1
  enabled          = var.enabled

  depends_on = [aws_iam_role_policy.sqs_poll]
}

resource "aws_lambda_permission" "sqs" {
  statement_id  = "AllowSQSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.function_arn
  qualifier     = module.lambda.alias_name
  principal     = "sqs.amazonaws.com"
  source_arn    = var.sqs_queue_arn
}

output "function_name" {
  value = module.lambda.function_name
}

output "log_group_name" {
  value = module.lambda.log_group_name
}

output "function_arn" {
  value = module.lambda.function_arn
}

output "role_arn" {
  value = module.lambda.role_arn
}

output "role_name" {
  value = module.lambda.role_name
}
