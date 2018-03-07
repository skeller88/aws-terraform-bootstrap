provider "aws" {
  profile = "terraform"
  region  = "${var.aws_region}"
}
