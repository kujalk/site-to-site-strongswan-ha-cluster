#VPC 1 creation
#######################
resource "aws_vpc" "site" {
  cidr_block       = var.VPC_CIDR
  instance_tenancy = "default"

  tags = {
    Name = "${var.site_name}_VPC"
  }
}

#Creating a subnet-1
resource "aws_subnet" "site-public1" {
  vpc_id                  = aws_vpc.site.id
  cidr_block              = var.Public_CIDR1
  availability_zone       = var.availability_zone1
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.site_name}_Public_Subnet1"
  }
}

resource "aws_subnet" "site-public2" {
  vpc_id                  = aws_vpc.site.id
  cidr_block              = var.Public_CIDR2
  availability_zone       = var.availability_zone2
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.site_name}_Public_Subnet2"
  }
}

resource "aws_subnet" "site-private" {
  vpc_id                  = aws_vpc.site.id
  cidr_block              = var.Private_CIDR1
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.site_name}_site-private_Subnet1"
  }
}

#Create IWG
resource "aws_internet_gateway" "site" {
  vpc_id = aws_vpc.site.id

  tags = {
    Name = "${var.site_name}_IGW"
  }
}

#Route Table creation
resource "aws_route_table" "site" {
  vpc_id = aws_vpc.site.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.site.id
  }

  tags = {
    Name = "${var.site_name}_Public_RouteTable"
  }
}

#Associate the Route table with Subnet
resource "aws_route_table_association" "site-public-route1" {
  subnet_id      = aws_subnet.site-public1.id
  route_table_id = aws_route_table.site.id
}

resource "aws_route_table_association" "site-public-route2" {
  subnet_id      = aws_subnet.site-public2.id
  route_table_id = aws_route_table.site.id
}