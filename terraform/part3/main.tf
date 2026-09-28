###############################################################################
# VPC Lab - Part 3 (Terraform)
# Creates SITE_C-VPC and SITE_D-VPC (private subnets, no IGW/NAT/public IPs,
# with SSM interface endpoints - same pattern as Part 1), provisions a
# Transit Gateway, attaches all four VPCs (A, B, C, D) to it, builds an
# explicit TGW route table with per-VPC propagation, and updates every VPC's
# route table to send inter-VPC traffic to the TGW.
#
# IMPORTANT: Run `terraform destroy` in ../part2 BEFORE applying this
# config - see the deployment guide for the exact order of operations.
#
# Reads Part 1's outputs via a local terraform_remote_state lookup, so
# `terraform apply` in ../part1 must have been run first.
###############################################################################

data "terraform_remote_state" "part1" {
  backend = "local"

  config = {
    path = "${path.module}/../part1/terraform.tfstate"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

###############################################################################
# SITE_C-VPC (fully private - no IGW, no NAT, no public IPs)
###############################################################################
resource "aws_vpc" "site_c" {
  cidr_block           = var.site_c_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "SITE_C-VPC"
  }
}

resource "aws_subnet" "site_c_private" {
  vpc_id                  = aws_vpc.site_c.id
  cidr_block              = var.site_c_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "SITE_C-Private-Subnet"
  }
}

resource "aws_route_table" "site_c" {
  vpc_id = aws_vpc.site_c.id

  tags = {
    Name = "SITE_C-Private-RT"
  }
}

resource "aws_route_table_association" "site_c" {
  subnet_id      = aws_subnet.site_c_private.id
  route_table_id = aws_route_table.site_c.id
}

resource "aws_security_group" "site_c" {
  name        = "SITE_C-SG"
  description = "SITE_C instance SG - ICMP from the whole lab supernet, all egress"
  vpc_id      = aws_vpc.site_c.id

  ingress {
    description = "Allow ping from any VPC in this lab"
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = [var.lab_supernet_cidr]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SITE_C-SG"
  }
}

resource "aws_security_group" "site_c_endpoints" {
  name        = "SITE_C-Endpoint-SG"
  description = "SITE_C VPC interface endpoints SG - HTTPS from within the VPC"
  vpc_id      = aws_vpc.site_c.id

  ingress {
    description = "Allow HTTPS from SITE_C-VPC instances to the SSM endpoints"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = [var.site_c_cidr]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SITE_C-Endpoint-SG"
  }
}

resource "aws_vpc_endpoint" "site_c_ssm" {
  vpc_id              = aws_vpc.site_c.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.site_c_private.id]
  security_group_ids  = [aws_security_group.site_c_endpoints.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "site_c_ssmmessages" {
  vpc_id              = aws_vpc.site_c.id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.site_c_private.id]
  security_group_ids  = [aws_security_group.site_c_endpoints.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "site_c_ec2messages" {
  vpc_id              = aws_vpc.site_c.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.site_c_private.id]
  security_group_ids  = [aws_security_group.site_c_endpoints.id]
  private_dns_enabled = true
}

resource "aws_instance" "site_c" {
  ami                    = data.aws_ssm_parameter.al2023_ami.value
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.site_c_private.id
  vpc_security_group_ids = [aws_security_group.site_c.id]
  iam_instance_profile   = data.terraform_remote_state.part1.outputs.instance_profile_name

  tags = {
    Name = "SITE_C-Instance"
  }
}

###############################################################################
# SITE_D-VPC (fully private - no IGW, no NAT, no public IPs)
###############################################################################
resource "aws_vpc" "site_d" {
  cidr_block           = var.site_d_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "SITE_D-VPC"
  }
}

resource "aws_subnet" "site_d_private" {
  vpc_id                  = aws_vpc.site_d.id
  cidr_block              = var.site_d_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "SITE_D-Private-Subnet"
  }
}

resource "aws_route_table" "site_d" {
  vpc_id = aws_vpc.site_d.id

  tags = {
    Name = "SITE_D-Private-RT"
  }
}

resource "aws_route_table_association" "site_d" {
  subnet_id      = aws_subnet.site_d_private.id
  route_table_id = aws_route_table.site_d.id
}

resource "aws_security_group" "site_d" {
  name        = "SITE_D-SG"
  description = "SITE_D instance SG - ICMP from the whole lab supernet, all egress"
  vpc_id      = aws_vpc.site_d.id

  ingress {
    description = "Allow ping from any VPC in this lab"
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = [var.lab_supernet_cidr]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SITE_D-SG"
  }
}

resource "aws_security_group" "site_d_endpoints" {
  name        = "SITE_D-Endpoint-SG"
  description = "SITE_D VPC interface endpoints SG - HTTPS from within the VPC"
  vpc_id      = aws_vpc.site_d.id

  ingress {
    description = "Allow HTTPS from SITE_D-VPC instances to the SSM endpoints"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = [var.site_d_cidr]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SITE_D-Endpoint-SG"
  }
}

