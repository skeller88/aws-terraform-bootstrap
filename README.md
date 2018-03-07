# aws-terraform-bootstrap

## Overview
Bootstrap AWS infrastructure on top of Terraform and run a "hello_world" Python 3 app that uses the following AWS services:
* [Lambda](https://aws.amazon.com/lambda/) - cloud functions
* [VPC](https://aws.amazon.com/vpc/) - private network
* [S3](https://aws.amazon.com/s3/) - cloud file storage
* [RDS](https://aws.amazon.com/rds/) - cloud SQL database
* [Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-paramstore.html) - cloud storage for secrets

In addition, this repo helps you configure the following tools in your local environment:
* Postgres - SQL database
* Pyvenv - Python 3 virtual environment
* Terraform - infrastructure as code
* PyCharm - python IDE
* Nosetests - automated testing framework
* iPython on top of Anaconda - data analysis IDE 

At the end of this README, you will have done the following:
* deployed an app on AWS with Terraform
* set up the app to run locally
* set up your local machine to ssh into an EC2 [bastion host](https://www.techopedia.com/definition/6157/bastion-host), and connect to a RDS instance via psql. 

## Motivations
There are many blog posts, github repos, stack overflow posts, and AWS documentation that explain parts of how to build 
and deploy AWS infrastructure with Terraform, but no repo I've found that puts all of the concepts I wanted together and makes it 
quick and easy to set up an app on AWS and locally. I spent too much time reinventing the 
wheel and doing DevOps work. This repo automates as much of that work as possible and provides clear documentation for 
the rest of it.

## Why not just use a serverless framework?
[Cloud Formation](https://aws.amazon.com/cloudformation/) is AWS's framework for deploying serverless architectures. 
Like Terraform, it enables developers to write infrastructure as code. In addition, it abstracts away devops tasks such 
as lambda packaging, deployment, and monitoring. [Apex](https://github.com/apex/apex) is TJ Holowaychuk's version of CF
with 5500 users and counting as of March 4 2018. 
 
[Serverless](https://serverless.com/) is another framework that offers similar functionality, and abstracts away the
cloud provider to make an app built on top of it cloud provider independent.

I plan on learning a serverless framework in the future, but before learning those tools, I wanted to get more lower 
level experience with cloud computing devops. With that lower level experience, I am better equipped to understand
the components of cloud architectures, debug production issues, and understand the tradeoffs of the various severless
frameworks. Also, I wanted to learn an open source infrastructure as code framework, and Terraform is a leader in that space.

# Table of Contents
[Local Setup](#local-setup)  
[Set up Python environment](##set-up-python-environment)
[AWS Setup](#aws-setup)  

# Local setup 

## Set up Python environment
Virtual environments keep the app environment isolated from the OS environment. 

```
cd <aws-terraform-bootstrap-dir>
python3 -m venv venv
```

Depending on your OS and python version, an error may occur [due to a bug in pyvenv](https://askubuntu.com/questions/488529/pyvenv-3-4-error-returned-non-zero-exit-status-1). 
If that happens, install pip after creating the venv:

```
cd <aws-terraform-bootstrap-dir>
python3 -m venv venv --without-pip
source venv/bin/activate
curl https://bootstrap.pypa.io/get-pip.py | python
deactivate
source venv/bin/activate
```

Install dependencies
`pip install -r requirements.txt`

## Optional - Set up Python environment for ipython notebooks
Due to ipython requiring different dependencies from the app, a separate environment is configured via an environment.yml
file. 

[Install Anaconda for Python 3.6](https://www.anaconda.com/download/#macos).

[Create the "hello_world" environment from the environment.yml file](https://conda.io/docs/user-guide/tasks/manage-environments.html#creating-an-environment-from-an-environment-yml-file):

`conda env create -f environment.yml`

Start the Anaconda application and select the "hello_world" environment.

## Set up Pycharm
Set the python binary in the `venv` virtual environment [as the project interpreter](https://www.jetbrains.com/help/pycharm/configuring-python-interpreter.html#local-interpreter). 

[Set NoseTests as the test runner](https://www.jetbrains.com/help/pycharm/python-integrated-tools.html) so 
that tests can be run from Pycharm. 

## Set environment variables:
Copy the environment variables in `.bash_profile.sample` to the local `~/.bash_profile` file, and modify them with the proper
values for the local environment. Make sure the file is not committed to version control so the secrets are safe. 

Look at the "environment.variables" property of the lambda configurations in terraform/lambda.tf for an understanding of the 
variables used in production. Parameter store is used to populate other env variables not seen in the
terraform configuration. 

## PostgreSQL
Install postgres [directly](https://www.postgresql.org/download/) or via [homebrew](https://brew.sh/):
`brew install postgresql`

Using the Terminal, login to Postgres via superuser:

`psql`
 
and create a role, <username>. `hellorole` is the production database role, FYI. 
```
CREATE ROLE <username> WITH PASSWORD '<password>';
ALTER ROLE <username> CREATEDB; 
```
Choose a different password from your superuser password. The reason you create a new role is so that your superuser 
credentials are less likely to be compromised. 

Then create the database and connect to it with the new user:
```
createdb hello_word;
psql -U <username> -d hello_world
```
[Refer to this article on setting up PostgreSQL](https://www.codementor.io/engineerapart/getting-started-with-postgresql-on-mac-osx-are8jcopb)for 
a more detailed explanation of the process. In order to perform additional actions from the command line, further
permissions for the role may be needed.

# AWS setup
## Set up AWS credentials
Do not use your default/admin AWS credentials, because that user has root access, and using API keys for that user in the app
makes it more likely that the keys will be compromised. Instead, [create an IAM user with more limited permissions for the app](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html).
The user should have the following policies attached:
- AmazonEC2FullAccess
- AWSLambdaFullAccess
- AmazonRDSFullAccess
- AmazonS3FullAccess
- AmazonSSMFullAccess

and the user should also have the following inline policy, which gives it the ability to manage IAM roles.
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1482712489000",
            "Effect": "Allow",
            "Action": [
                "iam:*"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
```

[Set up boto](http://boto3.readthedocs.io/en/latest/guide/configuration.html) by creating a `~/.aws/credentials` file
with the following format:
```
[hello_world]
aws_access_key_id = <app-access-key-id>
aws_secret_access_key = <app-secret-access-key>
region=<desired-aws-region>
```

Create a parent `.aws` folder if necessary.

Export the following environment variable so boto knows which credentials to use:

`EXPORT AWS_PROFILE=hello_world`

## Setup Terraform and AWS credentials for Terraform
[Set up Terraform](https://www.terraform.io/intro/getting-started/install.html)

[Create a Terraform IAM user](https://console.aws.amazon.com/iam/home?region=us-west-1#/users), which provides Terraform 
with access to AWS resources, but not root access, which can be abused. The Terraform user should have the same policies
attached as the app user.

Add the Terraform secret and key created for the IAM user to the `~/.aws/credentials` file:
```
[terraform]
aws_access_key_id = <terraform-access-key-id>
aws_secret_access_key = <terraform-admin-access-secret>
```

Initialize Terraform

```
cd terraform
terraform init
```

## Create and configure key pair
A key pair is needed in order to ssh into the bastion host from a local machine. Create a new key pair named 
"bastion_host"  via the [AWS console](https://us-west-1.console.aws.amazon.com/ec2/v2/home?region=us-west-1#KeyPairs:sort=keyName) and the .pem file
containing the private key will automatically be saved. Change the permissions of the .pem file to make sure that your private key file isn't publicly viewable:

`chmod 400 ~/.aws/<pem-file-name>`

Move the .pem file to the `~/.aws` folder. AWS has [a more detailed explanation of key pairs.](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#retrieving-the-public-key)

## Add app secrets to AWS Parameter Store
Create a dummy app secret; any string will do. 

Go to the [parameter store console](https://us-west-1.console.aws.amazon.com/systems-manager/parameters/) and add a new 
parameter with the name 'secret'. Save it as a "SecureString". 

## Package AWS lambda and deploy Terraform infrastructure
Run `terraform apply` to build the terraform infrastructure. 

`deploy_lambda.sh hello_world` builds a zipfile for the lambda function and runs `terraform apply`

## Add your local IP address to the allowed IP addresses of the VPC
An AWS help desk recommended way to enable access to the bastion host from your local machine is to go to
[the VPC console](https://us-west-1.console.aws.amazon.com/vpc/home?region=us-west-1#vpcs) and add a CIDR block containing your IP
address to the VPC settings. 

## ssh to bastion host
Before ssh'ing to the RDS instance, try ssh'ing to the bastion host. 
`bastion_ec2_public_address` is output to the terminal by Terraform. Copy it and modify the script below:
`ssh -i ~/.aws/bastion_host.pem ec2-user@<bastion_ec2_public_address>`

## Create ssh tunnel to RDS instance
[detailed instructions](https://userify.com/blog/howto-connect-mysql-ec2-ssh-tunnel-rds/)

After `terraform apply` runs in the terminal, the id of the bastion ec2 instance will be printed to sdout. Copy and
paste the id into the script below. 

In one terminal window, create the ssh tunnel:

`ssh -L 8000:<rds-host-address>:5432 -i ~/.aws/bastion_host.pem ec2-user@<bastion_ec2_public_address>`

Then in another window, connect to the RDS instance:
`psql --dbname=hello_world --user=hellorole --host=localhost --port=8000` 


## Destroy infrastructure with Terraform
[Terraform documentation on destroy](https://www.terraform.io/intro/getting-started/destroy.html)

# Future work 
Contributions to this repo are welcome. Future work can include:
- A hello_world Docker app, deployed in an ECS cluster.
- CI and CD process.
- Logging, monitoring, alerting via AWS or some third party tool.
- At a certain size, lambda deployment packages have to be uploaded to a S3 bucket before deployment. Add support for that. 
- Increase the availability of the architecture by adding duplicate services to additional availability zones. For example,
there's only one NAT in one AZ. 
- Ansible script to automate local setup, such as creation of postgres user and database.
- Use [Terraform Vault](https://www.terraform.io/docs/providers/vault/index.html) to store secrets and passwords instead of a local .bash_profile file. 
- Microservices.
- "hello_world" versions of other AWS services such as Kinesis, SQS, and Dynamo. 