resource "aws_ssm_parameter" "site-cidr" {
  name  = "/strongswan/config/${var.site_name}_cidr"
  type  = "String"
  value = var.VPC_CIDR
}

resource "aws_ssm_parameter" "site-publicip" {
  name  = "/strongswan/config/${var.site_name}_publicip"
  type  = "String"
  value = aws_instance.EC-Public1.public_ip
}

resource "aws_ssm_parameter" "site-privateip" {
  name  = "/strongswan/config/${var.site_name}_privateip"
  type  = "String"
  value = aws_instance.EC-Public1.private_ip
}