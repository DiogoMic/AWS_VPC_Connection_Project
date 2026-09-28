output "transit_gateway_id" {
  value = aws_ec2_transit_gateway.lab.id
}

output "tgw_route_table_id" {
  value = aws_ec2_transit_gateway_route_table.lab.id
}

output "site_c_vpc_id" {
  value = aws_vpc.site_c.id
}

output "site_c_instance_id" {
  value = aws_instance.site_c.id
}

output "site_d_vpc_id" {
  value = aws_vpc.site_d.id
}

output "site_d_instance_id" {
  value = aws_instance.site_d.id
}
