#Security Group public
resource "aws_security_group" "public" {
  name        = "${var.site_name}_EC2_Public_SecurityGroup"
  description = "${var.site_name} : To allow HTTP and SSH Traffic"
  vpc_id      = aws_vpc.site.id


  tags = {
    Name = "${var.site_name}_EC2_SecurityGroup"
  }

  ingress {
    description = "${var.site_name} : SSH Traffic Allow"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "${var.site_name} : Outside"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Security Group private
resource "aws_security_group" "private" {
  name        = "${var.site_name}_EC2_Private_SecurityGroup"
  description = "${var.site_name} : To allow Ping requests"
  vpc_id      = aws_vpc.site.id


  tags = {
    Name = "${var.site_name}_EC2_Private_SecurityGroup"
  }

  ingress {
    description = "${var.site_name} : Ping Traffic Allow"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Outside"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}
