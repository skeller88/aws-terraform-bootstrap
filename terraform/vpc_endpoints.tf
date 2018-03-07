# VPC endpoints
# Currently unnecessary because the lambda requires internet access, so a NAT gateway is needed.
# These endpoints would be useful if a lambda or EC2 instance did not need internet access, but needed to communicate
# with SSM and/or S3.
# Be careful as "Gateway" and "Interface" types require different configurations.
//resource "aws_vpc_endpoint" "s3" {
//  vpc_id       = "${aws_vpc.hello_world.id}"
//  service_name = "com.amazonaws.us-west-1.s3"
//  route_table_ids = ["${aws_route_table.hello_world_private_west_1a_subnet_route_table.id}",
//    "${aws_route_table.hello_world_private_west_1b_subnet_route_table.id}"]
//}
//
//resource "aws_vpc_endpoint" "ssm" {
//  vpc_id       = "${aws_vpc.hello_world.id}"
//  service_name = "com.amazonaws.us-west-1.ssm"
//  vpc_endpoint_type = "Interface"
//  security_group_ids = ["${aws_security_group.hello_world_lambda_vpc_security_group.id}"]
//  subnet_ids = ["${aws_subnet.hello_world_private_west_1a.id}", "${aws_subnet.hello_world_private_west_1b.id}"]
//}

