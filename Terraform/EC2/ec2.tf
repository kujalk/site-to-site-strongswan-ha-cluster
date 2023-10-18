#EC2 instance creation Public-1

resource "aws_instance" "master" {
  ami                    = var.AMI_ID
  instance_type          = var.EC2_Size
  subnet_id              = var.Public_SubnetID1
  vpc_security_group_ids = [aws_security_group.public.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  private_ip             = var.Master_private_ip
  source_dest_check      = false
  user_data = templatefile("EC2/master_userdata_script.tpl", {
    secondary_master_ip  = var.Secondary_Master_private_ip
    primarycidr          = var.Primary_cidr
    secondarycidr        = var.Secondary_cidr
    current_privateip    = var.Master_private_ip
    peer_privateip       = var.Follower_private_ip
    psk                  = var.Pre_Shared_Key
    pri_routetablename   = "${var.site_name}_Private_RouteTable"
    pub_routetablename   = "${var.site_name}_Public_RouteTable"
    secondary_tag        = var.Secondary_Site_name
    peering_id           = var.Peering_ID
    site2_routetablename = "${var.Secondary_Site_name}_Public_RouteTable"
  })

  tags = {
    Name     = "${var.site_name}_StrongSwan_Master"
    SiteName = "${var.site_name}"
    Env      = "Public"
  }
}

#EC2 instance creation Public-2
resource "aws_instance" "follower" {
  ami                    = var.AMI_ID
  instance_type          = var.EC2_Size
  subnet_id              = var.Public_SubnetID2
  private_ip             = var.Follower_private_ip
  vpc_security_group_ids = [aws_security_group.public.id]
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  user_data = templatefile("EC2/follower_userdata_script.tpl", {
    secondary_master_ip  = var.Secondary_Master_private_ip
    primarycidr          = var.Primary_cidr
    secondarycidr        = var.Secondary_cidr
    current_privateip    = var.Follower_private_ip
    peer_privateip       = var.Master_private_ip
    psk                  = var.Pre_Shared_Key
    pri_routetablename   = "${var.site_name}_Private_RouteTable"
    pub_routetablename   = "${var.site_name}_Public_RouteTable"
    secondary_tag        = var.Secondary_Site_name
    peering_id           = var.Peering_ID
    site2_routetablename = "${var.Secondary_Site_name}_Public_RouteTable"
  })

  tags = {
    Name     = "${var.site_name}_StrongSwan_Follower"
    SiteName = "${var.site_name}"
    Env      = "Public"
  }
}

#EC2 instance creation Private-1
resource "aws_instance" "EC-Private1" {
  ami                    = var.AMI_ID
  instance_type          = var.EC2_Size
  subnet_id              = var.Private_SubnetID1
  vpc_security_group_ids = [aws_security_group.private.id]

  tags = {
    Name     = "${var.site_name}_Private"
    SiteName = "${var.site_name}"
    Env      = "Private"
  }
}