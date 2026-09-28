###############################################################################
# VPC Lab - Part 2 (Terraform)
# Peers SITE_A-VPC and SITE_B-VPC and adds the routes each side needs to
# reach the other's CIDR through the peering connection.
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

resource "aws_vpc_peering_connection" "site_a_to_site_b" {
  vpc_id      = data.terraform_remote_state.part1.outputs.site_a_vpc_id
  peer_vpc_id = data.terraform_remote_state.part1.outputs.site_b_vpc_id
  auto_accept = true

  tags = {
    Name = "SITE_A-to-SITE_B-Peering"
  }
}

# Route in SITE_A's route table: traffic to SITE_B's CIDR -> peering connection
resource "aws_route" "site_a_to_site_b" {
  route_table_id            = data.terraform_remote_state.part1.outputs.site_a_route_table_id
  destination_cidr_block    = data.terraform_remote_state.part1.outputs.site_b_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.site_a_to_site_b.id
}

# Route in SITE_B's route table: traffic to SITE_A's CIDR -> peering connection
resource "aws_route" "site_b_to_site_a" {
  route_table_id            = data.terraform_remote_state.part1.outputs.site_b_route_table_id
  destination_cidr_block    = data.terraform_remote_state.part1.outputs.site_a_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.site_a_to_site_b.id
}
