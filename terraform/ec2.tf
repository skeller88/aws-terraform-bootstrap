resource "aws_instance" "hello_world_bastion" {
  # Amazon Linux AMI 2017.09.1 (HVM), SSD Volume Type
  ami                    = "ami-824c4ee2"
  key_name               = "bastion_host"
  instance_type          = "t2.micro"
  subnet_id              = "${aws_subnet.hello_world_public_west_1a.id}"
  vpc_security_group_ids = ["${aws_security_group.hello_world_bastion_security_group.id}"]

  # EC2 instance must be in a public subnet
  subnet_id = "${aws_subnet.hello_world_public_west_1a.id}"

  tags {
    Name    = "hello_world bastion"
    Env     = "prod"
    Project = "hello_world"
  }
}