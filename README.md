# azsql-vault-tf-example
Azure SQL managed by Vault with Terraform

### Required software
* Terraform (verfied with 0.12.2 ARM)

#### Azure CLI
You need to be logged in with the Azure CLI and the subscription you want to deploy to needs to be set as the default.

## Steps
1. `git clone https://github.com/SlOrbA/azsql-vault-tf-example`
1. `cd azsql-vault-tf-example`
1. `terraform init`
1. `terraform plan`
1. review the changes terraform is proposing
1. `terraform apply`

