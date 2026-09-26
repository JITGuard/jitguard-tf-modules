variable "name" {
  type        = string
  description = "Function name used for resource naming and SERVICE_NAME (e.g. admin-customers, stripe-event-handler)."
}

variable "handler" {
  type        = string
  default     = "index.handler"
  description = "Lambda handler identifier."
}

variable "runtime" {
  type        = string
  default     = "nodejs24.x"
  description = "Lambda runtime identifier."
}

variable "architecture" {
  type        = string
  default     = "arm64"
  description = "Instruction set architecture."
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
  default     = 1024
  description = "Memory allocation in MB."
}

variable "timeout" {
  type        = number
  default     = 30
  description = "Function timeout in seconds."
}

variable "environment" {
  type        = string
  description = "Environment name used to resolve SSM parameters and derive the Lambda function name."
}

variable "data_access_tables" {
  type        = list(string)
  default     = []
  description = "DynamoDB table ARNs this Lambda may read/write directly (replaces customer-dynamodb role assumption)."
}

variable "data_access_read_only" {
  type        = bool
  default     = false
  description = "Restrict the data-access grant to reads (GetItem/Query) only — no PutItem/UpdateItem/DeleteItem. Set on GET-only handlers and triggers that never write."
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

variable "log_retention_days" {
  type        = number
  default     = 30
  description = "CloudWatch log group retention in days."
}

variable "data_access_read_only_tables" {
  type        = list(string)
  default     = []
  description = "Additional table ARNs this Lambda may READ ONLY (GetItem/Query, plus index access). Use for cross-service reads of another service's table."
}