resource "aws_vpc_endpoint" "site_d_ssm" {
  vpc_id              = aws_vpc.site_d.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.site_d_private.id]
  security_group_ids  = [aws_security_group.site_d_endpoints.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "site_d_ssmmessages" {
  vpc_id              = aws_vpc.site_d.id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.site_d_private.id]
  security_group_ids  = [aws_security_group.site_d_endpoints.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "site_d_ec2messages" {
  vpc_id              = aws_vpc.site_d.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.site_d_private.id]
  security_group_ids  = [aws_security_group.site_d_endpoints.id]
  private_dns_enabled = true
}

resource "aws_instance" "site_d" {
  ami                    = data.aws_ssm_parameter.al2023_ami.value
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.site_d_private.id
  vpc_security_group_ids = [aws_security_group.site_d.id]
  iam_instance_profile   = data.terraform_remote_state.part1.outputs.instance_profile_name

  tags = {
    Name = "SITE_D-Instance"
  }
}

###############################################################################
# Transit Gateway + explicit route table (no default association/propagation
# so every attachment/route below is created intentionally, for clarity)
###############################################################################
resource "aws_ec2_transit_gateway" "lab" {
  description                     = "VPC Lab Transit Gateway connecting SITE_A/B/C/D"
  amazon_side_asn                 = 64512
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                     = "enable"
  vpn_ecmp_support                = "enable"

  tags = {
    Name = "VpcLab-TGW"
  }
}

resource "aws_ec2_transit_gateway_route_table" "lab" {
  transit_gateway_id = aws_ec2_transit_gateway.lab.id

  tags = {
    Name = "VpcLab-TGW-RouteTable"
  }
}

# --- Attachments (one per VPC) ---
resource "aws_ec2_transit_gateway_vpc_attachment" "site_a" {
  transit_gateway_id = aws_ec2_transit_gateway.lab.id
  vpc_id             = data.terraform_remote_state.part1.outputs.site_a_vpc_id
  subnet_ids         = [data.terraform_remote_state.part1.outputs.site_a_subnet_id]

  tags = {
    Name = "SITE_A-TGW-Attachment"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "site_b" {
  transit_gateway_id = aws_ec2_transit_gateway.lab.id
  vpc_id             = data.terraform_remote_state.part1.outputs.site_b_vpc_id
  subnet_ids         = [data.terraform_remote_state.part1.outputs.site_b_subnet_id]

  tags = {
    Name = "SITE_B-TGW-Attachment"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "site_c" {
  transit_gateway_id = aws_ec2_transit_gateway.lab.id
  vpc_id             = aws_vpc.site_c.id
  subnet_ids         = [aws_subnet.site_c_private.id]

  tags = {
    Name = "SITE_C-TGW-Attachment"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "site_d" {
  transit_gateway_id = aws_ec2_transit_gateway.lab.id
  vpc_id             = aws_vpc.site_d.id
  subnet_ids         = [aws_subnet.site_d_private.id]

  tags = {
    Name = "SITE_D-TGW-Attachment"
  }
}

# --- Associate each attachment with the explicit TGW route table ---
resource "aws_ec2_transit_gateway_route_table_association" "site_a" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.site_a.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.lab.id
}

resource "aws_ec2_transit_gateway_route_table_association" "site_b" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.site_b.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.lab.id
}

resource "aws_ec2_transit_gateway_route_table_association" "site_c" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.site_c.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.lab.id
}

resource "aws_ec2_transit_gateway_route_table_association" "site_d" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.site_d.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.lab.id
}

# --- Propagate each VPC's CIDR into the TGW route table ---
resource "aws_ec2_transit_gateway_route_table_propagation" "site_a" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.site_a.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.lab.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "site_b" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.site_b.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.lab.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "site_c" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.site_c.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.lab.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "site_d" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.site_d.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.lab.id
}

###############################################################################
# VPC route table updates: send lab-supernet traffic to the TGW.
###############################################################################
resource "aws_route" "site_a_to_tgw" {
  route_table_id         = data.terraform_remote_state.part1.outputs.site_a_route_table_id
  destination_cidr_block = var.lab_supernet_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.lab.id

  depends_on = [aws_ec2_transit_gateway_route_table_association.site_a]
}

resource "aws_route" "site_b_to_tgw" {
  route_table_id         = data.terraform_remote_state.part1.outputs.site_b_route_table_id
  destination_cidr_block = var.lab_supernet_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.lab.id

  depends_on = [aws_ec2_transit_gateway_route_table_association.site_b]
}

resource "aws_route" "site_c_to_tgw" {
  route_table_id         = aws_route_table.site_c.id
  destination_cidr_block = var.lab_supernet_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.lab.id

  depends_on = [aws_ec2_transit_gateway_route_table_association.site_c]
}

resource "aws_route" "site_d_to_tgw" {
  route_table_id         = aws_route_table.site_d.id
  destination_cidr_block = var.lab_supernet_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.lab.id

  depends_on = [aws_ec2_transit_gateway_route_table_association.site_d]
}
