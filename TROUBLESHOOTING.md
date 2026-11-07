# Troubleshooting Guide

This guide covers common problems that can occur while configuring, planning, applying, validating, or destroying the Terraform AWS Network Foundation Lab.

When troubleshooting Terraform-managed infrastructure, do not immediately change or delete resources manually in the AWS console.

Start with the Terraform configuration, run output, and state.

## First Diagnostic Steps

Check the local configuration:

```bash
terraform version
terraform fmt -check -diff
terraform validate
```

A valid configuration should report:

```text
Success! The configuration is valid.
```

Confirm the expected Terraform files exist:

```bash
ls -1 *.tf
```

Expected files:

```text
checks.tf
data.tf
locals.tf
main.tf
outputs.tf
provider.tf
variables.tf
versions.tf
```

## Terraform Is Not Initialized

If Terraform reports that the working directory is not initialized, run:

```bash
terraform init
terraform validate
```

The local directory:

```text
.terraform/
```

must remain outside Git.

The provider lock file:

```text
.terraform.lock.hcl
```

should be committed.

## Formatting or Validation Fails

If formatting fails, run:

```bash
terraform fmt
terraform fmt -check -diff
```

If validation fails, read the first error carefully.

Common causes include:

- Missing braces.
- Invalid expressions.
- Misspelled variable names.
- Incorrect resource references.
- Unsupported Terraform syntax.
- Provider configuration errors.

Fix configuration errors before attempting a plan.

Do not work around a validation failure by modifying AWS manually.

A successful `terraform validate` does not guarantee a successful plan. Some errors, such as calling a function that does not exist inside a `check` block, are only reported when Terraform evaluates the configuration during a plan.

## HCP Terraform Cannot Authenticate to AWS

Typical symptoms:

```text
No valid credential sources found
InvalidClientTokenId
SignatureDoesNotMatch
```

Check the HCP Terraform workspace variables:

1. `AWS_ACCESS_KEY_ID` exists and its category is **Environment variable**.
2. `AWS_SECRET_ACCESS_KEY` exists, its category is **Environment variable**, and it is marked **Sensitive**.
3. Neither value contains leading or trailing spaces.
4. The access key is active in IAM and has not been rotated or deleted.

Credentials must never be added to `provider.tf`, `variables.tf`, or any committed file.

## Required Variable Has No Value

Typical symptom:

```text
No value for required variable
```

Deployment settings must be **Terraform variables**, not environment variables. Confirm these exist in the workspace with the category **Terraform variable**:

```text
aws_region
expected_aws_account_id
owner_name
deployment_id
expiration_date
```

Variable names are case-sensitive and must match `variables.tf` exactly.

## Account Guardrail Check Fails

The provider setting `allowed_account_ids` compares the authenticated AWS account with `expected_aws_account_id`. If they do not match, Terraform stops before making any AWS changes.

Typical symptom:

```text
AWS account ID not allowed
```

The `expected_aws_account` check in `checks.tf` also reports a warning with the same meaning.

This is the guardrail working as intended. It means the credentials point at a different account than the one you declared.

Resolve it by correcting one of the following:

- The workspace credentials, if they belong to the wrong account.
- The `expected_aws_account_id` value, if it was entered incorrectly.

Do not remove `allowed_account_ids` or the check to make the plan succeed.

## AccessDenied or UnauthorizedOperation

Typical symptoms:

```text
AccessDenied
UnauthorizedOperation
You are not authorized to perform this operation
```

The error message names the denied action, for example `ec2:CreateRouteTable`.

1. Record the exact action named in the error.
2. Confirm whether the error occurred during plan, apply, or destroy.
3. Add only that action to the training policy.
4. Queue a new plan.

The AWS provider reads resource attributes during refresh, so read-only actions can be required even when nothing is being created. Actions that have been needed in earlier labs include:

```text
ec2:DescribeVpcAttribute
ec2:DescribeInstanceAttribute
ec2:DescribeInstanceCreditSpecifications
```

This lab also needs `ec2:DescribeNetworkInterfaces` when deleting subnets, because the provider checks each subnet for leftover network interfaces before removing it. It is included in the training policy.

