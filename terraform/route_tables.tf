resource "aws_route_table" "hello_world_private_west_1a_subnet_route_table" {
  vpc_id = "${aws_vpc.hello_world.id}"

  tags {
    Name    = "hello-world private west 1a subnet route table"
    ENV     = "prod"
    Project = "hello-world"
  }
}

resource "aws_route_table" "hello_world_private_west_1b_subnet_route_table" {
  vpc_id = "${aws_vpc.hello_world.id}"

  tags {
    Name    = "hello-world private west 1b subnet route table"
    ENV     = "prod"
    Project = "hello-world"
  }
}

resource "aws_route" "private_route_west_1a" {
  route_table_id         = "${aws_route_table.hello_world_private_west_1a_subnet_route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.hello_world_private_west_1.id}"
}

resource "aws_route" "private_route_west_1b" {
  route_table_id         = "${aws_route_table.hello_world_private_west_1b_subnet_route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.hello_world_private_west_1.id}"
}

resource "aws_route_table" "hello_world_public_subnet_route_table" {
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

resource "aws_route_table_association" "hello_world_public_west_1a_route_table" {
  subnet_id      = "${aws_subnet.hello_world_public_west_1a.id}"
  route_table_id = "${aws_route_table.hello_world_public_subnet_route_table.id}"
}

resource "aws_route_table_association" "hello_world_private_west_1a_subnet" {
  subnet_id      = "${aws_subnet.hello_world_private_west_1a.id}"
  route_table_id = "${aws_route_table.hello_world_private_west_1a_subnet_route_table.id}"
}

resource "aws_route_table_association" "hello_world_private_west_1b_subnet" {
  subnet_id      = "${aws_subnet.hello_world_private_west_1b.id}"
  route_table_id = "${aws_route_table.hello_world_private_west_1b_subnet_route_table.id}"
}
