{
    "Version": "2012-10-17",
    "Id": "HelloWorldBucketPolicy",
    "Statement": [
        {
            "Sid": "AllowLambdas",
            "Effect": "Allow",
            "Principal": {
                  "AWS": "${lambda_role_arn}"
            },
            "Action": "s3:*",
            "Resource": "${hello_world_bucket_arn}"
        }
    ]
}