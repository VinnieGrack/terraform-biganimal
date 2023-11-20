# Configure the BigAnimal Provider
provider "biganimal" {
  #//ba_bearer_token = "${var.BA_BEARER_TOKEN}"//
  #ba_bearer_token = var.BA_BEARER_TOKEN

#  variable "BA_BEARER_TOKEN" {
#  type        = string
#  description = "BA_BEARER_TOKEN"
#  default     = ""
#}

  #//ba_api_uri   = "https://portal.biganimal.com/api/v3" // Optional
  ba_api_uri   = "https://portal.biganimal.com/api/v3" 
}
