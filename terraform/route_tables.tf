resource "aws_route_table" "private_region_1_az_1" {
  vpc_id = "${aws_vpc.hello_world.id}"

  tags {
    Name    = "hello-world private ${var.region_1_az_1} subnet route table"
    ENV     = "prod"
    Project = "hello-world"
  }
}

resource "aws_route_table" "private_region_1_az_2" {
  vpc_id = "${aws_vpc.hello_world.id}"

  tags {
    Name    = "hello-world private ${var.region_1_az_2} subnet route table"
    ENV     = "prod"
    Project = "hello-world"
  }
}

resource "aws_route" "private_region_1_az_1" {
  route_table_id         = "${aws_route_table.private_region_1_az_1.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.hello_world_private_region_1_az_1.id}"
}

resource "aws_route" "private_region_1_az_2" {
  route_table_id         = "${aws_route_table.private_region_1_az_2.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.hello_world_private_region_1_az_2.id}"
}

resource "aws_route_table" "hello_world_public" {
  vpc_id = "${aws_vpc.hello_world.id}"

  route {
    cidr_block = "${var.allow_all_cidr}"
    gateway_id = "${aws_internet_gateway.hello_world.id}"
  }

  tags {
    Name    = "hello-world public subnet route table"
    ENV     = "prod"
    Project = "hello-world"
  }
}

resource "aws_route_table_association" "hello_world_public_subnet_region_1_az_1" {
  subnet_id      = "${aws_subnet.hello_world_public_region_1_az_1.id}"
  route_table_id = "${aws_route_table.hello_world_public.id}"
}

resource "aws_route_table_association" "hello_world_private_subnet_region_1_az_1" {
  subnet_id      = "${aws_subnet.hello_world_private_region_1_az_1.id}"
  route_table_id = "${aws_route_table.private_region_1_az_1.id}"
}

resource "aws_route_table_association" "hello_world_private_subnet_region_1_az_2" {
  subnet_id      = "${aws_subnet.hello_world_private_region_1_az_2.id}"
  route_table_id = "${aws_route_table.private_region_1_az_2.id}"
}
