variable "aws_region" {
  description = "AWS region for all resources (all four lab VPCs live in this one region)."
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type for the lab instances."
  type        = string
  default     = "t3.micro"
}

variable "site_a_cidr" {
  description = "CIDR block for SITE_A-VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "site_a_subnet_cidr" {
  description = "CIDR block for SITE_A's public subnet."
  type        = string
  default     = "10.0.1.0/24"
}

variable "site_b_cidr" {
  description = "CIDR block for SITE_B-VPC."
  type        = string
  default     = "10.1.0.0/16"
}

variable "site_b_subnet_cidr" {
  description = "CIDR block for SITE_B's public subnet."
  type        = string
  default     = "10.1.1.0/24"
}

variable "lab_supernet_cidr" {
  description = "Supernet covering all four lab VPCs (10.0.0.0/16 - 10.3.0.0/16). Used for the ICMP security group rule so it doesn't need to change in later parts."
  type        = string
  default     = "10.0.0.0/8"
}
