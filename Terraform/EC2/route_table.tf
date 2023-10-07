resource "aws_route_table" "private" {
  vpc_id = var.VPC_Id

  route {
    cidr_block           = var.Secondary_cidr
    network_interface_id = aws_instance.master.primary_network_interface_id
  }

  tags = {
    Name = "${var.site_name}_Private_RouteTable"
  }
}

#Associate the Route table with Subnet
resource "aws_route_table_association" "site-private-route1" {
  subnet_id      = var.Private_SubnetID1
  route_table_id = aws_route_table.private.id
}