resource "aws_lambda_function" "hello_world" {
  environment {
    variables = {
      ENV              = "prod"
      USE_AWS          = "True"
      DB_PASSWORD = "${aws_db_instance.hello_world.password}"
      DB_HOST_ADDRESS         = "${aws_db_instance.hello_world.address}"

      # Creates an implicit dependency on the hello_world s3 bucket
      # https://www.terraform.io/intro/getting-started/dependencies.html
      S3_BUCKET = "${aws_s3_bucket.hello_world.id}"

      STORAGE_TYPE = "${var.storage_type}"
    }
  }

  filename         = "${var.repo_dir}/dist/lambdas/hello_world.zip"
  function_name    = "hello_world_lambda"
  role             = "${aws_iam_role.lambda_role.arn}"
  handler          = "hello_world_lambda.main"
  source_code_hash = "${base64sha256(file("${var.repo_dir}/dist/lambdas/hello_world.zip"))}"
  runtime          = "python3.6"
  timeout          = 5

  vpc_config {
    security_group_ids = ["${aws_security_group.hello_world_lambda_vpc_security_group.id}"]
    subnet_ids         = ["${aws_subnet.hello_world_private_region_1_az_1.id}", "${aws_subnet.hello_world_private_region_1_az_2.id}"]
  }

  tags {
    Name    = "hello-world lambda"
    Env     = "prod"
    Project = "hello-world"
  }
}
