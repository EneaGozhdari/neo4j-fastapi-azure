resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
}

# Container registry that holds the API image.
resource "azurerm_container_registry" "this" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "Basic"
  admin_enabled       = true # simplest ACR auth for the exercise; use managed identity in prod.
}

# Log Analytics workspace backing the Container Apps environment.
resource "azurerm_log_analytics_workspace" "this" {
  name                = "${var.prefix}-logs"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "this" {
  name                       = "${var.prefix}-env"
  resource_group_name        = azurerm_resource_group.this.name
  location                   = azurerm_resource_group.this.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
}

# Neo4j on Container Apps — the Azure deployment path (authored, not applied).
# Internal-only TCP ingress so only the API in the same environment reaches Bolt.
resource "azurerm_container_app" "neo4j" {
  name                         = "${var.prefix}-neo4j"
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = azurerm_resource_group.this.name
  revision_mode                = "Single"

  template {
    container {
      name   = "neo4j"
      image  = var.neo4j_image
      cpu    = 1.0
      memory = "2Gi"

      env {
        name        = "NEO4J_AUTH"
        secret_name = "neo4j-auth"
      }
    }
  }

  # "user/password" is assembled from variables, never an inline literal.
  secret {
    name  = "neo4j-auth"
    value = "${var.neo4j_user}/${var.neo4j_password}"
  }

  ingress {
    external_enabled = false
    target_port      = 7687
    exposed_port     = 7687
    transport        = "tcp"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}

# FastAPI on Container Apps — public HTTPS ingress on the app port.
resource "azurerm_container_app" "api" {
  name                         = "${var.prefix}-api"
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = azurerm_resource_group.this.name
  revision_mode                = "Single"

  template {
    container {
      name   = "api"
      image  = "${azurerm_container_registry.this.login_server}/${var.api_image_name}:${var.image_tag}"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "NEO4J_URI"
        value = "bolt://${azurerm_container_app.neo4j.ingress[0].fqdn}:7687"
      }
      env {
        name  = "NEO4J_USER"
        value = var.neo4j_user
      }
      env {
        name        = "NEO4J_PASSWORD"
        secret_name = "neo4j-password"
      }
    }
  }

  secret {
    name  = "neo4j-password"
    value = var.neo4j_password
  }

  secret {
    name  = "acr-password"
    value = azurerm_container_registry.this.admin_password
  }

  registry {
    server               = azurerm_container_registry.this.login_server
    username             = azurerm_container_registry.this.admin_username
    password_secret_name = "acr-password"
  }

  ingress {
    external_enabled = true
    target_port      = 8000
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}
