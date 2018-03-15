resource "aws_eip" "bastion" {
  instance = "${aws_instance.hello_world_bastion.id}"
  vpc      = true
}

resource "aws_eip" "hello_world_private_region_1_az_1" {
  vpc = true
}

resource "aws_eip" "hello_world_private_region_1_az_2" {
  vpc = true
}

output "bastion_ec2_public_ip" {
  value = "${aws_eip.bastion.public_ip}"
}
