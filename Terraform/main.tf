provider "aws" {
  region  = "ap-southeast-1"
  profile = "AWSConsultant@2023"
}

module "primarysite" {
  source             = "./VPCSite"
  site_name          = "apollo_site"
  peer_site_name     = "gemini_site"
  availability_zone1 = "ap-southeast-1a"
  availability_zone2 = "ap-southeast-1b"
  VPC_CIDR           = "10.0.0.0/16"
  Public_CIDR1       = "10.0.1.0/24"
  Public_CIDR2       = "10.0.2.0/24"
  Private_CIDR1      = "10.0.3.0/24"
  EC2_Size           = "t2.micro"
  AMI_ID             = "ami-0df7a207adb9748c7"
}

module "secondarysite" {
  source             = "./VPCSite"
  site_name          = "gemini_site"
  peer_site_name     = "apollo_site"
  availability_zone1 = "ap-southeast-1c"
  availability_zone2 = "ap-southeast-1a"
  VPC_CIDR           = "192.168.0.0/16"
  Public_CIDR1       = "192.168.1.0/24"
  Public_CIDR2       = "192.168.2.0/24"
  Private_CIDR1      = "192.168.3.0/24"
  EC2_Size           = "t2.micro"
  AMI_ID             = "ami-0df7a207adb9748c7"
}

resource "random_password" "openssl_random_password" {
  length  = 64
  special = false
}

resource "aws_ssm_parameter" "base64_encoded_random_password" {
  name  = "/strongswan/config/psk"
  type  = "SecureString"
  value = base64encode(random_password.openssl_random_password.result)
}