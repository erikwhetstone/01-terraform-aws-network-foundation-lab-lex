# Core outputs are consumed by later labs so they can reuse this network
# foundation instead of silently creating additional VPCs.

output "vpc_id" {
  description = "ID of the Lab 1 VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "IPv4 CIDR block assigned to the Lab 1 VPC."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the two public subnets."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the two private subnets."
  value       = aws_subnet.private[*].id
}

# These additional outputs make validation easier and help learners understand
# how the deployed AWS resources map back to the Terraform network design.

output "public_subnet_cidrs" {
  description = "IPv4 CIDR blocks assigned to the public subnets."
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "IPv4 CIDR blocks assigned to the private subnets."
  value       = aws_subnet.private[*].cidr_block
}

output "availability_zones" {
  description = "Availability Zones used by the public and private subnet pairs."
  value       = local.availability_zones
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway attached to the VPC."
  value       = aws_internet_gateway.this.id
}

output "public_route_table_id" {
  description = "ID of the route table used by both public subnets."
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "IDs of the private route tables. These tables have no default Internet route in the baseline lab."
  value       = aws_route_table.private[*].id
}
