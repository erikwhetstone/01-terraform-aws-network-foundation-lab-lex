# Terraform AWS Network Foundation Lab

Lab 1 of the Terraform AWS Security Training series.

This lab builds a reusable AWS network foundation with Terraform. You will create a VPC, two public subnets, two private subnets, an Internet Gateway, and route tables across two Availability Zones.

The network created here is designed to be reused by later labs rather than creating a new VPC for every exercise.

## Lab Goal

By the end of this lab, you will have deployed a basic multi-AZ AWS network using Terraform and will understand how AWS decides whether a subnet has a route to the Internet.

The completed network contains:

- One VPC
- Two Availability Zones
- Two public subnets
- Two private subnets
- One Internet Gateway
- One shared public route table
- Two private route tables
- Terraform outputs for reuse by later labs

A NAT Gateway is not deployed in the baseline lab.

## What You Will Learn

This lab introduces several foundational AWS and Terraform concepts:

- How IPv4 CIDR blocks define network address ranges
- How a VPC provides an isolated AWS network
- Why workloads are distributed across multiple Availability Zones
- The difference between public and private subnets
- How Internet Gateways provide Internet connectivity to a VPC
- How route tables control traffic paths
- Why attaching an Internet Gateway does not automatically make every subnet public
- How Terraform data sources discover information from AWS
- How Terraform variables separate configuration from architecture
- How Terraform checks can prevent unsafe deployments
- How provider default tags identify resource ownership
- How Terraform outputs expose information for later labs
- Why Terraform state must not be stored in Git

## Architecture

The baseline architecture is:

```text
                         Internet
                            |
                     Internet Gateway
                            |
                  Public Route Table
                     0.0.0.0/0
                            |
             +--------------+--------------+
             |                             |
       Public Subnet A               Public Subnet B
       10.42.10.0/24                 10.42.20.0/24
             |                             |
            AZ A                          AZ B
             |                             |
      Private Subnet A              Private Subnet B
      10.42.110.0/24                10.42.120.0/24
             |                             |
    Private Route Table            Private Route Table
             |                             |
       No default                    No default
      Internet route                Internet route

                   VPC: 10.42.0.0/16
```

The public subnets share a route table containing:

```text
0.0.0.0/0 -> Internet Gateway
```

The private route tables intentionally do not contain a default Internet route.

## Network Address Plan

| Network | CIDR |
|---|---|
| VPC | `10.42.0.0/16` |
| Public subnet A | `10.42.10.0/24` |
| Public subnet B | `10.42.20.0/24` |
| Private subnet A | `10.42.110.0/24` |
| Private subnet B | `10.42.120.0/24` |

The `/16` VPC provides a larger address range from which smaller `/24` subnet networks are allocated.

The lab deliberately keeps gaps between subnet ranges so the addressing scheme remains easy to read and leaves room for future expansion.

## What Makes a Subnet Public?

A subnet is not public merely because it exists inside a VPC with an Internet Gateway.

For this lab, a public subnet has both:

1. A route table containing a default route to the Internet Gateway.
2. Automatic public IPv4 assignment enabled for resources launched into the subnet.

The public route is:

```text
0.0.0.0/0 -> Internet Gateway
```

The private subnets do not receive this route.

This distinction is important because later labs can place Internet-facing components in public subnets while keeping application or database components in private subnets.

## Why There Is No NAT Gateway

The baseline lab deliberately does not deploy a NAT Gateway.

A NAT Gateway is useful when resources in a private subnet need outbound Internet access without accepting unsolicited inbound Internet connections. However, NAT Gateway usage introduces ongoing AWS charges.

Because this is a foundational networking lab, private subnets remain isolated from direct Internet routing.

An optional advanced NAT exercise may be introduced separately after its architecture and cost implications are explained.

## Security Decisions

Security is part of the lab design rather than an optional step added after deployment.

### AWS Account Guardrail

The lab uses:

```text
expected_aws_account_id
```

Terraform compares this value with the AWS account associated with the active credentials.

