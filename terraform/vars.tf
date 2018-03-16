variable "allow_all_cidr" {
  default = "0.0.0.0/0"
}

variable "project_name" {
  default = "hello-world"
}

variable "region_1_az_1" {
  default = "us-west-1a"
}

variable "region_1_az_2" {
  default = "us-west-1b"
}

# Set via environment variables
# should be the same region as the region in the "region_*_az_*" variables
variable "aws_region" {}

variable "prod_db_password" {}
variable "repo_dir" {}
variable "storage_type" {}
