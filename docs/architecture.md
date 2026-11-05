# Architecture

This document describes the network that the Terraform AWS Network Foundation Lab builds, how traffic is routed, and how later labs consume it.

For Terraform concepts, see `concepts.md`. For deployment steps, see `deployment-guide.md`.

## Overview

The lab creates one VPC with four subnets spread across two Availability Zones:

```text
VPC 10.42.0.0/16
|
|-- Availability Zone 1
|   |-- Public subnet 1   10.42.10.0/24   -> public route table
|   `-- Private subnet 1  10.42.110.0/24  -> private route table 1
|
|-- Availability Zone 2
|   |-- Public subnet 2   10.42.20.0/24   -> public route table
|   `-- Private subnet 2  10.42.120.0/24  -> private route table 2
|
`-- Internet Gateway

Public route table:     10.42.0.0/16 -> local
                        0.0.0.0/0    -> Internet Gateway

Private route tables:   10.42.0.0/16 -> local
                        (no default Internet route)
```

The lab creates networking only. It does not create any compute, storage, or database resources.

## Resource Inventory

| Terraform address | AWS resource | Count | Purpose |
|---|---|---|---|
| `aws_vpc.this` | VPC | 1 | Isolated network boundary for this lab and later labs |
| `aws_internet_gateway.this` | Internet Gateway | 1 | Internet path for the public route table |
| `aws_subnet.public` | Subnet | 2 | Internet-facing resources |
| `aws_subnet.private` | Subnet | 2 | Internal application and database resources |
| `aws_route_table.public` | Route table | 1 | Shared by both public subnets |
| `aws_route.public_internet` | Route | 1 | Default route `0.0.0.0/0` to the Internet Gateway |
| `aws_route_table_association.public` | Association | 2 | Binds each public subnet to the public route table |
| `aws_route_table.private` | Route table | 2 | One per private subnet, no Internet route |
| `aws_route_table_association.private` | Association | 2 | Binds each private subnet to its own route table |

A first plan against an empty account should report:

```text
Plan: 14 to add, 0 to change, 0 to destroy.
```

A different number means the configuration or inputs differ from the baseline and should be investigated before applying.

## Address Plan

| Network | CIDR | Usable addresses |
|---|---|---|
| VPC | `10.42.0.0/16` | 65,536 total |
| Public subnet 1 | `10.42.10.0/24` | 251 |
| Public subnet 2 | `10.42.20.0/24` | 251 |
| Private subnet 1 | `10.42.110.0/24` | 251 |
| Private subnet 2 | `10.42.120.0/24` | 251 |

AWS reserves five addresses in every subnet, so each /24 provides 251 usable addresses rather than 256.

The gaps between ranges are deliberate. The `10.42.10.x` to `10.42.20.x` public ranges and the `10.42.110.x` to `10.42.120.x` private ranges leave room for additional subnet tiers in later labs without renumbering.

## Availability Zones

Each public and private subnet pair is placed in the same Availability Zone. The two zones are selected from the zones available in the chosen region at plan time, so the lab is not tied to specific zone names.

Two zones demonstrate a basic multi-AZ design. Later labs, such as the Application Load Balancer and RDS labs, require subnets in at least two zones.

## Routing Design

### Public subnets

Both public subnets share one route table. Its default route sends Internet-bound traffic to the Internet Gateway.

Public subnets set `map_public_ip_on_launch = true`, so instances launched into them receive a public IPv4 address automatically. AWS bills for public IPv4 addresses while they are in use. See `COSTS.md`.

### Private subnets

Each private subnet has its own route table containing only the local VPC route. Resources in private subnets cannot reach the Internet and cannot be reached from it.

Separate private route tables cost nothing and let a later advanced exercise add a per-zone NAT route without redesigning the network.

### Why there is no NAT Gateway

A NAT Gateway would give private subnets outbound Internet access, but it bills hourly even when idle, plus data processing charges. That would exceed the series cost target if left running. The baseline omits it.

## DNS

The VPC enables both `enable_dns_support` and `enable_dns_hostnames`. Later labs depend on these settings for RDS endpoint names, VPC interface endpoints, and Systems Manager connectivity.

## Outputs for Later Labs

Later labs consume these outputs instead of creating their own VPC:

| Output | Used for |
|---|---|
| `vpc_id` | Placing security groups and resources in this VPC |
| `vpc_cidr` | Writing security group rules scoped to the VPC |
| `public_subnet_ids` | EC2 web servers and the Application Load Balancer |
| `private_subnet_ids` | Private application servers and RDS subnet groups |

Additional outputs support validation:

```text
public_subnet_cidrs
private_subnet_cidrs
availability_zones
internet_gateway_id
public_route_table_id
private_route_table_ids
```

## Not Included in the Baseline

The following are intentionally out of scope for Lab 1:

- NAT Gateway
- VPC Flow Logs
- Custom network ACLs (the VPC default network ACL is used)
- IPv6
- VPC endpoints
- VPC peering or Transit Gateway connectivity

Each adds cost, complexity, or both, and is better introduced in the lab that needs it.
