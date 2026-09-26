# Built-in TFLint rules only (Terraform-language checks: deprecated syntax,
# unused declarations, invalid references). The `aws` ruleset is added in CI
# where the tflint binary is current — this pinned local version predates the
# plugin's protocol, so loading the aws plugin here fails.
#
# CI pins tflint v0.64.0, not the v0.39.3 the consuming repos use. That is
# deliberate and not cosmetic: these modules use `optional(type, default)`,
# and v0.39.3's bundled HCL parser rejects the two-argument form outright
# ("Optional attribute modifier expects only one argument"), so it cannot parse
# api-lambda/variables.tf at all. Verified against both binaries.

rule "terraform_required_version" {
  # True finding, deliberately not fixed yet.
  #
  # These modules use `optional()`, which needs Terraform >= 1.3, but declare no
  # floor — so a consumer on 1.2 gets a parse error deep inside a variable type
  # rather than a clear version message. The fix is one `versions.tf` per module
  # (`required_version = ">= 1.3"`), plus `required_providers` for aws and
  # archive. That is a change to module *content*, so it is not being made
  # silently as part of moving the modules out of jitguard-core.
  #
  # Consumers are on Terraform 1.14.0 with aws `~> 6.0`, so `>= 1.3` and
  # `>= 6.0` would be safe floors when this is done.
  enabled = false
}

rule "terraform_required_providers" {
  # See above — same change, same reason for deferring.
  enabled = false
}
