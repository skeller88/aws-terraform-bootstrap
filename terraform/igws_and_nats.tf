# Internet gateway. An Internet gateway serves two purposes: to provide a target in your VPC route tables for
# Internet-routable traffic, and to perform network address translation (NAT) for instances that have been assigned
# public IPv4 addresses.
#
# In other words, an igw functions as a two-way NAT gateway.
resource "aws_internet_gateway" "hello_world" {
  vpc_id = "${aws_vpc.hello_world.id}"

  tags {
    Name    = "hello-world internet-gateway"
    ENV     = "prod"
    Project = "hello-world"
  }
}

# NAT
resource "aws_nat_gateway" "hello_world_private_region_1_az_1" {
  allocation_id = "${aws_eip.hello_world_private_region_1_az_1.id}"
  subnet_id     = "${aws_subnet.hello_world_public_region_1_az_1.id}"
  depends_on    = ["aws_internet_gateway.hello_world"]

  tags {
    Name    = "private ${var.region_1_az_1} nat"
    ENV     = "prod"
    Project = "hello-world"
  }
}

resource "aws_nat_gateway" "hello_world_private_region_1_az_2" {
  allocation_id = "${aws_eip.hello_world_private_region_1_az_2.id}"
  subnet_id     = "${aws_subnet.hello_world_public_region_1_az_1.id}"
  depends_on    = ["aws_internet_gateway.hello_world"]

  tags {
    Name    = "private ${var.region_1_az_2} nat"
    ENV     = "prod"
    Project = "hello-world"
  }
}

output "igw_id" {
  value = "${aws_internet_gateway.hello_world.id}"
}
