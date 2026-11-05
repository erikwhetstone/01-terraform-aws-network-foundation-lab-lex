# Changelog

All notable changes to this lab are documented in this file.

The format is based on Keep a Changelog, and this lab uses semantic versioning.

## [Unreleased]

This version is in private development. It has not yet completed the HCP Terraform plan, apply, validate, and destroy lifecycle test and is not released.

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

### Not Included

- NAT Gateway. Omitted from the baseline to avoid recurring charges.
