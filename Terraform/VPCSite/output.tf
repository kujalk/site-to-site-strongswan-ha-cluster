output "vpc_id" {
  value = aws_vpc.site.id
}

output "vpc_cidr" {
  value = var.VPC_CIDR
}

output "public_subnet1" {
  value = aws_subnet.site-public1.id
}

output "public_subnet2" {
  value = aws_subnet.site-public2.id
}

output "private_subnet1" {
  value = aws_subnet.site-private.id
}

output "eip_allocation_id" {
  value = aws_eip.primary.allocation_id
}

output "publicip" {
  value = aws_eip.primary.public_ip
}

output "site_name" {
  value = var.site_name
}