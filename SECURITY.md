# Security Guidance

This document explains the security design of the Terraform AWS Network Foundation Lab.

Lab 1 is a training environment. Its controls are designed to teach secure infrastructure practices while keeping the network understandable, reusable, and cost-conscious.

The example IAM policy included with this repository is a training baseline. It is not a universal production IAM policy.

## Security Objectives

Lab 1 follows these principles:

- Use least-privilege AWS permissions.
- Keep AWS credentials outside source code.
- Keep Terraform state outside Git.
- Detect accidental use of the wrong AWS account.
- Separate public and private network paths.
- Avoid exposing workloads unnecessarily.
- Require human review before infrastructure changes.
- Identify deployed resources through standard tags.
- Keep Auto Apply disabled.
- Review destroy operations before confirmation.
- Avoid unnecessary paid networking resources.

## Deployment Identity

The lab should be deployed by an AWS identity with only the permissions necessary to manage the networking resources defined by this repository.

The example policy is located at:

```text
examples/iam/training-policy.json
```

It provides a training baseline for:

- Reading AWS caller identity.
- Reading Availability Zones and VPC networking information.
- Creating and deleting the training VPC.
- Creating and deleting subnets.
- Managing the Internet Gateway.
- Managing route tables, routes, and associations.
- Managing resource tags.

The recommended policy must not rely on:

```text
AdministratorAccess
```

or:

```text
ec2:*
```

During private testing, if the AWS provider requires an additional permission, identify the exact AWS API action that failed and add only that action when justified.

The policy must be tested through the full lifecycle:

```text
Plan -> Apply -> Refresh -> Destroy
```

## Credential Storage

AWS credentials must not be stored in this repository.

Do not place credentials in:

- `provider.tf`
- `variables.tf`
- `terraform.tfvars`
- Markdown documentation
- committed shell scripts
- screenshots
- Terraform plans
- Terraform state

For introductory training with static AWS credentials, HCP Terraform workspace environment variables may include:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

Actual credential values must be marked sensitive and must never enter Git history.

Long-lived access keys are an introductory training mechanism only. A later advanced lab replaces static credentials with HCP Terraform workload identity, AWS IAM trust, AWS STS, and short-lived credentials.

## Terraform State

Terraform state can contain:

- Resource IDs
- IP addresses
- Generated resource names
- Infrastructure relationships
- Configuration values
- Potentially sensitive information

Terraform state therefore must not be committed to Git.

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
crash.*.log
```

The provider dependency lock file is different:

```text
.terraform.lock.hcl
```

The lock file should be committed because it records provider selections rather than deployed infrastructure state.

The normal training workflow is:

```text
GitHub
  |
  +-- Terraform source code
  |
HCP Terraform
  |
  +-- Remote Terraform runs
  +-- Terraform state
  |
AWS training account
```

HCP Terraform owns shared Terraform state. GitHub owns source code.

## Wrong-Account Protection

The lab requires:

```text
expected_aws_account_id
```

Terraform reads the authenticated AWS account through:

```text
data.aws_caller_identity.current
```

and compares it with the expected account.

If the values do not match, the provider setting `allowed_account_ids` stops Terraform before any AWS changes are made.

The `expected_aws_account` check in `checks.tf` repeats the comparison as a readable warning. Terraform `check` blocks never block an apply on their own, which is why the provider setting is the enforcing control.

If the account check fails:

1. Stop the run.
2. Do not approve the apply.
3. Verify the configured AWS credentials.
4. Verify the intended training account.
5. Correct the authentication or workspace configuration before continuing.

Never change `expected_aws_account_id` simply to remove the warning without confirming the intended target account.

## Plan and Apply Review

HCP Terraform Auto Apply should remain disabled.

The expected workflow is:

```text
Configuration change
        |
        v
Terraform plan
        |
        v
Human review
        |
        v
Manual approval
        |
        v
