# Cost Guidance

This document explains the expected AWS cost of the Terraform AWS Network Foundation Lab and the design decisions used to keep the lab inexpensive.

AWS pricing can change. Always verify current pricing before public release and before using this lab in a production or large-scale training environment.

## Cost Summary

| Item | Lab 1 Estimate |
|---|---|
| Expected learner session | Approximately 60 to 90 minutes |
| Baseline infrastructure cost | Approximately $0 |
| Estimated monthly infrastructure cost if forgotten | Approximately $0 for the baseline Lab 1 resources |
| NAT Gateway | Disabled |
| VPC Flow Logs | Disabled |
| Compute resources | None |
| Load balancers | None |
| Databases | None |

The baseline estimate assumes only the resources created by this repository are deployed.

Later labs that place workloads inside this network can create additional charges.

Pricing reviewed November 2026 against AWS list prices: VPCs, subnets, route tables, and Internet Gateways have no hourly charge. Public IPv4 addresses cost $0.005 per hour each, and a NAT Gateway costs $0.045 per hour plus data processing in us-east-1. Lab 1 creates neither. Optional VPC features such as VPC Encryption Controls carry their own charges and are not enabled by this lab.

## Baseline Resources

Lab 1 creates:

- One VPC.
- Two public subnets.
- Two private subnets.
- One Internet Gateway.
- One shared public route table.
- Two private route tables.
- Route table associations.
- One default route (`0.0.0.0/0`) to the Internet Gateway. This is a route, not a public IP address.

The network design is:

```text
VPC               10.42.0.0/16
Public subnet A   10.42.10.0/24
Public subnet B   10.42.20.0/24
Private subnet A  10.42.110.0/24
Private subnet B  10.42.120.0/24
```

The baseline lab does not deploy application workloads.

## Expected Session Cost

The expected direct AWS infrastructure cost for the baseline Lab 1 session is approximately:

```text
$0
```

This estimate is based on the baseline lab creating only standard VPC networking resources such as:

- VPC.
- Subnets.
- Route tables.
- Route table associations.
- Internet Gateway.

These resources normally do not have a direct hourly charge by themselves.

Do not interpret this estimate as a guarantee that an AWS account will receive no charges.

Other resources, account-level services, traffic patterns, learner modifications, future AWS pricing changes, or resources from other labs can create costs.

## Estimated Monthly Cost if Forgotten

If only the baseline Lab 1 resources remain deployed, the expected direct monthly infrastructure cost is approximately:

```text
$0
```

This estimate assumes:

- No NAT Gateway is enabled.
- No paid VPC Flow Logs destination is configured by this repository.
- No EC2 instances are deployed.
- No public IPv4 addresses are allocated to running workloads.
- No load balancers are deployed.
- No databases are deployed.
- No other paid services are added by the learner.

Even though the baseline network is expected to have little or no direct idle cost, learners should still destroy training infrastructure when finished.

Cleanup prevents abandoned resources, reduces confusion, and ensures later labs are not accidentally using an environment the learner believes has been removed.

## Most Expensive Resource

In the baseline configuration, there is no intentionally billable infrastructure resource expected to dominate cost.

The resource that would materially change the cost profile is:

```text
NAT Gateway
```

A NAT Gateway is intentionally disabled in the baseline lab.

The current Terraform configuration does not deploy NAT Gateway resources.

NAT should be introduced only as an optional advanced exercise after its architecture and pricing are explained.

## Why NAT Gateway Is Disabled

NAT Gateway can provide outbound Internet connectivity for workloads in private subnets.

Lab 1 does not deploy workloads into the private subnets, so that connectivity is unnecessary.

Enabling NAT would:

- Introduce an hourly networking charge.
- Introduce data-processing charges.
- Add routing complexity.
- Increase the financial risk of forgetting the lab.
- Distract from the primary public-versus-private routing lesson.

The baseline private route tables therefore contain no NAT Gateway default route.

## VPC Flow Logs

VPC Flow Logs are not enabled by this baseline repository.

Flow Logs can be useful for:

- Network troubleshooting.
- Security investigations.
- Traffic analysis.
- Audit and monitoring workflows.

However, Flow Logs can create charges through services used to collect, store, query, or analyze the records.

Logging is therefore treated as an optional advanced feature rather than a baseline Lab 1 requirement.

## Services That Continue Billing When Stopped

The baseline Lab 1 configuration does not create traditional "stoppable" resources such as EC2 instances or databases.

The baseline resources are networking configuration objects rather than workloads that can be stopped and started.

However, later labs can add resources to this network that continue to generate charges even when the learner considers the exercise finished.

Examples in later labs can include:

- Public IPv4 addresses.
- EBS storage.
- Load balancers.
- RDS databases.
- NAT Gateway.
- Data transfer.
- Logging and monitoring storage.

Always review the resources associated with the training account rather than assuming that stopping an application eliminates all AWS charges.

## Free Tier and Credit Caveats

This lab does not depend on Free Tier eligibility to justify its baseline estimate.

