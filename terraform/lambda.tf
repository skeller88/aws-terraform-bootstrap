resource "aws_lambda_function" "hello_world" {
  environment {
    variables = {
      ENV              = "prod"
      WRITE_TO_AWS     = "True"
      STORAGE_TYPE     = "${var.storage_type}"
      PROD_DB_PASSWORD = "${var.prod_db_password}"
      RDS_HOST         = "${var.rds_host}"

      # Creates an implicit dependency on the hello_world s3 bucket
      # https://www.terraform.io/intro/getting-started/dependencies.html
      S3_BUCKET = "${aws_s3_bucket.hello_world.id}"
    }
  }

  filename         = "${var.repo_dir}/dist/lambdas/hello_world.zip"
  function_name    = "hello_world"
  role             = "${aws_iam_role.lambda_role.arn}"
  handler          = "hello_world.main"
  source_code_hash = "${base64sha256(file("${var.repo_dir}/dist/lambdas/hello_world.zip"))}"
  runtime          = "python3.6"
  timeout          = 5

  vpc_config {
    security_group_ids = ["${aws_security_group.hello_world_lambda_vpc_security_group.id}"]
    subnet_ids         = ["${aws_subnet.hello_world_private_west_1a.id}", "${aws_subnet.hello_world_private_west_1b.id}"]
  }

  tags {
    Name    = "hello-world lambda"
    Env     = "prod"
    Project = "hello-world"
  }
}
