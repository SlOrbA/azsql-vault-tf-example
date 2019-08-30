output "url"   { value = "https://${azurerm_app_service.vault-app.default_site_hostname}" }
output "token" { value = "${random_uuid.root-token.result}" }
