# Changelog

All notable changes to this lab are documented in this file.

The format is based on Keep a Changelog, and this lab uses semantic versioning.

## [1.0.1] - 2026-11-09

### Changed

- Repository renamed to `01-terraform-aws-network-foundation-lab` so the series repositories sort in curriculum order.
- The deployment guide now links to the Lab 0 curriculum repository.

## [1.0.0] - 2026-11-06

First release. Tested through the full HCP Terraform plan, apply, validate, re-plan, and destroy lifecycle with Terraform 1.17.1 and AWS provider 6.x.

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