Do not attach `AdministratorAccess` to resolve permission errors. `examples/iam/training-policy.json` is a training baseline and should be refined only from demonstrated failures.

## Wrong Region

If resources appear in an unexpected region, or the plan cannot find Availability Zones you expect, compare:

- The `aws_region` Terraform variable.
- The `AWS_REGION` and `AWS_DEFAULT_REGION` environment variables, if set.

The provider uses `aws_region`. Keep the environment variables consistent with it to avoid confusion when using the AWS CLI.

## Availability Zone Problems

The lab places subnets in two Availability Zones read from the region at plan time.

If the plan fails because fewer than two Availability Zones are available, or an Availability Zone is not enabled for the account, choose a region with at least two standard Availability Zones and update `aws_region`.

## CIDR Conflicts

The baseline network plan is:

```text
VPC:             10.42.0.0/16
Public subnet A: 10.42.10.0/24
Public subnet B: 10.42.20.0/24
Private subnet A: 10.42.110.0/24
Private subnet B: 10.42.120.0/24
```

If you override the defaults, every subnet must fall inside the VPC CIDR and no two subnets may overlap.

The `10.42.0.0/16` range can conflict with an existing network if the VPC is later peered or connected to another network. That does not affect this lab, but choose a different range if you plan to connect the VPC elsewhere.

## Plan Shows Unexpected Changes

Before applying, read every line of the plan.

Stop and investigate if the plan:

- Destroys or replaces the VPC or subnets unexpectedly.
- Creates a NAT Gateway (NAT Gateway is disabled by default).
- Creates resources in an unexpected region.
- Changes many resources after only a documentation change.

Do not apply a plan you do not understand. Discard the run and correct the inputs first.

## Apply Partially Fails

An apply can fail after some resources were created. Those resources exist in AWS and are recorded in state.

1. Do not delete anything manually in the AWS console.
2. Read the full error in the HCP Terraform run output.
3. Review the workspace state to see which resources were created.
4. Fix the cause, such as a missing IAM permission.
5. Queue a new plan and confirm it only creates or repairs what is missing.

If a resource is marked tainted, Terraform plans to replace it. Only untaint a resource after confirming in AWS that it is healthy and correctly configured.

## Destroy Partially Fails

A destroy can stop partway through. Resources already removed are gone from both AWS and state, and the remaining resources stay in both.

Worked example from testing this lab: a destroy removed 9 of the 14 resources, then failed on all four subnets with `UnauthorizedOperation` for `ec2:DescribeNetworkInterfaces`. The VPC was not attempted because its subnets still existed. The recovery was:

1. Do not delete the remaining resources manually in the console.
2. Add only the denied action to the training policy.
3. Queue a new destroy plan and confirm it lists only the remaining resources, in this case `5 to destroy`.
4. Confirm the destroy and validate cleanup using `docs/cleanup-guide.md`.

## Destroy Fails with DependencyViolation

Typical symptom:

```text
DependencyViolation
has dependencies and cannot be deleted
```

AWS will not delete a VPC, subnet, or Internet Gateway while other resources still use it. This normally means a later lab is still deployed into this network.

1. Identify the dependent lab or resource.
2. Destroy the dependent lab through its own Terraform workspace.
3. Queue a new destroy plan for this lab.
4. Review the destroy plan.
5. Confirm the destroy.

Never destroy this network while later labs depend on it. Do not delete the blocking resources manually unless you have confirmed no Terraform workspace manages them.

## Resources Are Missing Tags

Standard tags are applied through provider `default_tags`.

If a resource is missing tags:

- Confirm `owner_name`, `deployment_id`, and `expiration_date` are set in the workspace.
- Confirm the resource was created by this Terraform workspace and not manually.

Resources without the `ManagedBy = Terraform` tag were not created by this lab.

## When to Stop and Ask for Help

Stop and seek help before continuing if:

- The plan proposes destroying resources you did not expect.
- State does not match what exists in AWS.
- A fix appears to require broad permissions such as `AdministratorAccess`.
- You are unsure whether another lab depends on this network.

Record the error message, the run type (plan, apply, or destroy), and the step you were on before asking for help.
