provider "aws" {
  region  = "ap-southeast-1"
  profile = "AWSConsultant@2023"
}

module "primarysite" {
  source             = "./VPCSite"
  site_name          = "cuba_site"
  availability_zone1 = "ap-southeast-1a"
  availability_zone2 = "ap-southeast-1b"
  VPC_CIDR           = "10.0.0.0/16"
  Public_CIDR1       = "10.0.1.0/24"
  Public_CIDR2       = "10.0.2.0/24"
  Private_CIDR1      = "10.0.3.0/24"
}

module "secondarysite" {
  source             = "./VPCSite"
  site_name          = "thailand_site"
  availability_zone1 = "ap-southeast-1c"
  availability_zone2 = "ap-southeast-1a"
  VPC_CIDR           = "192.168.0.0/17"
  Public_CIDR1       = "192.168.1.0/24"
  Public_CIDR2       = "192.168.2.0/24"
  Private_CIDR1      = "192.168.3.0/24"
}

resource "random_password" "openssl_random_password" {
  length  = 64
  special = false
}

#VPC Peering connection
resource "aws_vpc_peering_connection" "peer" {
  peer_vpc_id = module.primarysite.vpc_id
  vpc_id      = module.secondarysite.vpc_id
  auto_accept = true

  tags = {
    Name = "VPC Peering between primary site ${module.primarysite.site_name} and secondary site ${module.secondarysite.site_name} for ipsec connectivity simulation"
  }
}

module "primarysiteec2" {

  depends_on                    = [module.primarysite]
  source                        = "./EC2"
  site_name                     = module.primarysite.site_name
  EC2_Size                      = "t2.micro"
  AMI_ID                        = "ami-0df7a207adb9748c7"
  VPC_Id                        = module.primarysite.vpc_id
  Master_private_ip             = "10.0.1.5"
  Follower_private_ip           = "10.0.2.5"
  Pre_Shared_Key                = base64encode(random_password.openssl_random_password.result)
  Public_SubnetID1              = module.primarysite.public_subnet1
  Public_SubnetID2              = module.primarysite.public_subnet2
  Private_SubnetID1             = module.primarysite.private_subnet1
  Primary_cidr                  = module.primarysite.vpc_cidr
  Secondary_cidr                = module.secondarysite.vpc_cidr
  Secondary_Master_private_ip   = "192.168.1.15"
  Secondary_Follower_private_ip = "192.168.2.15"
  Secondary_Site_name           = module.secondarysite.site_name
  Peering_ID                    = aws_vpc_peering_connection.peer.id
}

module "secondarysiteec2" {

  depends_on                    = [module.secondarysite]
  source                        = "./EC2"
  site_name                     = module.secondarysite.site_name
  EC2_Size                      = "t2.micro"
  AMI_ID                        = "ami-0df7a207adb9748c7"
  VPC_Id                        = module.secondarysite.vpc_id
  Master_private_ip             = "192.168.1.15"
  Follower_private_ip           = "192.168.2.15"
  Pre_Shared_Key                = base64encode(random_password.openssl_random_password.result)
  Public_SubnetID1              = module.secondarysite.public_subnet1
  Public_SubnetID2              = module.secondarysite.public_subnet2
  Private_SubnetID1             = module.secondarysite.private_subnet1
  Primary_cidr                  = module.secondarysite.vpc_cidr
  Secondary_cidr                = module.primarysite.vpc_cidr
  Secondary_Master_private_ip   = "10.0.1.5"
  Secondary_Follower_private_ip = "10.0.2.5"
  Secondary_Site_name           = module.primarysite.site_name
  Peering_ID                    = aws_vpc_peering_connection.peer.id
}