# inject Terraform configuration variables
source .app_bash_profile
cd terraform/
# pretty printing
terraform fmt
# update terraform-defined infrastructure
terraform apply