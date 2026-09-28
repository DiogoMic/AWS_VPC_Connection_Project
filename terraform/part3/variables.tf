variable "aws_region" {
  description = "AWS region - must match the region Part 1 was deployed to."
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type for the lab instances."
  type        = string
  default     = "t3.micro"
}

variable "site_c_cidr" {
  description = "CIDR block for SITE_C-VPC."
  type        = string
  default     = "10.2.0.0/16"
}

variable "site_c_subnet_cidr" {
  description = "CIDR block for SITE_C's public subnet."
  type        = string
  default     = "10.2.1.0/24"
}

variable "site_d_cidr" {
  description = "CIDR block for SITE_D-VPC."
  type        = string
  default     = "10.3.0.0/16"
}

variable "site_d_subnet_cidr" {
  description = "CIDR block for SITE_D's public subnet."
  type        = string
  default     = "10.3.1.0/24"
}

variable "lab_supernet_cidr" {
  description = <<-EOT
    Supernet covering all four lab VPCs (10.0.0.0/16 - 10.3.0.0/16). Each VPC
    route table gets ONE route for this supernet pointed at the TGW; the
    VPC's own local /16 route always wins for same-VPC traffic because it's
    the more specific match (longest-prefix-match).
  EOT
  type        = string
  default     = "10.0.0.0/8"
}
