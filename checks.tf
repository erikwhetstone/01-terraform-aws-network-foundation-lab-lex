# Reports an account mismatch in plain language. The blocking control is
# allowed_account_ids in provider.tf; a failed check only produces a warning.
check "expected_aws_account" {
  assert {
    condition     = data.aws_caller_identity.current.account_id == var.expected_aws_account_id
    error_message = "AWS account mismatch. The authenticated AWS account does not match expected_aws_account_id."
  }
}

# Lab 1 requires two Availability Zones so the public and private subnet pairs
# can demonstrate a basic multi-AZ network design.
check "minimum_availability_zones" {
  assert {
    condition     = length(data.aws_availability_zones.available.names) >= 2
    error_message = "This lab requires at least two available Availability Zones in the selected AWS Region."
  }
}

# Duplicate subnet CIDRs would cause AWS subnet creation to fail and usually
# indicate an accidental copy/paste error in the learner's network plan.
check "unique_public_subnet_cidrs" {
  assert {
    condition     = length(distinct(var.public_subnet_cidrs)) == length(var.public_subnet_cidrs)
    error_message = "Each public subnet CIDR must be unique."
  }
}

check "unique_private_subnet_cidrs" {
  assert {
    condition     = length(distinct(var.private_subnet_cidrs)) == length(var.private_subnet_cidrs)
    error_message = "Each private subnet CIDR must be unique."
  }
}

# A CIDR must not be reused between the public and private subnet groups.
check "public_private_cidrs_are_distinct" {
  assert {
    condition = length(setintersection(
      toset(var.public_subnet_cidrs),
      toset(var.private_subnet_cidrs)
    )) == 0

    error_message = "Public and private subnet CIDRs must be distinct."
  }
}

# Lab 1 deliberately teaches four distinct /24 networks. With a fixed /24
# prefix, unique network addresses guarantee that the subnet ranges do not
# overlap one another.
check "subnet_cidrs_do_not_overlap" {
  assert {
    condition = (
      length(distinct(local.subnet_network_addresses)) ==
      length(local.subnet_network_addresses)
    )

    error_message = "The public and private subnet CIDR blocks must not overlap."
  }
}

# A subnet is inside the VPC when its prefix is at least as long as the VPC
# prefix and it shares the VPC network address at the VPC prefix length.
# This avoids newer CIDR functions so it works on every supported version.
check "subnets_are_inside_vpc" {
  assert {
    condition = alltrue([
      for cidr in local.all_subnet_cidrs :
      tonumber(split("/", cidr)[1]) >= tonumber(split("/", var.vpc_cidr)[1]) &&
      cidrhost("${cidrhost(cidr, 0)}/${split("/", var.vpc_cidr)[1]}", 0) == cidrhost(var.vpc_cidr, 0)
    ])

    error_message = "Every public and private subnet CIDR must be contained within vpc_cidr."
  }
}
