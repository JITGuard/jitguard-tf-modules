variable "handler" {
  type        = string
  default     = "index.handler"
  description = "Lambda handler identifier."
}

variable "environment_variables" {
  type        = map(string)
  default     = {}
  description = "Environment variables injected into the function."
}

variable "extra_policy_documents" {
  type        = list(string)
  default     = []
  description = "Additional IAM policy document JSON strings merged into the role policy via override_policy_documents."
}

variable "memory_size" {
  type        = number
  default     = 128
  description = "Memory allocation in MB."
}

variable "timeout" {
  type        = number
  default     = 30
  description = "Function timeout in seconds."
}

variable "eventbridge_rule_arn" {
  type        = string
  description = "ARN of the EventBridge rule to grant invoke permission to."
}

variable "environment" {
  type        = string
  description = "Environment name used to resolve SSM parameters and name resources."
}

variable "name" {
  type        = string
  description = "Function name (e.g. billing-scheduler, full-sync-worker)."
}

variable "data_access_tables" {
  type        = list(string)
  default     = []
  description = "DynamoDB table ARNs this Lambda may read/write directly."
}

variable "data_access_read_only" {
  type        = bool
  default     = false
  description = "Restrict data-access grant to reads (GetItem/Query) only."
}

variable "grant_scan" {
  type        = bool
  default     = false
  description = "Grant dynamodb:Scan on the data-access tables. Only Lambdas with legitimate cross-tenant reads should enable this."
}

variable "data_access_kms_keys" {
  type        = list(string)
  default     = []
  description = "KMS key ARNs used to encrypt the data-access tables. Grants kms:Decrypt (and kms:GenerateDataKey for writes) so the Lambda can read/write SSE-KMS DynamoDB tables."
}

variable "data_access_read_only_tables" {
  type        = list(string)
  default     = []
  description = "Additional table ARNs this Lambda may READ ONLY (GetItem/Query). Use for cross-service reads."
}
