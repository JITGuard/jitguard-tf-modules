# Minimal, static-only example for the cross-region DynamoDB backup module.
#
# The example exists so CI can validate the module: the module requires the
# caller to pass an `aws.destination` provider alias, and a bare module
# directory cannot validate on its own because the alias has no configuration.
# Validating this root exercises the module's variables, resources and
# provider wiring without touching AWS.
#
# Replace the placeholder table ARN when wiring this into a real stack.

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

provider "aws" {
  alias  = "destination"
  region = "eu-central-1"
}

module "backup" {
  source = "../../"

  providers = {
    aws.destination = aws.destination
  }

  name               = "example"
  environment        = "dev"
  destination_region = "eu-central-1"

  tables = ["arn:aws:dynamodb:eu-west-1:111122223333:table/example"]
}

output "plan_arn" {
  value       = module.backup.plan_arn
  description = "ARN of the example backup plan."
}
