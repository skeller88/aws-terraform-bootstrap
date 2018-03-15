Table of Contents
=================

   * [Table of Contents](#table-of-contents)
   * [Overview](#overview)
   * [Purpose of this repo](#purpose-of-this-repo)
   * [Architecture](#architecture)
      * [Application](#application)
      * [Networking](#networking)
   * [Why not a serverless framework?](#why-not-a-serverless-framework)
   * [Why Terraform?](#why-terraform)
   * [Local setup](#local-setup)
      * [Repo](#repo)
      * [Python environment](#python-environment)
         * [Install dependencies](#install-dependencies)
         * [Optional: Ipython notebooks](#optional-ipython-notebooks)
         * [Optional: Pycharm](#optional-pycharm)
      * [Environment variables](#environment-variables)
      * [PostgreSQL](#postgresql)
   * [AWS setup](#aws-setup)
      * [AWS Parameter Store](#aws-parameter-store)
      * [IAMs](#iams)
         * [App IAM user](#app-iam-user)
         * [Terraform IAM user](#terraform-iam-user)
   * [Post setup](#post-setup)
      * [Deploy](#deploy)
      * [Run](#run)
      * [Fetch objects from S3](#fetch-objects-from-s3)
      * [Tests](#tests)
      * [Destroy](#destroy)
   * [Connect to AWS instances](#connect-to-aws-instances)
      * [EC2 Key pair](#ec2-key-pair)
      * [Remote access via bastion host](#remote-access-via-bastion-host)
         * [ssh to bastion host](#ssh-to-bastion-host)
         * [Create ssh tunnel to RDS instance](#create-ssh-tunnel-to-rds-instance)
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

# Purpose of this repo
There are many blog posts, github repos, stack overflow posts, and AWS documentation that explain parts of how to build 
and deploy AWS infrastructure with Terraform, but no repo I've found that puts all of the concepts I wanted together and makes it 
quick and easy to set up an app on AWS and locally. I spent too much time reinventing the 
wheel and doing DevOps work. This repo automates as much of that work as possible and provides clear documentation for 
the rest of it.

# Architecture
## Application
The app itself is simple. `hello_world_lambda.py` runs the function `hello_world.py`, which reads a parameter from SSM Parameter Store, 
makes a HTTPS request to a [fake online REST API](https://jsonplaceholder.typicode.com/),
and writes part of REST API response to a either a csv file or Postgres (depending on the environment variable), hosted
either locally or on AWS (depending on the environment variable). The csv file is either in a local directory:

`<aws-terraform-bootstrap-dir>/data/<timestamp>_message.csv>`

or an AWS bucket:

`hello-world-<hello_world_bucket_name_suffix>/<timestamp>_message.csv`

The Postgres database is either a local Postgres instance:

`psql --dbname=hello_world --user=hellorole --host=localhost`

or a Postgres instance hosted on a RDS host. Details on connecting to the RDS Postgres instance are described later in this README.

## Networking
![Architecture Diagram](architecture_diagram.jpg?raw=true)

The above architecture diagram shows that the app is deployed in a VPC consisting of two private subnets and two public subnets across two
availability zones, one public and one private subnet per availability zone (AZ). The lambda and RDS are deployed in a VPC 
because RDS can only be deployed into a VPC, and so a lambda that accesses the RDS instance has to either be in the same
VPC or use [VPC peering](https://docs.aws.amazon.com/AmazonVPC/latest/PeeringGuide/Welcome.html). Also, deploying an instance into a VPC yields additional benefits such as the ability to change the security group
of an instance while it's running. Read more in [AWS's VPC documentation](https://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Introduction.html) 
about VPCs and AWS's migration from their legacy EC2-Classic architecture to VPCs.    

The RDS instance is shown in one subnet only because it's a single AZ deployment. Multi-AZ deployments are higher cost, and unnecessary for a bootstrap app
like this one. It's easy to add multi-az support though if an app needs that increased uptime. 

The lambda is shown in both private subnets because it can be run in either subnet. If one is available and one is down,
for example, the lambda will be run in the subnet that is up. Since the lambda depends on the NAT for access to the
internet, there's one NAT in each AZ.

There's only one bastion host because 1) that saves costs, and 2) uptime is not as important for a bastion host as it
would be for the lambda. If the AZ containing the bastion host is down, it's less than a minute to use Terraform to add 
a new bastion host to the other AZ. 

# Why not a serverless framework?
[Cloud Formation](https://aws.amazon.com/cloudformation/) is AWS's framework for deploying serverless architectures. 
Like Terraform, it enables developers to write infrastructure as code. In addition, it abstracts away DevOps tasks such 
as lambda packaging, deployment, and monitoring. [Apex](https://github.com/apex/apex) is [TJ Holowaychuk's](https://medium.com/@tjholowaychuk) version of CF.
 
[Serverless](https://serverless.com/) is another framework that offers similar functionality, as well as support for 
other cloud providers.

I plan on learning a serverless framework in the future, but before learning those tools, I wanted to get more lower 
level experience with cloud computing devops. With that lower level experience, I am better equipped to understand
the components of cloud architectures, debug production issues, and understand the tradeoffs of the various severless
frameworks. 

# Why Terraform?
Since a serverless framework is not being used, an infrastructure as code (IaC) framework is needed to provision
AWS instances. "Provision" means choosing the number, type, and properties of instances, and deploying those instances. 
Terraform was chosen for a few reasons. It's an open source infrastructure as code framework, which means that it's
free to use (paid features like Terraform Vault are optional). It's used by companies with large apps that serve
millions of users, including my former company. It can be used with any cloud computing platform. Finally, it's 
declarative, which means the end infrastructure state is specified, and Terraform figures out how to achieve that state.
That means it's easy to add, change, and remove infrastructure. Gruntwork.io [has an excellent blog post](https://blog.gruntwork.io/why-we-use-terraform-and-not-chef-puppet-ansible-saltstack-or-cloudformation-7989dad2865c)
that dives deeper into the benefits of Terraform compared with Cloud Formation, Puppet, and other tools.

# Local setup 
## Repo
`git clone https://github.com/skeller88/aws-terraform-bootstrap.git`

## Python environment
Install Python 3.6, either [directly](https://www.python.org/downloads/release/python-363/) or via [homebrew](https://www.digitalocean.com/community/tutorials/how-to-install-python-3-and-set-up-a-local-programming-environment-on-macos)

Then create the virtual environment. Virtual environments keep the app environment isolated from the OS environment. 

```bash
cd <aws-terraform-bootstrap-dir>
python3 -m venv venv
source venv/bin/activate
```

Depending on your OS and python version, an error may occur [due to a bug in pyvenv](https://askubuntu.com/questions/488529/pyvenv-3-4-error-returned-non-zero-exit-status-1). 
If that happens, install pip after creating the venv:

```bash
cd <aws-terraform-bootstrap-dir>
python3 -m venv venv --without-pip
source venv/bin/activate
curl https://bootstrap.pypa.io/get-pip.py | python
deactivate
source venv/bin/activate
```


### Install dependencies
```bash
# Make sure the virtual environment for the app has been activated
source venv/bin/activate
pip install -r requirements.txt
```

### Optional: Ipython notebooks
iPython is a useful data analysis tool. Due to iPython requiring different dependencies from the app, a separate 
environment is configured via an environment.yml file. 

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

Copy the environment variables in `.app_bash_profile.sample` to an `.app_bash_profile` file in this repo in the root
directory, and modify them with the proper values for the local machine. `.app_bash_profile` is in the `.gitignore`
file, which prevents it from being committed to version control so the secrets will be safe. `.app_bash_profile`
is sourced as part of the `./deploy_with_terraform.sh` script, which means that its variables are injected into the 
environment. 

Look at the `environment.variables` property of the lambda configurations in `terraform/lambda.tf` for an understanding of the 
variables used in production. 

## PostgreSQL
Install Postgres [directly](https://www.postgresql.org/download/) or via [homebrew](https://brew.sh/):
`brew install postgresql`

Using the Terminal, login to Postgres via superuser:

`psql postgres`
 
and create a role, `hellorole`.
 
```postgres-sql
CREATE ROLE hellorole WITH PASSWORD '<password>';
ALTER ROLE hellorole CREATEDB; 
ALTER ROLE hellorole WITH LOGIN;
CREATE DATABASE hello_world OWNER hellorole;
```
Choose a different password from your superuser password. The reason you create a new role is so that your superuser 
credentials are less likely to be compromised. 

Connect to the database with the `hellorole` user to verify that the database has been created successfully. There will not be any 
tables in the database:
```bash
psql -U hellorole -d hello_world
```
The app will populate the "messages" table when it is run.

[Refer to this article on setting up PostgreSQL](https://www.codementor.io/engineerapart/getting-started-with-postgresql-on-mac-osx-are8jcopb)for 
a more detailed explanation of the process.

# AWS setup

## AWS Parameter Store
Create a dummy app secret; any string will do. 

Go to the [parameter store console](https://us-west-1.console.aws.amazon.com/systems-manager/parameters/) and add a new 
parameter with the name 'secret'. Save it as a "SecureString". 

## IAMs
### App IAM user
[Create an IAM user with more limited permissions for the app](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html),
and use the user's credentials to locally run the app against AWS S3 via the "smart_open" package in "s3.py". Do not use your default/admin AWS credentials, because that user has root access, and using API keys for that user in the app
makes it more likely that the keys will be compromised. Instead, the user should have the following policies attached:
- AmazonEC2FullAccess
- AWSLambdaFullAccess
- AmazonRDSFullAccess
- AmazonS3FullAccess
- AmazonSSMFullAccess

and the user should also have the following inline policy, which gives it the ability to manage IAM roles.
```json
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

[Add the IAM user credentials to Boto](http://boto3.readthedocs.io/en/latest/guide/configuration.html) by creating a `~/.aws/credentials` file
with the following format:
```bash
[hello_world]
aws_access_key_id = <app-access-key-id>
aws_secret_access_key = <app-secret-access-key>
region=<desired-aws-region>
```

Create a parent `.aws` folder if necessary.

### Terraform IAM user
[Set up Terraform](https://www.terraform.io/intro/getting-started/install.html)

Create a Terraform IAM user, which provides Terraform with access to AWS resources, but not root access, which can be abused. 
The Terraform user should have the same policies attached as the app user. Note that the Terraform IAM user could be used 
instead of the app IAM user, but it's best to have clear separation of responsibilities across IAMs. 

Add the secret and key created for the Terraform IAM user to the `~/.aws/credentials` file:
```bash
[terraform]
aws_access_key_id = <terraform-access-key-id>
aws_secret_access_key = <terraform-admin-access-secret>
```

Initialize Terraform:
```bash
pushd terraform
terraform init
popd
```

[Read this tutorial for more detailed instructions](https://userify.com/blog/howto-connect-mysql-ec2-ssh-tunnel-rds/)

# Post setup 
Once the directions in [Local setup](#local-setup) and [AWS setup](#aws-setup) are finished, deploy, run, and test the
app. Destroy all the infrastructure at any time.

## Deploy
Deploy the lambda and bootstrap the infrastructure in one line:

```bash
cd <aws-terraform-bootstrap-dir>
./package_lambda.sh hello_world_lambda && ./deploy_with_terraform.sh
```

Or, if the lambda is already built, redeploy/update the infrastructure:

```bash
./deploy_with_terraform.sh
```

AWS has regions, and availability zones (AZs) within each region. [Due to AWS availability issues, a region
may temporarily be unavailable](https://github.com/coreos/coreos-kubernetes/issues/442). If an AZ is unavailable,
change the Terraform variable representing that AZ, located in `terraform/vars.tf` and with a variable name like `region_1_az_1`,
to an available AZ. For example, in "us-west-1" the available AZs are "a", "b", and "c". 

## Run
Run the app locally. Make sure the "USE_AWS" environment variableis set to "False".

Run locally from the command line:
```bash
cd <aws-terraform-bootstrap-dir>
source venv/bin/activate && source .app_bash_profile && python ./hello_world_lambda.py
```

or run locally from Pycharm:
- Open "aws-terraform-bootstrap" repo
- Right click on "hello_world.py" and select "Run 'hello_world'"

Run the app on AWS:
- Navigate to the "hello_world" Lambda dashboard
- Configure a test event with an empty JSON object.
- Click "Test" to run the test event and execute the lambda, and output will appear on the dashboard
- Change the "storage_type" environment variable to either "csv" (write to S3) or "postgres" (write to RDS). 

The app can also be run locally against the AWS SSM Parameter Store and  S3 bucket, by setting "USE_AWS" to "True" and running the app  
from the command line or from Pycharm. Note that it's not possible to run locally against the AWS RDS instance, because
the RDS instance is located in a private subnet, and can only be accessed from outside the private subnet via the 
EC2 bastion host. 

## Fetch objects from S3
After running the lambda at least once with `STORAGE_TYPE=csv`, data will have been written to the S3 bucket. Fetch the
data using a script:

```bash
source .app_bash_profile && python ./read_bucket_objects.py $S3_BUCKET
``` 

## Tests
Run `./run_tests.sh`, which will run the `hello_world.py` method with various combinations of environment variables to validate that setup worked
properly.

## Destroy
To avoid AWS costs, when you're done playing with the repo, remove all of the infrastructure deployed via Terraform:

```bash
pushd terraform
source .app_bash_profile && terraform destroy
popd
```

# Connect to AWS instances
Once the directions in [Local setup](#local-setup) and [AWS setup](#aws-setup) are finished, and [the app is deployed](#deploy),
connect to the AWS bastion host and RDS host.

## EC2 Key pair
A key pair is needed in order to ssh into the bastion host from a local machine. [Create a new key pair](https://us-west-1.console.aws.amazon.com/ec2/v2/home?region=us-west-1#KeyPairs:sort=keyName) named 
"bastion_host"  via the AWS console and the .pem file containing the private key will automatically be saved. Change 
the permissions of the .pem file to make sure that your private key file isn't publicly viewable:

```bash
chmod 400 bastion_host.pem
```

Move the .pem file to the `~/.aws` folder. AWS has [a more detailed explanation of key pairs.](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#retrieving-the-public-key)

## Remote access via bastion host
### ssh to bastion host
Before ssh'ing to the RDS instance, try ssh'ing to the bastion host. `bastion_ec2_public_ip` is output to the 
terminal by Terraform after running `./deploy_with_terraform.sh`. Copy `bastion_ec2_public_ip` and modify the script below:
```bash
ssh -i ~/.aws/bastion_host.pem ec2-user@<bastion_ec2_public_ip>
```

### Create ssh tunnel to RDS instance
In one terminal window, create the ssh tunnel:

```bash
ssh -L 8000:<rds_host_address>:5432 -i ~/.aws/bastion_host.pem ec2-user@<bastion_ec2_public_ip>
```

Then in another window, connect to the RDS instance. The password for the instance is the value of the 
`TF_VAR_prod_db_password` environment variable. 
```bash
psql --dbname=hello_world --user=hellorole --host=localhost --port=8000
```

and after the `hello_world` lambda has been run at least once, read the data that's been written to RDS by the lambda:
```postgres-sql
select * from messages;
``` 

# Future work 
Contributions to this repo are welcome. 

## Planned
A "hello world" Docker app, deployed in an ECS cluster.

A lambda that runs in response to HTTP POST requests, and echoes the POST body back to the client.

## Backlog
CI and CD process.

Logging, monitoring, alerting via AWS or some third party tool.

At a certain size, lambda deployment packages have to be uploaded to a S3 bucket before deployment. Add support for that.

Configure the lambda to run in response to a HTTP GET or POST, and echo back request parameters.
 
Increase the availability of the architecture by adding duplicate services to additional availability zones. For example, there's only one NAT in one AZ.
 
Ansible script to automate local setup, such as creation of Postgres user and database.

Create a lambda and EC2 that does not require internet access, to demonstrate the use of [VPC endpoints](https://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/vpc-endpoints.html). Currently SSM and S3

[Terraform modules](https://www.terraform.io/docs/modules/usage.html). 

Use [Terraform Vault](https://www.terraform.io/docs/providers/vault/index.html) to store secrets and passwords instead of a local .bash_profile file.
 
Microservices.

"hello world" versions of other AWS services such as Kinesis, SQS, and Dynamo.
 
Implementations using a serverless framework, other languages such as Java and Go, and other cloud providers such as Google Cloud Platform.
  