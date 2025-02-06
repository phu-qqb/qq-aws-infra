output "vpc_id" {
  value = aws_vpc.main.id
}

output "ad_directory_id" {
  value = aws_directory_service_directory.ad.id
}
