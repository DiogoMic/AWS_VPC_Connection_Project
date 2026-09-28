###
# VPC Lab - Part 1 (Terraform)
# Creates SITE_A-VPC and SITE_B-VPC, each with a private subnet
# and an EC2 instance managed via SSM. Since the
# instances have no internet route, each VPC gets its own SSM/SSMMessages/
# EC2Messages interface (PrivateLink) endpoints so the SSM Agent can reach
# Systems Manager entirely over the AWS private network.
##

data "aws_availability_zones" "available" {
  state = "available"
}

# Resolved dynamically so this works in any region without hardcoding an AMI ID.
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

##
# Shared IAM role for SSM (reused by every instance across all three parts)
##
resource "aws_iam_role" "ssm_instance_role" {
  name = "VpcLab-SSM-InstanceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "VpcLab-SSM-InstanceRole"
  }
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "VpcLab-SSM-InstanceProfile"
  role = aws_iam_role.ssm_instance_role.name
}

##
# SITE_A-VPC 
##
resource "aws_vpc" "site_a" {
  cidr_block           = var.site_a_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "SITE_A-VPC"
  }
}

resource "aws_subnet" "site_a_private" {
  vpc_id                  = aws_vpc.site_a.id
  cidr_block              = var.site_a_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "SITE_A-Private-Subnet"
  }
}

resource "aws_route_table" "site_a" {
  vpc_id = aws_vpc.site_a.id

  tags = {
    Name = "SITE_A-Private-RT"
  }
}

resource "aws_route_table_association" "site_a" {
  subnet_id      = aws_subnet.site_a_private.id
  route_table_id = aws_route_table.site_a.id
}

resource "aws_security_group" "site_a" {
  name        = "SITE_A-SG"
  description = "SITE_A instance SG - ICMP from the whole lab supernet, all egress"
  vpc_id      = aws_vpc.site_a.id

  ingress {
    description = "Allow ping from any VPC in this lab (10.0.0.0/16 - 10.3.0.0/16)"
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
    Name = "SITE_A-SG"
  }
}

# SG for the interface endpoints: only needs HTTPS from inside this VPC.
resource "aws_security_group" "site_a_endpoints" {
  name        = "SITE_A-Endpoint-SG"
  description = "SITE_A VPC interface endpoints SG - HTTPS from within the VPC"
  vpc_id      = aws_vpc.site_a.id

  ingress {
    description = "Allow HTTPS from SITE_A-VPC instances to the SSM endpoints"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = [var.site_a_cidr]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SITE_A-Endpoint-SG"
  }
}

# Interface (PrivateLink) endpoints so the SSM Agent can reach Systems
# Manager without any internet route. Private DNS is enabled so the agent's
# normal ssm.<region>.amazonaws.com hostnames resolve to these endpoints.
resource "aws_vpc_endpoint" "site_a_ssm" {
  vpc_id              = aws_vpc.site_a.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.site_a_private.id]
  security_group_ids  = [aws_security_group.site_a_endpoints.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "site_a_ssmmessages" {
  vpc_id              = aws_vpc.site_a.id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.site_a_private.id]
  security_group_ids  = [aws_security_group.site_a_endpoints.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "site_a_ec2messages" {
  vpc_id              = aws_vpc.site_a.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.site_a_private.id]
  security_group_ids  = [aws_security_group.site_a_endpoints.id]
  private_dns_enabled = true
}

resource "aws_instance" "site_a" {
  ami                    = data.aws_ssm_parameter.al2023_ami.value
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.site_a_private.id
  vpc_security_group_ids = [aws_security_group.site_a.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_instance_profile.name

  tags = {
    Name = "SITE_A-Instance"
  }
}

##
# SITE_B-VPC 
##
resource "aws_vpc" "site_b" {
  cidr_block           = var.site_b_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "SITE_B-VPC"
  }
}

resource "aws_subnet" "site_b_private" {
  vpc_id                  = aws_vpc.site_b.id
  cidr_block              = var.site_b_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "SITE_B-Private-Subnet"
  }
}

resource "aws_route_table" "site_b" {
  vpc_id = aws_vpc.site_b.id

  tags = {
    Name = "SITE_B-Private-RT"
  }
}

resource "aws_route_table_association" "site_b" {
  subnet_id      = aws_subnet.site_b_private.id
  route_table_id = aws_route_table.site_b.id
}

resource "aws_security_group" "site_b" {
  name        = "SITE_B-SG"
  description = "SITE_B instance SG - ICMP from the whole lab supernet, all egress"
  vpc_id      = aws_vpc.site_b.id

  ingress {
    description = "Allow ping from any VPC in this lab (10.0.0.0/16 - 10.3.0.0/16)"
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
    Name = "SITE_B-SG"
  }
}

resource "aws_security_group" "site_b_endpoints" {
  name        = "SITE_B-Endpoint-SG"
  description = "SITE_B VPC interface endpoints SG - HTTPS from within the VPC"
  vpc_id      = aws_vpc.site_b.id

  ingress {
    description = "Allow HTTPS from SITE_B-VPC instances to the SSM endpoints"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = [var.site_b_cidr]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SITE_B-Endpoint-SG"
  }
}

resource "aws_vpc_endpoint" "site_b_ssm" {
  vpc_id              = aws_vpc.site_b.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.site_b_private.id]
  security_group_ids  = [aws_security_group.site_b_endpoints.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "site_b_ssmmessages" {
  vpc_id              = aws_vpc.site_b.id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.site_b_private.id]
  security_group_ids  = [aws_security_group.site_b_endpoints.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "site_b_ec2messages" {
  vpc_id              = aws_vpc.site_b.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.site_b_private.id]
  security_group_ids  = [aws_security_group.site_b_endpoints.id]
  private_dns_enabled = true
}

resource "aws_instance" "site_b" {
  ami                    = data.aws_ssm_parameter.al2023_ami.value
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.site_b_private.id
  vpc_security_group_ids = [aws_security_group.site_b.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_instance_profile.name

  tags = {
    Name = "SITE_B-Instance"
  }
}
