Table of Contents
=================

   * [Table of Contents](#table-of-contents)
   * [Overview](#overview)
   * [Motivations](#motivations)
   * [Why not just use a serverless framework?](#why-not-just-use-a-serverless-framework)
   * [Architecture digram clarifications](#architecture-diagram-clarifications)
   * [Local setup](#local-setup)
      * [Repo](#repo)
      * [Python environment](#python-environment)
         * [Optional: Ipython notebooks](#optional-ipython-notebooks)
         * [Optional: Pycharm](#optional-pycharm)
      * [Environment variables](#environment-variables)
      * [PostgreSQL](#postgresql)
      * [Testing](#testing)
   * [AWS setup](#aws-setup)
      * [IAMs](#iams)
         * [App IAM user](#app-iam-user)
         * [Terraform IAM user](#terraform-iam-user)
      * [Boto](#boto)
      * [EC2 key pair](#ec2-key-pair)
      * [AWS Parameter Store](#aws-parameter-store)
      * [Remote access via bastion host](#remote-access-via-bastion-host)
         * [Add your local IP address to the allowed IP addresses of the VPC](#add-your-local-ip-address-to-the-allowed-ip-addresses-of-the-vpc)
         * [ssh to bastion host](#ssh-to-bastion-host)
         * [Create ssh tunnel to RDS instance](#create-ssh-tunnel-to-rds-instance)
   * [Package AWS lambda and deploy infrastructure with Terraform](#package-aws-lambda-and-deploy-infrastructure-with-terraform)
   * [Destroy infrastructure with Terraform](#destroy-infrastructure-with-terraform)
   * [Future work](#future-work)
     * [Planned](#planned)
     * [Backlog](#backlog)

Created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc) 
  

# Overview
Bootstrap AWS infrastructure on top of Terraform and run a "hello_world" Python 3 app that uses the following AWS services:
* [Lambda](https://aws.amazon.com/lambda/) - cloud functions
* [VPC](https://aws.amazon.com/vpc/) - private network
* [S3](https://aws.amazon.com/s3/) - cloud file storage
* [RDS](https://aws.amazon.com/rds/) - cloud SQL database
* [Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-paramstore.html) - cloud storage for secrets

![Architecture Diagram](architecture_diagram.jpg?raw=true)

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

# Motivations
There are many blog posts, github repos, stack overflow posts, and AWS documentation that explain parts of how to build 
and deploy AWS infrastructure with Terraform, but no repo I've found that puts all of the concepts I wanted together and makes it 
quick and easy to set up an app on AWS and locally. I spent too much time reinventing the 
wheel and doing DevOps work. This repo automates as much of that work as possible and provides clear documentation for 
the rest of it.

# Why not just use a serverless framework?
[Cloud Formation](https://aws.amazon.com/cloudformation/) is AWS's framework for deploying serverless architectures. 
Like Terraform, it enables developers to write infrastructure as code. In addition, it abstracts away DevOps tasks such 
as lambda packaging, deployment, and monitoring. [Apex](https://github.com/apex/apex) is [TJ Holowaychuk's](https://medium.com/@tjholowaychuk) version of CF.
 
[Serverless](https://serverless.com/) is another framework that offers similar functionality, as well as support for 
other cloud providers.

I plan on learning a serverless framework in the future, but before learning those tools, I wanted to get more lower 
level experience with cloud computing devops. With that lower level experience, I am better equipped to understand
the components of cloud architectures, debug production issues, and understand the tradeoffs of the various severless
frameworks. Also, I wanted to learn an open source infrastructure as code framework, and Terraform is a leader in that space.

# Architecture diagram clarifications
The above architecture diagram shows that the app is deployed in two private subnets and two public subnets across two
availability zones, one public and one private subnet per availability zone (AZ). The RDS instance is shown in one subnet 
only because it's a single AZ deployment. Multi-AZ deployments are higher cost, and unnecessary for a bootstrap app
like this one. It's easy to configure though if an app needs that increased uptime. 

The lambda is shown in both private subnets because it can be run in either subnet. If one is available and one is down,
for example, the lambda will be run in the subnet that is up. Since the lambda depends on the NAT for access to the
internet, there's one NAT in each AZ.

There's only one bastion host because 1) that saves costs, and 2) uptime is not as important for a bastion host as it
would be for the lambda. If the AZ containing the bastion host is down, it's less than a minute to use Terraform to add 
a new bastion host to the other AZ. 

# Local setup 
## Repo
`git clone https://github.com/skeller88/aws-terraform-bootstrap.git`

## Python environment
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

### Optional: Ipython notebooks
Due to ipython requiring different dependencies from the app, a separate environment is configured via an environment.yml
file. 

[Install Anaconda for Python 3.6](https://www.anaconda.com/download/#macos).

[Create the "hello_world" environment from the environment.yml file](https://conda.io/docs/user-guide/tasks/manage-environments.html#creating-an-environment-from-an-environment-yml-file):

`conda env create -f environment.yml`

Start the Anaconda application and select the "hello_world" environment.

### Optional: Pycharm
Set the python binary in the `venv` virtual environment [as the project interpreter](https://www.jetbrains.com/help/pycharm/configuring-python-interpreter.html#local-interpreter). 

Set any environment variables via the "hello_world.py" [run configuration](https://www.jetbrains.com/help/pycharm/run-debug-configuration-python.html).

[Set NoseTests as the test runner](https://www.jetbrains.com/help/pycharm/python-integrated-tools.html) so 
that tests can be run from Pycharm. 

## Environment variables
Environment variables are used to run the app locally, and also to populate Terraform variables used for app deployment. 
See the [Terraform documentation](https://www.terraform.io/docs/configuration/variables.html#environment-variables)
for information on how this process works. 

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

## Testing
Nosetests is the testing framework used. A dummy test suite should show you the gist of how Nosetests works. Run tests 
in the `tests` folder via the command line or via Pycharm.

# AWS setup
## IAMs
### App IAM user
This user is useful to run the app locally. Do not use your default/admin AWS credentials, because that user has root access, and using API keys for that user in the app
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

### Terraform IAM user
[Set up Terraform](https://www.terraform.io/intro/getting-started/install.html)

Create a Terraform IAM user, which provides Terraform 
with access to AWS resources, but not root access, which can be abused. The Terraform user should have the same policies
attached as the app user. Note that the Terraform IAM user could be used instead of the app IAM user, but this author's
opinion is that it's best to have clear separation of responsibilities across IAMs. 

Add the secret and key created for the Terraform IAM user to the `~/.aws/credentials` file:
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

## Boto
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

## EC2 Key pair
A key pair is needed in order to ssh into the bastion host from a local machine. [Create a new key pair](https://us-west-1.console.aws.amazon.com/ec2/v2/home?region=us-west-1#KeyPairs:sort=keyName) named 
"bastion_host"  via the AWS console and the .pem file
containing the private key will automatically be saved. Change the permissions of the .pem file to make sure that your private key file isn't publicly viewable:

`chmod 400 ~/.aws/<pem-file-name>`

Move the .pem file to the `~/.aws` folder. AWS has [a more detailed explanation of key pairs.](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#retrieving-the-public-key)

## AWS Parameter Store
Create a dummy app secret; any string will do. 

Go to the [parameter store console](https://us-west-1.console.aws.amazon.com/systems-manager/parameters/) and add a new 
parameter with the name 'secret'. Save it as a "SecureString". 

## Remote access via bastion host

### Add your local IP address to the allowed IP addresses of the VPC
An AWS help desk recommended way to enable access to the bastion host from your local machine is to go to
[the VPC console](https://us-west-1.console.aws.amazon.com/vpc/home?region=us-west-1#vpcs) and add a CIDR block containing your IP
address to the VPC settings. 

### ssh to bastion host
Before ssh'ing to the RDS instance, try ssh'ing to the bastion host. 
`bastion_ec2_public_address` is output to the terminal by Terraform. Copy it and modify the script below:
`ssh -i ~/.aws/bastion_host.pem ec2-user@<bastion_ec2_public_address>`

### Create ssh tunnel to RDS instance
After `terraform apply` runs in the terminal, the id of the bastion ec2 instance will be printed to sdout. Copy and
paste the id into the script below. 

In one terminal window, create the ssh tunnel:

`ssh -L 8000:<rds-host-address>:5432 -i ~/.aws/bastion_host.pem ec2-user@<bastion_ec2_public_address>`

Then in another window, connect to the RDS instance:
`psql --dbname=hello_world --user=hellorole --host=localhost --port=8000` 

[Read this tutorial for more detailed instructions](https://userify.com/blog/howto-connect-mysql-ec2-ssh-tunnel-rds/)

# Package AWS lambda and deploy infrastructure with Terraform
Run `terraform apply` to build the terraform infrastructure, and `terraform fmt` to standardize the formatting of .tf files. 

`deploy_lambda.sh hello_world` builds a zipfile for the lambda function and runs `terraform apply`

# Destroy infrastructure with Terraform
It's easy to remove all of the infrastructure deployed via Terraform with a single command, ["terraform destroy"](https://www.terraform.io/intro/getting-started/destroy.html).

# Future work 
Contributions to this repo are welcome. 

## Planned
A "hello world" Docker app, deployed in an ECS cluster.

## Backlog
CI and CD process.

Logging, monitoring, alerting via AWS or some third party tool.

At a certain size, lambda deployment packages have to be uploaded to a S3 bucket before deployment. Add support for that.

Configure the lambda to run in response to a HTTP GET or POST, and echo back request parameters.
 
Increase the availability of the architecture by adding duplicate services to additional availability zones. For example, there's only one NAT in one AZ.
 
Ansible script to automate local setup, such as creation of postgres user and database.

Create a lambda and EC2 that does not require internet access, to demonstrate the use of [VPC endpoints](https://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/vpc-endpoints.html). Currently SSM and S3

[Terraform modules](https://www.terraform.io/docs/modules/usage.html). 

Use [Terraform Vault](https://www.terraform.io/docs/providers/vault/index.html) to store secrets and passwords instead of a local .bash_profile file.
 
Microservices.

"hello world" versions of other AWS services such as Kinesis, SQS, and Dynamo.
 
Implementations using a serverless framework, other languages such as Java and Go, and other cloud providers such as Google Cloud Platform.
  