Terraform apply
```

Before approving a Lab 1 plan, confirm:

- The AWS account is correct.
- The AWS Region is correct.
- The VPC CIDR is expected.
- Exactly two public subnets are planned.
- Exactly two private subnets are planned.
- Two Availability Zones are used.
- The Internet Gateway belongs to the training VPC.
- The public route table points to the Internet Gateway.
- Private route tables have no default Internet route.
- No NAT Gateway is planned.
- Resource tags identify the deployment.
- No unrelated resources are being modified or destroyed.

A valid Terraform configuration does not automatically mean a Terraform plan is safe to apply.

## Publicly Reachable Network Paths

Lab 1 creates two public subnets with:

```text
map_public_ip_on_launch = true
```

The public subnets use a shared route table containing:

```text
0.0.0.0/0 -> Internet Gateway
```

This makes the subnets suitable for later Internet-facing workloads.

Lab 1 itself does not create:

- EC2 instances.
- Load balancers.
- Public databases.
- Application listeners.
- Application security groups.
- Public web applications.

Creating a public subnet does not by itself expose an application.

Later labs must separately control workload exposure using security groups and other appropriate controls.

## Private Network Paths

Lab 1 creates two private subnets with:

```text
map_public_ip_on_launch = false
```

Their route tables do not contain:

```text
0.0.0.0/0 -> Internet Gateway
```

The baseline private route tables also do not contain a NAT Gateway route.

These subnets provide the network foundation for later private application and database tiers.

## Internet Gateway

The Internet Gateway is attached to the VPC so the public subnets can have Internet routing.

Attaching an Internet Gateway to a VPC does not automatically make every subnet public.

Internet reachability depends on routing and on the configuration of workloads deployed into the subnet.

This distinction is a core learning objective of Lab 1.

## NAT Gateway

A NAT Gateway is not deployed in the baseline lab.

The decision avoids:

- A paid networking resource that is unnecessary for this exercise.
- Additional routing complexity before learners need it.
- Outbound Internet connectivity from private subnets without a demonstrated requirement.

The private subnets contain no workloads in Lab 1, so they do not require outbound Internet access.

Optional NAT functionality should be introduced only as an advanced exercise with an explicit cost explanation.

## CIDR Guardrails

The baseline address plan is:

```text
VPC               10.42.0.0/16
Public subnet A   10.42.10.0/24
Public subnet B   10.42.20.0/24
Private subnet A  10.42.110.0/24
Private subnet B  10.42.120.0/24
```

Terraform validates that:

- Two public subnet CIDRs are supplied.
- Two private subnet CIDRs are supplied.
- Subnet CIDRs are valid.
- Training subnets use `/24` prefixes.
- Subnet networks are unique.
- Public and private subnet ranges are distinct.
- Subnet networks do not overlap.
- Every subnet resides inside the configured VPC CIDR.

These checks reduce the chance of deploying an invalid or confusing network design.

## Availability Zone Guardrail

Lab 1 requires at least two available AWS Availability Zones.

Terraform discovers available zones dynamically rather than hardcoding names such as:

```text
us-east-1a
us-east-1b
```

Availability Zone names can map differently between AWS accounts, so dynamic discovery makes the training repository more portable.

## Resource Identification and Tags

The AWS provider applies standard tags wherever supported.

The baseline tags are:

```text
ManagedBy    = Terraform
Purpose      = Training
Project      = terraform-aws-security-training
Lab          = network-foundation
Owner        = <learner identifier>
DeploymentId = <unique deployment identifier>
Environment  = Lab
CreatedFrom  = terraform-aws-security-training
ExpiresOn    = <cleanup date>
```

These tags help administrators determine:

- Who owns the deployment.
- Which lab created the resource.
- Which deployment created it.
- Why the resource exists.
- Whether Terraform manages it.
- When the resource should be reviewed for cleanup.

Tags are governance metadata. They are not authorization controls by themselves.

## Data Encryption

Lab 1 does not create persistent application or database storage.

It does not create:

- EBS volumes.
- S3 objects.
- RDS storage.
- Application databases.
- Application secrets.

Encryption requirements are introduced in the labs that create those resources.

Terraform state must still be treated as sensitive infrastructure information and stored through the approved HCP Terraform workflow.

## Logging

The baseline lab does not enable VPC Flow Logs or other optional network logging resources.

This is intentional to keep the initial network lab small and cost-conscious.

Account-level AWS logging outside this repository may still record activity depending on the learner environment.

Production environments typically require stronger logging, monitoring, alerting, retention, and audit controls than this training lab demonstrates.

Optional network logging should be introduced separately with its storage, privacy, security, and cost implications explained.

## Cost as a Security Control

Unexpected cloud resources create financial risk.

The baseline lab therefore:

- Does not create a NAT Gateway.
- Does not create compute resources.
- Does not create load balancers.
- Does not create databases.
- Uses a small fixed network architecture.
- Requires an expiration-date tag.
- Keeps Auto Apply disabled.
- Requires plan review.
- Includes a destroy workflow.

VPCs, subnets, route tables, and Internet Gateways normally have no direct hourly charge on their own, but AWS pricing and related service charges can change.

Cost information must be reviewed before public release.

See:

```text
COSTS.md
```

for detailed cost guidance.

## Safe Destruction

Destroying infrastructure is a security-sensitive operation.

The expected workflow is:

```text
Destroy request
      |
      v
