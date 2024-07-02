provider "azurerm" {
  features {}
}

provider "vault" {
  address = "https://${azurerm_app_service.vault-app.default_site_hostname}"
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

resource "azurerm_mssql_database" "sqldb" {
  name                = "db-example"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  server_name         = azurerm_mssql_server.dbserver.name
}

resource "azurerm_mssql_firewall_rule" "vault" {
  name                = "vault-access"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mssql_server.dbserver.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource "azurerm_service_plan" "vault-plan" {
  name                = "vault-plan-example"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "vault-app" {
  name                = "vault-app-${random_string.app-name.result}-example"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  app_service_plan_id = azurerm_service_plan.vault-plan.id

  site_config {
    linux_fx_version = "DOCKER|vault"
  }

  app_settings = {
    VAULT_DEV_ROOT_TOKEN_ID             = random_uuid.root-token.result
    VAULT_LOCAL_CONFIG                  = "{ \"ui\":  \"true\"}"
    SKIP_SETCAP                         = "yep"
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
  }
}

resource "random_string" "app-name" {
  length  = "3"
  upper   = false
  lower   = true
  special = false
}

