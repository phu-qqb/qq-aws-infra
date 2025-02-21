output "aws_vpc" {
  value = aws_vpc.vpc
}

output "aws_subnets_trusted" {
  value = aws_subnet.subnets_trusted
}

output "aws_security_group_workspaces_qq" {
  value = aws_security_group.sg_workspaces_qq
}
