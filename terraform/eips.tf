resource "aws_eip" "bastion" {
  instance = "${aws_instance.hello_world_bastion.id}"
  vpc      = true
}

resource "aws_eip" "hello_world_private_west_1" {
  vpc = true
}

output "bastion_ec2_public_dns" {
  value = "${aws_instance.hello_world_bastion.public_dns}"
}
