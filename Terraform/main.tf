provider "aws" {
  region  = "ap-southeast-1"
  profile = "AWSConsultant@2023"
}

module "primarysite" {
  source             = "./VPCSite"
  site_name          = "canada_site"
  availability_zone1 = "ap-southeast-1a"
  availability_zone2 = "ap-southeast-1b"
  VPC_CIDR           = "10.0.0.0/16"
  Public_CIDR1       = "10.0.1.0/24"
  Public_CIDR2       = "10.0.2.0/24"
  Private_CIDR1      = "10.0.3.0/24"
}

module "secondarysite" {
  source             = "./VPCSite"
  site_name          = "us_site"
  availability_zone1 = "ap-southeast-1c"
  availability_zone2 = "ap-southeast-1a"
  VPC_CIDR           = "192.168.0.0/16"
  Public_CIDR1       = "192.168.1.0/24"
  Public_CIDR2       = "192.168.2.0/24"
  Private_CIDR1      = "192.168.3.0/24"
}

resource "random_password" "openssl_random_password" {
  length  = 64
  special = false
}

module "primarysiteec2" {

  depends_on          = [module.primarysite]
  source              = "./EC2"
  site_name           = "canada_site"
  EC2_Size            = "t2.micro"
  AMI_ID              = "ami-0df7a207adb9748c7"
  VPC_Id              = module.primarysite.vpc_id
  EIP_Static_ID       = module.primarysite.eip_allocation_id
  Master_private_ip   = "10.0.1.5"
  Follower_private_ip = "10.0.2.5"
  Pre_Shared_Key      = base64encode(random_password.openssl_random_password.result)
  Public_SubnetID1    = module.primarysite.public_subnet1
  Public_SubnetID2    = module.primarysite.public_subnet2
  Private_SubnetID1   = module.primarysite.private_subnet1
  Primary_cidr        = module.primarysite.vpc_cidr
  Secondary_cidr      = module.secondarysite.vpc_cidr
  Primary_PublicIP    = module.primarysite.publicip
  Secondary_PublicIP  = module.secondarysite.publicip
}

module "secondarysiteec2" {

  depends_on          = [module.secondarysite]
  source              = "./EC2"
  site_name           = "us_site"
  EC2_Size            = "t2.micro"
  AMI_ID              = "ami-0df7a207adb9748c7"
  VPC_Id              = module.secondarysite.vpc_id
  EIP_Static_ID       = module.secondarysite.eip_allocation_id
  Master_private_ip   = "192.168.1.15"
  Follower_private_ip = "192.168.2.15"
  Pre_Shared_Key      = base64encode(random_password.openssl_random_password.result)
  Public_SubnetID1    = module.secondarysite.public_subnet1
  Public_SubnetID2    = module.secondarysite.public_subnet2
  Private_SubnetID1   = module.secondarysite.private_subnet1
  Primary_cidr        = module.secondarysite.vpc_cidr
  Secondary_cidr      = module.primarysite.vpc_cidr
  Primary_PublicIP    = module.secondarysite.publicip
  Secondary_PublicIP  = module.primarysite.publicip
}