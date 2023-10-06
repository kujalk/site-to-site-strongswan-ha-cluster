#EC2 instance creation Public-1
resource "aws_instance" "EC-Public1" {
  ami                    = var.AMI_ID
  instance_type          = var.EC2_Size
  subnet_id              = aws_subnet.site-public1.id
  vpc_security_group_ids = [aws_security_group.public.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  source_dest_check      = false
  user_data = templatefile("VPCSite/userdata_script.tpl", {
    primarysite   = var.site_name
    secondarysite = var.peer_site_name
  })

  tags = {
    Name     = "${var.site_name}_StrongSwan_Server"
    SiteName = "${var.site_name}"
    Env      = "Public"
  }
}

#EC2 instance creation Private-1
resource "aws_instance" "EC-Private1" {
  ami                    = var.AMI_ID
  instance_type          = var.EC2_Size
  subnet_id              = aws_subnet.site-private.id
  vpc_security_group_ids = [aws_security_group.private.id]

  tags = {
    Name     = "${var.site_name}_Private"
    SiteName = "${var.site_name}"
    Env      = "Private"
  }
}