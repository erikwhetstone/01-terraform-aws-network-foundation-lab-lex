# Deployment Guide

This guide walks through deploying the Network Foundation Lab with HCP Terraform, reviewing the plan, applying it, and validating the result.

For removing the lab afterward, see `cleanup-guide.md`.

## Prerequisites

- An AWS account you are permitted to use for training, either your own or a sandbox account provided by your AWS administrator.
- An IAM identity with the permissions in `examples/iam/training-policy.json`, and an access key for it. If you do not administer the AWS account, ask your AWS administrator to create these. Lab 0 explains the setup.
- An HCP Terraform account and organization. Lab 0 explains the setup.
- Your own copy of this repository in GitHub, created by forking it or using it as a template.
- An AWS Budget configured as described in Lab 0.
- Optional: the AWS CLI, for command-line validation.

## Step 1: Create the Workspace

1. In HCP Terraform, create a new workspace.
2. Choose the **Version Control** workflow.
3. Connect your GitHub account and select your copy of this repository.
4. Give the workspace a name that identifies the lab and learner, such as `network-foundation-<your-name>`.
5. Create the workspace.

## Step 2: Confirm Auto Apply Is Off

1. Open the workspace settings.
2. Confirm that auto-apply is disabled.
3. Save if you made a change.

With auto-apply off, every run stops after the plan and waits for your approval.

While in the settings, you can also pin the workspace Terraform version to a specific release instead of the latest. This keeps your runs reproducible. This lab was tested with Terraform 1.17.1.

## Step 3: Add Environment Variables

Add these with the category **Environment variable**:

| Key | Value | Sensitive |
|---|---|---|
| `AWS_ACCESS_KEY_ID` | Your training access key ID | Yes |
| `AWS_SECRET_ACCESS_KEY` | Your training secret access key | Yes |

These authenticate the AWS provider. They must never be placed in any file in the repository.

The HCP Terraform **Add variable** form defaults to **Terraform variable**. Select **Environment variable** before saving, or the AWS provider will not find the credentials and the plan fails with `No valid credential sources found`.

## Step 4: Add Terraform Variables

Add these with the category **Terraform variable**:

| Key | Example value |
|---|---|
| `aws_region` | `us-east-1` |
| `expected_aws_account_id` | Your 12-digit AWS account ID |
| `owner_name` | `Jane-Doe` |
| `deployment_id` | `jane-network-01` |
| `expiration_date` | A date a few days out, in `YYYY-MM-DD` format |

The CIDR variables have defaults and do not need to be set. Leave them unset unless you have a specific reason to change the address plan.

`expected_aws_account_id` must be the account your access key belongs to. If it is not, the provider stops the run before making any changes.

## Step 5: Queue a Plan

1. Open the workspace and select **New run**.
2. Choose a plan and apply run.
3. Start the run and wait for the plan to finish.

## Step 6: Review the Plan

Do not approve the run until you have checked every item:

- The summary reads `Plan: 14 to add, 0 to change, 0 to destroy.`
- Every resource is in the region you set in `aws_region`.
- There is no `aws_nat_gateway` resource.
- There is no `aws_eip` resource.
- The VPC CIDR is `10.42.0.0/16` unless you changed it.
- The tags include your `owner_name`, `deployment_id`, and `expiration_date`.

If anything is unexpected, discard the run and correct the inputs. See `TROUBLESHOOTING.md`.

## Step 7: Apply

1. Select **Confirm & apply**.
2. Add a short comment, such as `Initial Lab 1 deployment`.
3. Confirm and wait for the apply to finish.

A successful apply ends with:

```text
Apply complete! Resources: 14 added, 0 changed, 0 destroyed.
```

The workspace header then shows **Resources 16**: the 14 managed resources plus the 2 data sources the lab reads. This is expected.

## Step 8: Review the Outputs

Open the workspace **Outputs** tab and confirm:

- `vpc_cidr` is `10.42.0.0/16`.
- `public_subnet_cidrs` lists `10.42.10.0/24` and `10.42.20.0/24`.
- `private_subnet_cidrs` lists `10.42.110.0/24` and `10.42.120.0/24`.
- `availability_zones` lists two different zones.
- `public_subnet_ids` and `private_subnet_ids` each contain two IDs.

Copy the `vpc_id` value. The validation steps below use it.

## Step 9: Validate in AWS

You can validate in the AWS console under **VPC**, or with the AWS CLI using the same credentials and region.

Set the VPC ID from the outputs:

```bash
VPC_ID="paste-vpc-id-from-outputs"
```

Confirm the VPC CIDR:

```bash
aws ec2 describe-vpcs --vpc-ids "$VPC_ID" --query 'Vpcs[0].CidrBlock' --output text
```

Confirm the four subnets, their zones, and which ones assign public IPs:

```bash
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[].[CidrBlock,AvailabilityZone,MapPublicIpOnLaunch]' --output table
```

The public subnets `10.42.10.0/24` and `10.42.20.0/24` should show `True`. The private subnets `10.42.110.0/24` and `10.42.120.0/24` should show `False`.

Confirm the Internet Gateway is attached:

```bash
aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[].InternetGatewayId' --output text
```

Confirm the routes in each route table:

```bash
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query 'RouteTables[].[RouteTableId,join(`, `,Routes[].DestinationCidrBlock)]' --output table
```

Expect four route tables:

- The public route table, with `10.42.0.0/16` and `0.0.0.0/0`.
- Two private route tables, with `10.42.0.0/16` only.
- The VPC main route table, with `10.42.0.0/16` only.

AWS creates the main route table automatically with every VPC. It is not managed by Terraform, carries no lab tags, and has no subnets associated with it in this lab.

Confirm no NAT Gateway exists:

```bash
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" --query 'NatGateways[?State!=`deleted`].NatGatewayId' --output text
```

Expected: no output.

Confirm the standard tags on the VPC:

```bash
aws ec2 describe-vpcs --vpc-ids "$VPC_ID" --query 'Vpcs[0].Tags' --output table
```

## Resources AWS Creates Automatically

Along with the main route table, AWS creates a default network ACL and a default security group for every VPC. Terraform does not manage them, and they are deleted automatically when the VPC is destroyed.

## Next Steps

Leave the network in place while you complete labs that depend on it. Record the `vpc_id`, `public_subnet_ids`, and `private_subnet_ids` outputs, since later labs ask for them.

When you no longer need the network, follow `cleanup-guide.md`.
