# Cleanup Guide

This guide walks through safely destroying the Network Foundation Lab and confirming nothing is left behind.

The network itself costs nothing while idle, but it should still be removed when you are finished so that old training resources do not accumulate in the account.

## Step 1: Confirm No Other Lab Depends on This Network

Later labs deploy into this VPC. Destroying the network while they are running will fail, and attempting it wastes time.

1. In HCP Terraform, review your other workspaces.
2. Destroy any later lab that uses this network first, through its own workspace.
3. Wait for those destroys to finish before continuing.

If you have the AWS CLI, confirm nothing is still using the VPC:

```bash
VPC_ID="paste-vpc-id-from-outputs"
```

```bash
aws ec2 describe-network-interfaces --filters "Name=vpc-id,Values=$VPC_ID" --query 'NetworkInterfaces[].[NetworkInterfaceId,Description]' --output table
```

Expected: no network interfaces. Any result means something is still deployed in the VPC.

## Step 2: Queue the Destroy Plan

1. Open the Lab 1 workspace in HCP Terraform.
2. Open the workspace settings and find the destruction option.
3. Queue a destroy plan.
4. Wait for the plan to finish.

## Step 3: Review the Destroy Plan

Do not confirm the destroy until you have checked every item:

- The summary reads `Plan: 0 to add, 0 to change, 14 to destroy.`
- You are in the Lab 1 workspace, not a different lab's workspace.
- Every resource name begins with `network-foundation-` followed by your `deployment_id`.
- No resource belongs to another lab or to infrastructure you did not create.

If the count is not 14, or any resource looks unfamiliar, discard the run and investigate before continuing.

## Step 4: Confirm the Destroy

1. Select **Confirm & apply**.
2. Add a short comment, such as `Lab 1 cleanup`.
3. Confirm and wait for the run to finish.

A successful destroy ends with:

```text
Apply complete! Resources: 0 added, 0 changed, 14 destroyed.
```

If the destroy fails with `DependencyViolation`, see `TROUBLESHOOTING.md`. Do not delete resources manually in the console.

## Step 5: Validate Cleanup in AWS

Confirm the VPC no longer exists:

```bash
aws ec2 describe-vpcs --vpc-ids "$VPC_ID"
```

Expected: an `InvalidVpcID.NotFound` error. That error is the success condition here.

Confirm no lab-tagged resources remain, using the same `deployment_id` you set in the workspace:

```bash
aws resourcegroupstaggingapi get-resources --tag-filters "Key=DeploymentId,Values=paste-your-deployment-id" --query 'ResourceTagMappingList[].ResourceARN' --output text
```

Expected: no output. Recently deleted resources can appear here for a short time after a destroy. Wait a few minutes and run it again before treating a result as a problem.

This command needs the `tag:GetResources` permission, which may not be in the training policy. If it is denied, use **Tag Editor** in the AWS console to search for the same tag instead.

## Step 6: Validate Terraform State

1. Open the workspace **States** tab and select the latest state.
2. Confirm it contains no resources.
3. Open the **Outputs** tab and confirm it is empty.

An empty state means Terraform no longer manages anything for this workspace.

## Step 7: Decide What to Keep

After a successful cleanup:

- **Keep the workspace** if you plan to redeploy the lab later. An empty workspace costs nothing.
- **Delete the workspace** if you are finished with the lab entirely.
- **Deactivate or delete the access key** in IAM, and remove it from the workspace, if it is no longer needed. Long-lived keys that are not in use should not be left active.

Check the AWS Billing console over the next day to confirm no unexpected charges appear.