Destroy plan
      |
      v
Human review
      |
      v
Confirm Lab 1 resources only
      |
      v
Terraform destroy
      |
      v
Validate cleanup
```

Before confirming destruction:

- Verify the destroy plan contains only Lab 1 resources.
- Confirm no later lab still depends on the network.
- Review Terraform state.
- Do not manually delete Terraform-managed resources first.

After destruction, confirm:

- The training VPC is gone.
- Both public subnets are gone.
- Both private subnets are gone.
- The Internet Gateway is gone.
- Lab route tables are gone.
- HCP Terraform state reflects the completed destruction.
- No unexpected Lab 1 resources remain.

Partial failures can leave AWS resources present while Terraform still contains important state information about them.

Inspect Terraform state before taking manual recovery actions.

## IAM Training Baseline

The file:

```text
examples/iam/training-policy.json
```

is intentionally a training baseline.

It is not a universal production IAM policy.

The policy deliberately avoids:

```text
AdministratorAccess
ec2:*
Action: "*"
```

Some EC2 API actions cannot be meaningfully restricted to individual resource ARNs and therefore use:

```json
"Resource": "*"
```

This does not grant every EC2 action. The allowed API actions remain explicitly listed.

Permission failures during private validation should be investigated individually. Add only the specific AWS API permission demonstrated to be required for the Lab 1 lifecycle.

## Training Simplifications

Lab 1 intentionally does not configure:

- VPC Flow Logs.
- AWS Network Firewall.
- Transit Gateway.
- Site-to-Site VPN.
- AWS Direct Connect.
- IPv6 routing.
- NAT Gateway.
- Centralized egress inspection.
- AWS Organizations controls.
- Service Control Policies.
- Production monitoring and alerting.
- Production-grade IAM federation.
- Automated resource expiration.

These omissions are deliberate.

Lab 1 focuses on:

- VPC boundaries.
- CIDR planning.
- Availability Zones.
- Public and private subnet design.
- Internet Gateway routing.
- Route tables.
- Terraform guardrails.
- Resource ownership.
- Infrastructure lifecycle.

Additional controls should be introduced after the learner understands the network foundation they protect.

## Security Validation Checklist

Before approving an apply, confirm:

- [ ] The target AWS account is correct.
- [ ] The target AWS Region is correct.
- [ ] Auto Apply is disabled.
- [ ] No credentials exist in repository history.
- [ ] No Terraform state exists in Git.
- [ ] No Terraform plan files exist in Git.
- [ ] The IAM policy does not use `AdministratorAccess`.
- [ ] The IAM policy does not use `ec2:*`.
- [ ] The VPC CIDR is expected.
- [ ] Public and private subnet CIDRs do not overlap.
- [ ] Two Availability Zones are used.
- [ ] Only public subnets have the Internet Gateway default route.
- [ ] Private subnets have no baseline Internet route.
- [ ] No NAT Gateway is planned.
- [ ] Required ownership tags are present.
- [ ] The plan affects only Lab 1 resources.

Before approving a destroy, confirm:

- [ ] The destroy plan affects only Lab 1 resources.
- [ ] No later lab still depends on the Lab 1 network.
- [ ] Terraform state has been reviewed.
- [ ] Cleanup will be validated after destruction.

## Reporting a Security Issue

Do not put active credentials, private Terraform state, internal account identifiers, or other sensitive environment data into a public issue.

If credentials are discovered in repository history during private development:

1. Treat the credential as exposed.
2. Revoke or rotate it.
3. Review the full Git history.
4. Do not assume deleting the current file removes historical exposure.
5. Create clean public history if sensitive information entered repository history.

Security is part of the complete infrastructure lifecycle, from the first Terraform plan through final destruction.
