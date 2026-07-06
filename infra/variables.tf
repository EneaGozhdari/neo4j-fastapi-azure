variable "subscription_id" {
  description = "Azure subscription ID. Required for plan/apply, not for validate."
  type        = string
  default     = null
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "westeurope"
}

variable "prefix" {
  description = "Short name prefix for generated resource names."
  type        = string
  default     = "neo4japi"
}

variable "resource_group_name" {
  description = "Name of the resource group to create."
  type        = string
  default     = "rg-neo4j-fastapi"
}

variable "acr_name" {
  description = "Globally-unique Azure Container Registry name (alphanumeric, 5-50 chars)."
  type        = string
  default     = "acrneo4jfastapi"
}

variable "api_image_name" {
  description = "Repository name of the API image inside ACR."
  type        = string
  default     = "neo4j-fastapi-api"
}

variable "image_tag" {
  description = "Tag of the API image to deploy (e.g. a build id or git SHA)."
  type        = string
  default     = "latest"
}

variable "neo4j_image" {
  description = "Neo4j container image for the Azure deployment path."
  type        = string
  default     = "neo4j:5.26"
}

variable "neo4j_user" {
  description = "Neo4j username."
  type        = string
  default     = "neo4j"
}

variable "neo4j_password" {
  description = "Neo4j password. Supply via tfvars or TF_VAR_neo4j_password; never commit it."
  type        = string
  sensitive   = true
  # No default — must be supplied explicitly.
}
