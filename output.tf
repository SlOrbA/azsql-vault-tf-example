output "url" {
    value = "https://${azurerm_linux_web_app.vault-app.default_hostname}"
}

output "token" {
  value = random_uuid.root-token.result
}
