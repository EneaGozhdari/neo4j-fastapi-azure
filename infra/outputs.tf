output "api_url" {
  description = "Public HTTPS URL of the FastAPI container app."
  value       = "https://${azurerm_container_app.api.ingress[0].fqdn}"
}

output "api_fqdn" {
  description = "FQDN of the API container app."
  value       = azurerm_container_app.api.ingress[0].fqdn
}

output "acr_login_server" {
  description = "Login server of the Azure Container Registry."
  value       = azurerm_container_registry.this.login_server
}

output "neo4j_internal_fqdn" {
  description = "Internal FQDN of the Neo4j container app (Bolt on 7687)."
  value       = azurerm_container_app.neo4j.ingress[0].fqdn
}
