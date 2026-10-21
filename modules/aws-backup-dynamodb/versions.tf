terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # `configuration_aliases` is why this module carries a versions.tf at all:
      # the destination-region vault must be created by a second provider, and a
      # module can only *declare* the alias it expects the caller to pass.
      version               = ">= 6.0"
      configuration_aliases = [aws.destination]
    }
  }
}
