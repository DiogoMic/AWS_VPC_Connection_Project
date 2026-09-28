output "instance_profile_name" {
  value = aws_iam_instance_profile.ssm_instance_profile.name
}

output "site_a_vpc_id" {
  value = aws_vpc.site_a.id
}

output "site_a_vpc_cidr" {
  value = aws_vpc.site_a.cidr_block
}

output "site_a_subnet_id" {
  value = aws_subnet.site_a_private.id
}

output "site_a_route_table_id" {
  value = aws_route_table.site_a.id
}

output "site_a_security_group_id" {
  value = aws_security_group.site_a.id
}

output "site_a_instance_id" {
  value = aws_instance.site_a.id
}

output "site_a_instance_private_ip" {
  value = aws_instance.site_a.private_ip
}

output "site_b_vpc_id" {
  value = aws_vpc.site_b.id
}

output "site_b_vpc_cidr" {
  value = aws_vpc.site_b.cidr_block
}

output "site_b_subnet_id" {
  value = aws_subnet.site_b_private.id
}

output "site_b_route_table_id" {
  value = aws_route_table.site_b.id
}

output "site_b_security_group_id" {
  value = aws_security_group.site_b.id
}

output "site_b_instance_id" {
  value = aws_instance.site_b.id
}

output "site_b_instance_private_ip" {
  value = aws_instance.site_b.private_ip
}
