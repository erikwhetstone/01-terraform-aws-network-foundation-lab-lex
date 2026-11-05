# The current AWS identity feeds the readable account check in checks.tf.
# The blocking account guardrail is allowed_account_ids in provider.tf.
data "aws_caller_identity" "current" {}

# Availability Zones are discovered dynamically instead of hardcoding names
# such as us-east-1a, which can map differently between AWS accounts.
data "aws_availability_zones" "available" {
  state = "available"
}
