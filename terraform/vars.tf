variable "allow_all_cidr" {
  default = "0.0.0.0/0"
}

variable "project_name" {
  default = "hello-world"
}

# Set via environment variables
variable "aws_account_id" {}

variable "aws_region" {}
variable "prod_db_password" {}
variable "repo_dir" {}
variable "rds_host" {}
variable "storage_type" {}

output "aws_account_id_output" {
  value = "${var.aws_account_id}"
}
