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
resource "aws_nat_gateway" "hello_world_private_west_1" {
  tags {
    Name    = "private us-west-1b nat"
    ENV     = "prod"
    Project = "hello-world"
  }

  allocation_id = "${aws_eip.hello_world_private_west_1.id}"
  subnet_id     = "${aws_subnet.hello_world_public_west_1a.id}"
  depends_on    = ["aws_internet_gateway.hello_world"]
}

output "igw_id" {
  value = "${aws_internet_gateway.hello_world.id}"
}