If the accounts do not match, the provider setting `allowed_account_ids` stops Terraform before any AWS changes are made. The `expected_aws_account` check in `checks.tf` also reports a readable warning, but check blocks alone never block an apply.

If this check fails, stop and do not approve the run. Always verify the target AWS account before applying changes.

### Credentials Are Not Stored in Source Code

AWS credentials must never be placed in:

- Terraform source files
- `terraform.tfvars`
- README examples
- Git commits
- screenshots
- Terraform plan files

Authentication is supplied outside the repository.

### Private Subnet Routing

Private subnet route tables have no default route to an Internet Gateway.

Later labs can use these subnets for resources that should not be directly Internet-facing.

### Auto Apply

Auto Apply should remain disabled in HCP Terraform.

Always review the Terraform plan before approving an apply.

The same principle applies to destruction: review the destroy plan before confirming removal.

### Resource Ownership

The AWS provider applies common tags so administrators can identify why a resource exists and who owns the deployment.

Common tags include:

```text
ManagedBy
Purpose
Project
Lab
Owner
DeploymentId
Environment
CreatedFrom
ExpiresOn
```

## Cost Estimate

The baseline Lab 1 architecture consists primarily of:

- VPC
- Subnets
- Route tables
- Route table associations
- Internet Gateway

These resources normally have no direct hourly charge by themselves.

However, AWS pricing can change and later resources placed into this network may incur charges.

The baseline lab therefore avoids optional paid networking services such as NAT Gateway.

Before public release, current pricing should be verified against official AWS pricing information.

See [COSTS.md](COSTS.md) for the detailed lab cost model.

## Prerequisites

Before beginning this lab, you should have:

- An AWS training or sandbox account
- Terraform installed
- Git installed
- Access to HCP Terraform
- A GitHub account
- Basic command-line familiarity
- AWS credentials appropriate for the training environment
- An AWS budget or other cost-monitoring process appropriate for your environment

You should also understand that Terraform state may contain infrastructure information and must not be committed to Git.

## Repository Structure

```text
01-terraform-aws-network-foundation-lab/
|-- .gitignore
|-- .terraform.lock.hcl
|-- README.md
|-- SECURITY.md
|-- COSTS.md
|-- TROUBLESHOOTING.md
|-- CHANGELOG.md
|-- LICENSE
|-- versions.tf
|-- provider.tf
|-- variables.tf
|-- data.tf
|-- locals.tf
|-- main.tf
|-- outputs.tf
|-- checks.tf
|-- examples/
|   |-- terraform.tfvars.example
|   `-- iam/
|       `-- training-policy.json
|-- docs/
|   |-- architecture.md
|   |-- concepts.md
|   |-- deployment-guide.md
|   `-- cleanup-guide.md
`-- diagrams/
    `-- architecture.png
