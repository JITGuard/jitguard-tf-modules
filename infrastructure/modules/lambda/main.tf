locals {
  # path.root (the consuming root module's `infrastructure/`), not path.module,
  # so the build output lands in the caller's .terraform/ even when this module
  # is loaded from a git ref (#1035).
  build_dir     = "${path.root}/.terraform"
  function_name = "${var.environment}-${var.name}"

  telemetry_env = {
    SERVICE_NAME = var.name
    ENVIRONMENT  = var.environment
  }
}

data "archive_file" "bundle" {
  type        = "zip"
  source_dir  = "${path.module}/dummy-bundle"
  output_path = "${local.build_dir}/${local.function_name}.zip"
}

resource "aws_iam_role" "this" {
  name = "${local.function_name}-role"

  assume_role_policy = data.aws_iam_policy_document.this_assume.json
}

data "aws_iam_policy_document" "this_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "permissions" {
  name = "permissions"
  role = aws_iam_role.this.name

  policy = data.aws_iam_policy_document.permissions.json
}

data "aws_iam_policy_document" "permissions" {
  override_policy_documents = var.extra_policy_documents

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["${aws_cloudwatch_log_group.this.arn}:*"]
  }

  statement {
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
    ]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = length(var.data_access_tables) > 0 ? [1] : []
    content {
      actions = var.data_access_read_only ? [
        "dynamodb:GetItem",
        "dynamodb:Query",
        ] : [
        "dynamodb:GetItem",
        "dynamodb:Query",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
      ]
      resources = concat(var.data_access_tables, [for t in var.data_access_tables : "${t}/index/*"])
    }
  }

  # Cross-service read-only access to another service table (e.g. the
  # promotion gate reading billing-owned plan/usage records in #1050).
  dynamic "statement" {
    for_each = length(var.data_access_read_only_tables) > 0 ? [1] : []
    content {
      actions = [
        "dynamodb:GetItem",
        "dynamodb:Query",
        "dynamodb:Scan",
      ]
      resources = concat(var.data_access_read_only_tables, [for t in var.data_access_read_only_tables : "${t}/index/*"])
    }
  }
  dynamic "statement" {
    for_each = var.grant_scan && length(var.data_access_tables) > 0 ? [1] : []
    content {
      actions = [
        "dynamodb:Scan",
      ]
      resources = concat(var.data_access_tables, [for t in var.data_access_tables : "${t}/index/*"])
    }
  }

  dynamic "statement" {
    for_each = length(var.data_access_kms_keys) > 0 ? [1] : []
    content {
      actions = var.data_access_read_only ? [
        "kms:Decrypt",
        ] : [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:GenerateDataKey",
      ]
      resources = var.data_access_kms_keys
    }
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = var.log_retention_days
}

resource "aws_lambda_function" "this" {
  filename         = data.archive_file.bundle.output_path
  function_name    = local.function_name
  role             = aws_iam_role.this.arn
  handler          = var.handler
  runtime          = var.runtime
  architectures    = [var.architecture]
  memory_size      = var.memory_size
  timeout          = var.timeout
  source_code_hash = data.archive_file.bundle.output_base64sha256
  publish          = true

  logging_config {
    # Powertools already emits JSON; Lambda passes it through unwrapped so the
    # { $.step = ... } metric filters in metric-filters.tf keep matching.
    log_format = "JSON"
    log_group  = aws_cloudwatch_log_group.this.name
  }

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = merge(var.environment_variables, local.telemetry_env)
  }

  lifecycle {
    # Code is deployed out-of-band (backend/scripts/deploy-lambdas.sh updates
    # $LATEST, publishes a version, moves the `live` alias). Ignore the code
    # inputs so Terraform never overwrites the deployed bundle with the dummy
    # one. Do NOT list computed attributes (version, qualified_arn,
    # qualified_invoke_arn, source_code_size, last_modified): ignore_changes
    # only applies to configured arguments, so those entries are no-ops that
    # emit "Redundant ignore_changes element" warnings.
    ignore_changes = [
      filename,
      source_code_hash,
    ]
  }

  depends_on = [
    aws_cloudwatch_log_group.this,
    aws_iam_role_policy.permissions,
  ]
}

resource "aws_lambda_alias" "live" {
  name             = "live"
  description      = "Live alias — updated on each deployment"
  function_name    = aws_lambda_function.this.arn
  function_version = aws_lambda_function.this.version

  lifecycle {
    ignore_changes = [
      function_version,
    ]
  }
}
