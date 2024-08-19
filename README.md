# azsql-vault-tf-example
Azure SQL managed by Vault with Terraform

### Required software
* Terraform (verified with 1.9.3 AMD64
  https://terraform.io
* Vault (verified with 1.17.3 AMD64)
  https://vaultproject.io

#### Azure CLI
You need to be logged in with the Azure CLI and the subscription you want to deploy to needs to be set as the default.

## Steps
1. `git clone https://github.com/SlOrbA/azsql-vault-tf-example`
1. `cd azsql-vault-tf-example`
1. `terraform init`
1. `terraform apply --target azurerm_app_service.vault-app` [Not needed anymore]
1. `export VAULT_ADDR=<url>`
1. `export VAULT_TOKEN=<token>`
1. `terraform apply`
1. `vault read azsql/creds/dev`
1. Try connection to Azure SQL DB with credentials given
