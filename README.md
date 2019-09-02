# azsql-vault-tf-example
Azure SQL managed by Vault with Terraform

### Required software
* Terraform (verified with 0.12.6 ARM)
* Vault (verified with 1.2.1 ARM)

#### Azure CLI
You need to be logged in with the Azure CLI and the subscription you want to deploy to needs to be set as the default.

## Steps
1. `git clone https://github.com/SlOrbA/azsql-vault-tf-example`
1. `cd azsql-vault-tf-example`
1. `terraform init`
1. `terraform plan --target azurerm_app_service.vault-app`
1. review the changes terraform is proposing
1. `terraform apply --target azurerm_app_service.vault-app`
1. `terraform plan`
1. review the changes terraform is proposing
1. `terraform apply`
1. `export VAULT_ADDR=<url>`
1. `export VAULT_TOKEN=<token>`
1. `vault read azsql/creds/dev`
1. Try connection to Azure SQL DB with credentials given