Learners may have:

- AWS Free Tier benefits.
- Promotional credits.
- Sandbox credits.
- Organization-provided training credits.
- No credits at all.

Do not describe a resource as free simply because one learner's account receives a credit.

Published cost estimates should describe AWS list-price behavior before learner-specific credits whenever practical.

Credits reduce the learner's bill. They do not change the underlying service pricing.

## Training-Series Budget

The broader Terraform AWS Security Training series targets approximately:

```text
$10 or less per learner
```

for the initial learning pathway when learners:

- Use normal low training traffic.
- Keep lab sessions short.
- Destroy billable resources after validation.
- Leave NAT Gateway disabled unless specifically required.
- Avoid unnecessary always-on services.

A suggested learner AWS Budget is:

```text
Budget target:  $10
Warning:         $5
Warning:         $8
```

AWS Budget notifications are alerts. They are not automatic shutdown controls.

A budget warning does not replace cleanup.

## Cost Controls in Lab 1

Lab 1 uses several cost-control practices:

### NAT Gateway disabled by default

The baseline lab does not deploy NAT Gateway resources.

### No compute resources

Lab 1 does not create EC2 instances.

### No load balancer

Lab 1 does not create an Application Load Balancer or Network Load Balancer.

### No database

Lab 1 does not create RDS, DynamoDB, or another database service.

### No paid logging by default

The baseline repository does not create VPC Flow Logs.

### Auto Apply disabled

HCP Terraform Auto Apply should remain disabled.

A learner should review the plan before approving infrastructure creation.

### Expiration metadata

The lab requires:

```text
expiration_date
```

and applies it through the standard:

```text
ExpiresOn
```

tag where supported.

The expiration date is governance metadata. It does not automatically delete AWS resources.

### Destroy workflow

The training lifecycle includes destroy review and cleanup validation.

## Required Cleanup

When the learner is finished with Lab 1 and no later lab depends on its network, queue a destroy operation through HCP Terraform.

The expected workflow is:

```text
Destroy request
      |
      v
Destroy plan
      |
      v
Review resource list
      |
      v
Manual confirmation
      |
      v
Terraform destroy
      |
      v
Validate cleanup
```

Before confirming destroy, verify that Terraform plans to remove only Lab 1 resources.

After destroy, confirm that the following have been removed:

- Training VPC.
- Two public subnets.
- Two private subnets.
- Internet Gateway.
- Public route table.
- Private route tables.
- Route table associations.

Also verify that HCP Terraform state reflects the completed destruction.

## When Not to Destroy Lab 1

Lab 1 creates the reusable network foundation for later labs.

Do not destroy the Lab 1 network while another active lab still depends on its outputs.

Later labs can consume values such as:

```text
vpc_id
public_subnet_ids
private_subnet_ids
```

If later infrastructure still uses those network resources, destroying Lab 1 can break or block that infrastructure.

Before destroying the network, confirm dependent labs have already been destroyed or no longer use it.

## Forgotten Resource Review

If a learner forgets to clean up a training environment:

1. Review the HCP Terraform workspace.
2. Review the Terraform state.
3. Review the most recent plan or run.
4. Inspect AWS resources with the Lab 1 ownership tags.
5. Identify any resources created by later labs.
6. Review the destroy plan before confirmation.
7. Destroy the training resources in dependency order.
8. Validate that cleanup completed.

Do not manually delete Terraform-managed resources solely because they appear abandoned.

Terraform state should be reviewed first.

## Pricing Verification Before Public Release

The approximate cost guidance in this repository must be reviewed before the repository becomes public.

Before release:

1. Review the current AWS pricing for every resource created by the lab.
2. Confirm the baseline Terraform still creates no NAT Gateway.
3. Confirm optional paid logging remains disabled.
4. Confirm no newly added Terraform resource introduces a charge.
5. Update this document if AWS pricing or the architecture changed.
6. Record estimates before Free Tier or promotional credits.

Use the official AWS pricing documentation and AWS Pricing Calculator when performing the release-time review.

## Cost Review Checklist

Before approving an apply:

- [ ] No NAT Gateway is planned.
- [ ] No unexpected compute resource is planned.
- [ ] No load balancer is planned.
- [ ] No database is planned.
- [ ] No unexpected paid logging resource is planned.
- [ ] The architecture matches the baseline network design.
- [ ] Auto Apply is disabled.
- [ ] The learner understands the cleanup process.

Before ending the lab:

- [ ] Determine whether another lab still depends on this network.
- [ ] Review the destroy plan when cleanup is appropriate.
- [ ] Destroy billable dependent resources before the network foundation.
- [ ] Validate AWS cleanup.
- [ ] Confirm HCP Terraform state matches the final environment.

## Final Reminder

Cost control is part of infrastructure engineering.

A resource does not need to be expensive to deserve an owner, an expiration date, a reviewed plan, and a cleanup process.

Lab 1 intentionally starts with a low-cost network foundation so learners can practice those habits before later labs introduce billable compute, storage, load balancing, database, and networking services.
