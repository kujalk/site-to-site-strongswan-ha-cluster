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

data "aws_route_tables" "rts" {
  vpc_id = var.VPC_Id

  filter {
    name   = "tag:Name"
    values = ["${var.site_name}_Public_RouteTable"]
  }
}

resource "aws_route" "publicroute" {
  route_table_id         = tolist(data.aws_route_tables.rts.ids)[0] #only 1 exist
  destination_cidr_block = var.Secondary_cidr
  network_interface_id   = aws_instance.master.primary_network_interface_id
}

resource "aws_route" "primaryviproute" {
  route_table_id         = tolist(data.aws_route_tables.rts.ids)[0] #only 1 exist
  destination_cidr_block = "${var.Primary_VIP}/32"
  network_interface_id   = aws_instance.master.primary_network_interface_id
}

resource "aws_route" "secondaryviproute" {
  route_table_id            = tolist(data.aws_route_tables.rts.ids)[0] #only 1 exist
  destination_cidr_block    = "${var.Secondary_VIP}/32"
  vpc_peering_connection_id = var.Peering_ID
}