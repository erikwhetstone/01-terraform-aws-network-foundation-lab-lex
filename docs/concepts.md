# Concepts

This document explains the Terraform and AWS networking concepts used in the Network Foundation Lab. It focuses on why things work the way they do. For what the lab builds, see `architecture.md`.

## Declarative Infrastructure

Terraform is declarative. The configuration describes the desired end state, such as one VPC with four subnets, rather than a list of steps to run.

Terraform compares that desired state with what it already manages and works out the changes needed. Running the same configuration twice should produce no changes the second time.

## Providers

A provider is the plugin Terraform uses to talk to a platform's API. This lab uses the `hashicorp/aws` provider, pinned in `versions.tf`:

```hcl
version = "~> 6.0"
```

The `~>` constraint allows newer 6.x releases but not 7.0, which could contain breaking changes. The exact version installed is recorded in `.terraform.lock.hcl`, which is why that file is committed.

## Resources and Data Sources

A **resource** is something Terraform creates and owns, such as `aws_vpc.this`. Destroying the configuration deletes it.

A **data source** reads something Terraform does not own. This lab uses two:

- `aws_caller_identity` reads which AWS account the credentials belong to.
- `aws_availability_zones` reads which zones are available in the region.

Data sources never create or delete anything.

## Variables, Validation, and Locals

**Variables** are inputs. They let the same code deploy into any learner's account without editing source files.

**Validation blocks** reject bad input before Terraform contacts AWS. For example, `expected_aws_account_id` must be exactly 12 digits, and every subnet must be a /24.

**Locals** are calculated values. This lab uses them to build the resource name prefix, select two Availability Zones, and combine subnet lists for the overlap checks.

## Implicit Dependencies

Terraform works out creation order from references. Because each subnet sets `vpc_id = aws_vpc.this.id`, Terraform knows the VPC must exist first.

On destroy, the order reverses: associations and routes are removed before route tables, subnets before the VPC.

No `depends_on` is needed in this lab because every dependency is expressed through a reference.

## count and Splat Expressions

`count` creates several copies of one resource from a single block. Both subnet groups use:

```hcl
count = length(var.public_subnet_cidrs)
```

Each copy has an index, such as `aws_subnet.public[0]` and `aws_subnet.public[1]`.

The splat expression `aws_subnet.public[*].id` collects an attribute from every copy into a list. The outputs use this to return both subnet IDs at once.

## Outputs

Outputs publish values after an apply. In this lab they serve two purposes:

- Later labs consume `vpc_id`, `public_subnet_ids`, and `private_subnet_ids` instead of creating their own network.
- The remaining outputs let you check that what was deployed matches the design.

## Default Tags

The provider's `default_tags` block applies the standard tag set to every taggable resource automatically. Individual resources only add what is specific to them, such as `Name` and `Tier`.

This keeps tagging consistent and makes it impossible to forget the ownership and expiration tags on a new resource.

## Guardrails: Validation, Checks, and Provider Settings

Terraform offers several ways to catch mistakes, and they do not all behave the same way:

| Mechanism | Where | Blocks the run? |
|---|---|---|
| Variable validation | `variables.tf` | Yes, before contacting AWS |
| Provider `allowed_account_ids` | `provider.tf` | Yes, before any AWS change |
| `check` block | `checks.tf` | No, reports a warning only |

This lab uses all three. The account check in `checks.tf` gives a readable message, but the enforcing control is `allowed_account_ids`. A `check` block on its own must never be relied on to stop a deployment.

## State

Terraform records every resource it manages in a state file, mapping each Terraform address to a real AWS ID. Without state, Terraform cannot know which VPC is "its" VPC.

In this series, HCP Terraform stores state for each workspace. State is never committed to Git because it contains resource IDs, addresses, and potentially sensitive values.

If state and AWS disagree, fix it through Terraform. Deleting resources manually in the console leaves state pointing at things that no longer exist.

## Plan, Apply, and Destroy

- **Plan** shows exactly what Terraform intends to create, change, or delete. Nothing changes in AWS.
- **Apply** carries out a reviewed plan.
- **Destroy** is a plan that removes everything the workspace manages, followed by an apply.

Auto Apply stays disabled in this series so that every plan and every destroy plan is reviewed by a person before it runs.

## HCP Terraform Remote Execution

With a VCS-connected workspace, HCP Terraform runs plans and applies on its own infrastructure, not on your workstation. Credentials and variables are stored in the workspace, not on disk or in Git.

Workspace variables come in two categories:

| Category | Used for | Examples |
|---|---|---|
| Environment variable | Provider authentication | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` |
| Terraform variable | Inputs declared in `variables.tf` | `aws_region`, `expected_aws_account_id` |

Terraform source describes the architecture. Terraform variables describe the target environment. Environment variables authenticate the deployment.

## CIDR Blocks

A CIDR block describes a range of IP addresses. The number after the slash is how many leading bits are fixed:

- `/16` fixes 16 bits, leaving 65,536 addresses.
- `/24` fixes 24 bits, leaving 256 addresses.

Every subnet must fall inside the VPC range, and subnets in the same VPC must not overlap.

## Availability Zones

An Availability Zone is one or more physically separate data centers within a region. Spreading subnets across two zones means a failure in one zone does not take down everything.

Zone names such as `us-east-1a` can map to different physical zones in different AWS accounts, which is why this lab discovers zones with a data source instead of hardcoding them.

## Route Tables and the Internet Gateway

A route table decides where traffic leaving a subnet goes. Every route table includes a local route for the VPC range, so all subnets can reach each other.

An Internet Gateway is the VPC's connection to the Internet. It does nothing by itself. A subnet only reaches the Internet when its route table sends `0.0.0.0/0` to the gateway.

## What Makes a Subnet Public or Private

AWS has no "public subnet" setting. A subnet is public because of its routing:

- **Public:** its route table has a default route to an Internet Gateway.
- **Private:** its route table has no route to the Internet.

A resource in a public subnet also needs a public IP address and a security group that allows the traffic. Routing alone does not expose anything.

## NAT Gateways

A NAT Gateway lets resources in private subnets start outbound connections to the Internet, such as downloading updates, without being reachable from it.

This lab omits it because it bills hourly while it exists, even with no traffic. Private subnets in this lab therefore have no Internet access at all. Later labs that need AWS service access from private subnets use VPC endpoints instead.
