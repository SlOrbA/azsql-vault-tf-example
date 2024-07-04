provider "azurerm" {
  features {}
}

provider "vault" {
  address = "https://${azurerm_linux_web_app.vault-app.default_hostname}"
  token   = random_uuid.root-token.result
}

resource "random_uuid" "root-token" {}

resource "vault_mount" "db" {
  path = "azsql"
  type = "database"
}

resource "vault_database_secret_backend_connection" "azsql" {
  backend       = vault_mount.db.path
  name          = "example"
  allowed_roles = ["dev", "prod"]

  mssql {
    connection_url = "user id=${azurerm_mssql_server.dbserver.administrator_login};password=${azurerm_mssql_server.dbserver.administrator_login_password};server=${azurerm_mssql_server.dbserver.fully_qualified_domain_name};database=${azurerm_mssql_database.sqldb.name};app name=vault;port=1433"
  }
}

resource "vault_database_secret_backend_role" "role" {
  backend               = vault_mount.db.path
  name                  = "dev"
  db_name               = vault_database_secret_backend_connection.azsql.name
  creation_statements   = ["CREATE USER [{{name}}] WITh PASSWORD = '{{password}}';"]
  revocation_statements = ["DROP USER IF EXISTS [{{name}}]"]
  default_ttl           = "300"
  max_ttl               = "86400"
}

resource "azurerm_resource_group" "rg" {
  name     = "vault-example"
  location = "westeurope"
}

resource "azurerm_mssql_server" "dbserver" {
  name                         = "db-srv-vault-${random_string.app-name.result}-example"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = random_string.admin-username.result
  administrator_login_password = random_password.admin-password.result
}

resource "random_string" "admin-username" {
  length  = "8"
  upper   = false
  lower   = true
  special = false
}

resource "random_password" "admin-password" {
  length  = "16"
  upper   = true
  lower   = true
  special = false
}
# Corrected Terraform configuration for azurerm_mssql_database, azurerm_mssql_firewall_rule, and azurerm_service_plan resources

# Assuming the existence of a resource "azurerm_mssql_server" "dbserver" and "azurerm_resource_group" "rg" not shown in the provided excerpt

resource "azurerm_mssql_database" "sqldb" {
  name                = "example-database"
  server_id           = azurerm_mssql_server.dbserver.id
}

resource "azurerm_mssql_firewall_rule" "vault" {
  server_id        = azurerm_mssql_server.dbserver.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
  name             = "example-firewall-rule"
}

resource "azurerm_service_plan" "vault-plan" {
  name                = "example-service-plan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku_name            = "S1" # Assuming a SKU name, adjust as necessary
  os_type             = "Linux" # Assuming OS type, adjust as necessary
  }

resource "azurerm_linux_web_app" "vault-app" {
  name                = "vault-app-example"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.vault-plan.id

  ftp_publish_basic_authentication_enabled       = false
  https_only                                     = true
  webdeploy_publish_basic_authentication_enabled = false

  site_config { 
    ftps_state = "FtpsOnly"
    ip_restriction_default_action = "Allow"
    scm_ip_restriction_default_action = "Allow"

    application_stack {
      docker_image_name = "hashicorp/vault:latest"
    }
  }

  app_settings = {
    "WEBSITES_PORT"                       = "8200"
    #"VAULT_DEV_LISTEN_ADDRESS"            = "0.0.0.0:80"
    "VAULT_DEV_ROOT_TOKEN_ID"             = random_uuid.root-token.result
    "VAULT_LOCAL_CONFIG"                  = "{ \"ui\":  \"true\"}"
    "SKIP_SETCAP"                         = "yep"
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
  }
}

resource "random_string" "app-name" {
  length  = "3"
  upper   = false
  lower   = true
  special = false
}

