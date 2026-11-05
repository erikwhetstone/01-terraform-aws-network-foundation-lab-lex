# The VPC provides an isolated network boundary for this lab and for
# infrastructure deployed by later labs in the training series.
resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.resource_name_prefix}-vpc"
  }
}

# The Internet Gateway provides the path to the Internet for resources using
# the public route table. Attaching an IGW does not make private subnets public.
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${local.resource_name_prefix}-igw"
  }
}

# Public subnets are intended for resources that require Internet-facing
# connectivity, such as the Application Load Balancer introduced later.
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = local.availability_zones[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name = "${local.resource_name_prefix}-public-${count.index + 1}"
    Tier = "Public"
  }
}

# Private subnets intentionally do not assign public IPv4 addresses. Later
# labs can place internal application and database resources in these subnets.
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = local.availability_zones[count.index]

  map_public_ip_on_launch = false

  tags = {
    Name = "${local.resource_name_prefix}-private-${count.index + 1}"
    Tier = "Private"
  }
}

# Both public subnets share a route table whose default IPv4 route points to
# the Internet Gateway.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${local.resource_name_prefix}-public-rt"
    Tier = "Public"
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Each private subnet receives its own route table so later labs can extend
# private routing independently. No default Internet route is created here.
resource "aws_route_table" "private" {
  count = length(aws_subnet.private)

  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${local.resource_name_prefix}-private-${count.index + 1}-rt"
    Tier = "Private"
  }
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
