variable "aws_region" {
  description = "AWS Region where the network foundation will be deployed."
  type        = string
}

variable "expected_aws_account_id" {
  description = "AWS account ID expected for this deployment. Used as a safety guardrail against deploying into the wrong account."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.expected_aws_account_id))
    error_message = "expected_aws_account_id must contain exactly 12 digits."
  }
}

variable "owner_name" {
  description = "Learner or administrator responsible for this deployment."
  type        = string

  validation {
    condition     = length(trimspace(var.owner_name)) > 0
    error_message = "owner_name must not be empty."
  }
}

variable "deployment_id" {
  description = "Unique identifier for this lab deployment."
  type        = string

  validation {
    condition     = length(trimspace(var.deployment_id)) > 0
    error_message = "deployment_id must not be empty."
  }
}

variable "expiration_date" {
  description = "Expected cleanup date for this training deployment in YYYY-MM-DD format."
  type        = string

  validation {
    condition     = can(regex("^\\d{4}-\\d{2}-\\d{2}$", var.expiration_date))
    error_message = "expiration_date must use YYYY-MM-DD format."
  }
}

variable "project_name" {
  description = "Generic project identifier used when naming and tagging resources."
  type        = string
  default     = "terraform-aws-security-training"
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block assigned to the training VPC."
  type        = string
  default     = "10.42.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_cidrs" {
  description = "IPv4 /24 CIDR blocks for the two public subnets."
  type        = list(string)

  default = [
    "10.42.10.0/24",
    "10.42.20.0/24",
  ]

  validation {
    condition = (
      length(var.public_subnet_cidrs) == 2 &&
      alltrue([
        for cidr in var.public_subnet_cidrs :
        can(cidrnetmask(cidr))
      ])
    )
    error_message = "public_subnet_cidrs must contain exactly two valid IPv4 CIDR blocks."
  }

  validation {
    condition = alltrue([
      for cidr in var.public_subnet_cidrs :
      try(split("/", cidr)[1] == "24", false)
    ])
    error_message = "Each public subnet must use a /24 prefix for this lab."
  }

  validation {
    condition     = length(distinct(var.public_subnet_cidrs)) == 2
    error_message = "Each public subnet CIDR must be unique."
  }
}

variable "private_subnet_cidrs" {
  description = "IPv4 /24 CIDR blocks for the two private subnets."
  type        = list(string)

  default = [
    "10.42.110.0/24",
    "10.42.120.0/24",
  ]

  validation {
    condition = (
      length(var.private_subnet_cidrs) == 2 &&
      alltrue([
        for cidr in var.private_subnet_cidrs :
        can(cidrnetmask(cidr))
      ])
    )
    error_message = "private_subnet_cidrs must contain exactly two valid IPv4 CIDR blocks."
  }

  validation {
    condition = alltrue([
      for cidr in var.private_subnet_cidrs :
      try(split("/", cidr)[1] == "24", false)
    ])
    error_message = "Each private subnet must use a /24 prefix for this lab."
  }

  validation {
    condition     = length(distinct(var.private_subnet_cidrs)) == 2
    error_message = "Each private subnet CIDR must be unique."
  }
}
