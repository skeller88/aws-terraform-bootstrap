resource "aws_db_instance" "hello_world" {
  allocated_storage    = 20
  backup_retention_period = 2
  db_subnet_group_name = "${aws_db_subnet_group.hello_world_db_subnet.id}"
  final_snapshot_identifier = "hello-world-final-snapshot"
  vpc_security_group_ids = ["${aws_security_group.hello_world_vpc_inbound.id}"]
  skip_final_snapshot = true
  # ssd
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "9.6.1"
  instance_class       = "db.t2.micro"
  name                 = "hello_world"
  username             = "hellorole"
  password             = "${var.prod_db_password}"
  publicly_accessible = true
  tags {
    Name = "postgres db"
    env = "prod"
    project = "hello-world"
  }
}

# https://stackoverflow.com/questions/7842782/perl-netamazons3-bucketalreadyexists-the-requested-bucket-name-is-not-avail
# In order to increase the chances that a bucket name is available, suffix with a random string
resource "random_string" "hello_world_bucket_name_suffix" {
  length = 10
  number = false
  special = false
  upper = false
}

resource "aws_s3_bucket" "hello_world" {
  bucket = "hello-world-${random_string.hello_world_bucket_name_suffix.id}"
  tags {
    env     = "prod"
    project = "hello-world"
  }
}

output "s3_bucket_name" {
  value = "${aws_s3_bucket.hello_world.id}"
}

output "aws_db_instance_address" {
  value = "${aws_db_instance.hello_world.address}"
}

output "aws_db_id" {
  value = "${aws_db_instance.hello_world.id}"
}