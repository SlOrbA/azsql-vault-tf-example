provider "azurerm" {}

provider "vault" {}

resource "vault_mount" "db" {
  path = "azsql"
  type = "database"
}

resource "vault_database_secret_backend_connection" "azsql" {
  backend       = "${vault_mount.db.path}"
  name          = "example"
  allowed_roles = ["dev","prod"]

  mssql {
    connection_url = "jdbc:sqlserver://${azurerm_sql_server.dbserver.fully_qualified_domain_name};databaseName=${azurerm_sql_database.sqldb.name};user=${azurerm_sql_server.dbserver.administrator_login};password=${azurerm_sql_server.dbserver.administrator_login_password};encrypt=true;hostNameInCertificate=*.int.mscds.com;"
  }
}

resource "vault_database_secret_backend_role" "role"{
  backend             = "${vault_mount.db.path}"
  name                = "my-role"
  db_name             = "${vault_database_secret_backend_connection.azsql.name}"
  creation_statements = ["CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{passwd}}' VALID UNTIL '{{expiration}}';"]
}

resource "azurerm_resource_group" "rg" {
  name     = "example"
  location = "westeurope"
}

resource "azurerm_sql_server" "dbserver" {
  name                         = "example-db-server"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  location                     = "${azurerm_resource_group.rg.location}"
  version                      = "12.0"
  administrator_login          = "${random_string.admin-username.result}"
  administrator_login_password = "${random_string.admin-password.result}"
}

resource "random_string" "admin-username" {
  length           = "8"
  upper            = false
  lower            = true
  special          = false
}

resource "random_string" "admin-password" {
  length           = "8"
  upper            = true
  lower            = true
  special          = true
  override_special = "-_=+<>"
}

resource "azurerm_sql_database" "sqldb" {
  name                = "example-db"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"
  server_name         = "${azurerm_sql_server.dbserver.name}"
}

resource "azurerm_app_service_plan" "vault-plan" {
  name                = "example-plan"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"
  
  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "vault-app" {
  name                = "example-app"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"
  app_service_plan_id = "${azurerm_app_service_plan.vault-plan.id}"

  site_config {
    linux_fx_version = "DOCKER|vault"
  }

  app_settings = {
    VAULT_DEV_ROOT_TOKEN_ID  = "myroot"
  }
}
