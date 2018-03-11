data "template_file" "bucket_policy" {
  template = "${file("./templates/policies/bucket_policy.tpl")}"

  vars {
    lambda_role_arn        = "${aws_iam_role.lambda_role.arn}"
    hello_world_bucket_arn = "${aws_s3_bucket.hello_world.arn}"
  }
}

data "template_file" "lambda_basic_execution_policy" {
  template = "${file("./templates/policies/lambda_basic_execution_policy.tpl")}"

  vars {
    aws_region = "${var.aws_region}"
  }
}
