# Changelog

All notable changes to this lab are documented in this file.

The format is based on Keep a Changelog, and this lab uses semantic versioning.

## [Unreleased]

This version is in private development. It has completed the HCP Terraform plan, apply, validate, and destroy lifecycle test with Terraform 1.17.1 and AWS provider 6.x, and is pending release review.

### Added

- VPC with a `10.42.0.0/16` default address plan.
- Two public and two private subnets across two Availability Zones.
- Internet Gateway with a shared public route table.
- Per-subnet private route tables with no default Internet route.
- Outputs for VPC, subnet, route table, and Internet Gateway identifiers.
- Standard training tags applied through provider `default_tags`.
- Input validation for account ID, CIDR blocks, and required deployment values.
- Account guardrail using provider `allowed_account_ids`, with a readable check in `checks.tf`.
- Training baseline IAM policy in `examples/iam/training-policy.json`.
- README, SECURITY, COSTS, and TROUBLESHOOTING documentation.
- Architecture, concepts, deployment, and cleanup guides in `docs/`.
- Architecture diagram in `diagrams/architecture.png`.

### Fixed

- The subnet containment check no longer uses `cidrcontains`, which is not available in Terraform 1.17.1.
- The training IAM policy now allows `ec2:DescribeNetworkInterfaces`, which subnet deletion requires.

### Not Included

- NAT Gateway. Omitted from the baseline to avoid recurring charges.
