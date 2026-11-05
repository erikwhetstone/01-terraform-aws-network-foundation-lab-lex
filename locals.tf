locals {
  lab_name = "network-foundation"

  # The lab uses at most two available AZs. If fewer than two exist, the plan
  # fails when the second subnet is indexed; checks.tf explains why.
  availability_zones = slice(
    data.aws_availability_zones.available.names,
    0,
    min(2, length(data.aws_availability_zones.available.names))
  )

  resource_name_prefix = "${local.lab_name}-${var.deployment_id}"

  all_subnet_cidrs = concat(
    var.public_subnet_cidrs,
    var.private_subnet_cidrs
  )

  # cidrhost(..., 0) normalizes each CIDR to its network address. Because Lab 1
  # requires /24 subnets, unique network addresses also guarantee that the four
  # training subnet ranges do not overlap with one another.
  subnet_network_addresses = [
    for cidr in local.all_subnet_cidrs :
    cidrhost(cidr, 0)
  ]
}