```

## Terraform File Walkthrough

### `versions.tf`

Defines the supported Terraform version and AWS provider requirements.

This controls compatibility. It does not create AWS resources.

### `provider.tf`

Configures the AWS provider, selected region, and standard resource tags.

AWS credentials are intentionally not stored here.

### `variables.tf`

Defines configurable deployment values including:

```text
aws_region
expected_aws_account_id
owner_name
deployment_id
expiration_date
project_name
vpc_cidr
public_subnet_cidrs
private_subnet_cidrs
```

The default network configuration is:

```text
10.42.0.0/16
10.42.10.0/24
10.42.20.0/24
10.42.110.0/24
10.42.120.0/24
```

### `data.tf`

Reads information from AWS that Terraform does not create.

This lab reads:

- The authenticated AWS account identity
- Available Availability Zones

Availability Zones are discovered instead of hardcoding names such as `us-east-1a`.

### `locals.tf`

Contains calculated values used by the configuration, including:

- Lab naming
- Resource name prefixes
- Selected Availability Zones
- Combined subnet CIDR information
- Normalized subnet network addresses

### `main.tf`

Contains the AWS networking resources taught in this lab:

- VPC
- Internet Gateway
- Public subnets
- Private subnets
- Public route table
- Public Internet route
- Private route tables
- Route table associations

### `checks.tf`

Contains deployment guardrails.

Checks include:

- Authenticated AWS account versus expected account
- At least two available Availability Zones
- Unique subnet CIDRs
- Separation between public and private CIDRs
- Non-overlapping subnet networks
- Subnets contained within the selected VPC CIDR

### `outputs.tf`

Publishes information about the deployed network.

Important outputs include:

```text
vpc_id
vpc_cidr
public_subnet_ids
private_subnet_ids
public_subnet_cidrs
private_subnet_cidrs
availability_zones
internet_gateway_id
public_route_table_id
private_route_table_ids
```

Later labs can use these values rather than creating another VPC.

## Terraform State

Terraform state does not belong in Git.

The repository ignores:

```text
.terraform/
*.tfstate
*.tfstate.*
*.tfplan
tfplan
*.tfvars
*.tfvars.json
.terraformrc
terraform.rc
crash.log
```

The provider dependency lock file is different:

```text
.terraform.lock.hcl
```

This file should be committed so future runs use compatible provider selections.

For the training workflow, HCP Terraform owns shared Terraform state while GitHub stores source code.

## HCP Terraform Workspace Setup

Create an HCP Terraform workspace connected to this repository.

Keep the workspace private while developing and validating the lab.

Disable Auto Apply so every proposed infrastructure change must be reviewed before deployment.

Do not place environment-specific account identifiers or credentials into this repository.

### Terraform Variables

Configure deployment values as HCP Terraform variables.

Required values include:

| Variable | Purpose |
|---|---|
| `aws_region` | AWS Region used for the network |
| `expected_aws_account_id` | Expected target AWS account |
| `owner_name` | Learner or administrator identifier |
| `deployment_id` | Unique identifier for this deployment |
| `expiration_date` | Intended cleanup date |

The network CIDRs have training defaults but may also be configured through workspace variables when appropriate.

### AWS Authentication

AWS authentication should be configured outside Terraform source code.

For training environments using AWS access keys, authentication values may include environment variables such as:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

Do not commit these values.

The Terraform variable `aws_region` controls the provider region for this lab. If your authentication environment also defines AWS region variables, keep them consistent with the Terraform value.

Long-lived access keys are used only where appropriate for introductory training. A later advanced lab can replace them with workload identity and short-lived AWS credentials.

## IAM Permissions

Do not use `AdministratorAccess` simply to make the lab work.

The repository includes:

```text
examples/iam/training-policy.json
```

as a training baseline for the permissions needed by this lab.

The example policy must be reviewed for the learner's AWS environment before use. It is not intended to be treated as a universal production IAM policy.

See [SECURITY.md](SECURITY.md) for additional security guidance.

## Initialize Terraform

After cloning the repository:

```bash
terraform init
```

Terraform downloads the required providers and creates the local `.terraform/` working directory.

Then verify formatting:

```bash
terraform fmt -check -diff
```

Validate the configuration:

```bash
terraform validate
```

A valid configuration should report:

```text
Success! The configuration is valid.
```

## Review the Terraform Plan

For the normal training workflow, initiate a plan through HCP Terraform.

Before applying anything, review the plan carefully.

Confirm:

- The target AWS account is correct
- The target AWS Region is correct
- The VPC CIDR is expected
- Two public subnets are planned
- Two private subnets are planned
- Two Availability Zones are being used
- An Internet Gateway is planned
- Public routing points to the Internet Gateway
- Private route tables do not contain a default Internet route
- No NAT Gateway is planned
- Resource tags identify the deployment

Do not approve a plan simply because Terraform says it is syntactically valid.

## Apply

After reviewing the plan and confirming the target environment, approve the HCP Terraform run manually.

Auto Apply should remain disabled.

After the apply completes, record the Terraform outputs.

Do not manually create, modify, or delete lab resources in the AWS console unless the exercise explicitly instructs you to do so.

Terraform should remain the source of truth for resources created by the lab.

## Validate the Network

After a successful apply, inspect the AWS VPC configuration.

Confirm the VPC CIDR is:

```text
10.42.0.0/16
```

Confirm the public subnets use:

```text
10.42.10.0/24
10.42.20.0/24
```

Confirm the private subnets use:

```text
10.42.110.0/24
10.42.120.0/24
```

Confirm the subnet pairs are distributed across two Availability Zones.

### Public Routing

Inspect the public route table.

It should contain a route similar to:

```text
Destination: 0.0.0.0/0
Target:      Internet Gateway
```

Confirm both public subnets are associated with the public route table.

### Private Routing

Inspect both private route tables.

They should contain the VPC-local route but no:

```text
0.0.0.0/0 -> Internet Gateway
```

and no NAT Gateway route in the baseline lab.

## Terraform Outputs

View deployed outputs through HCP Terraform after a successful run.

The important reusable outputs are:

```text
vpc_id
vpc_cidr
public_subnet_ids
private_subnet_ids
```

These values form the interface between this lab and later infrastructure labs.

For example, a later EC2 lab can accept a VPC ID and public subnet ID as inputs rather than creating another network.

## Destroy

Infrastructure lifecycle management includes removal, not only creation.

When you are finished with the lab, queue a destroy plan in HCP Terraform.

Before confirming destruction, review the plan and ensure it targets only resources owned by this lab.

Do not manually delete Terraform-managed network resources before reviewing Terraform state.

After reviewing the destroy plan, confirm the destroy operation.

## Verify Cleanup

After Terraform reports a successful destroy:

1. Confirm the lab VPC has been removed.
2. Confirm the four lab subnets have been removed.
3. Confirm the Internet Gateway has been removed.
4. Confirm the lab route tables have been removed.
5. Confirm HCP Terraform state reflects the completed destruction.
6. Confirm no unexpected networking resources remain from the deployment.

Never assume that a successful command means cleanup is complete without validating the result.

## Troubleshooting

### Wrong AWS Account

If the account guardrail reports a mismatch, stop.

Verify the credentials configured for the HCP Terraform workspace and compare them with `expected_aws_account_id`.

Do not change the expected account simply to make the check pass unless you have confirmed that the new account is genuinely the intended training account.

### Fewer Than Two Availability Zones

This lab requires at least two available Availability Zones.

Verify the selected AWS Region and account environment.

### Invalid or Overlapping CIDRs

Verify that:

- Each subnet uses a `/24`
- The four subnet networks are unique
- Public and private subnet ranges do not overlap
- Every subnet resides inside the VPC CIDR

### Authentication Failures

Verify AWS credentials are configured in the HCP Terraform workspace or approved local authentication environment.

Do not copy credentials into Terraform files.

### Partial Apply Failure

Do not immediately delete resources manually.

Inspect the HCP Terraform run and Terraform state first. Terraform may already track resources created before the failure.

### Private Subnets Stay in Deleting After Lab 2

If your account uses Amazon GuardDuty Runtime Monitoring with automated EC2 agent management, GuardDuty creates its own VPC endpoint and security group in this VPC while a Lab 2 instance runs. Terraform does not manage them, and they block the private subnets and the VPC from deleting.

The removal commands are in the troubleshooting guide under the same heading.

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for additional guidance.

## What Comes Next

This network is intended to become the foundation for later labs.

The next lab can consume:

```text
vpc_id
public_subnet_ids
```

to place an EC2 workload into the network without silently creating another VPC.

[Lab 2 - EC2 Web](https://github.com/lshillingford/02-terraform-aws-ec2-web-lab) does exactly this: it deploys a hardened NGINX web server into one of these public subnets.

Future labs can also use the private subnet outputs for application and database tiers.

The important concept is that infrastructure layers now have an explicit relationship:

```text
Network Foundation
       |
       +--> Public workload tier
       |
       +--> Private application tier
       |
       `--> Private database tier
```

This allows the training series to evolve into a connected AWS architecture rather than a collection of unrelated Terraform examples.

## Important Reminder

This repository is designed for training.

Always:

- Review the plan before apply
- Keep Auto Apply disabled
- Use a dedicated training or sandbox AWS account
- Keep credentials out of Git
- Keep Terraform state out of Git
- Monitor AWS costs
- Understand a resource before deploying it
- Review the destroy plan before confirmation
- Validate cleanup when the lab is complete
