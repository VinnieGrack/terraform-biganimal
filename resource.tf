terraform {
  required_providers {
    biganimal = {
      source  = "EnterpriseDB/biganimal"
      version = "0.6.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

variable "cluster_name" {
  type        = string
  description = "The name of the cluster."
}

variable "project_id" {
  type        = string
  description = "BigAnimal Project ID"
}

resource "biganimal_cluster" "single_node_cluster" {
  cluster_name = var.cluster_name
  project_id   = var.project_id

/*
  allowed_ip_ranges {
    cidr_block  = "0.0.0.0/24"
    description = "localhost"
  }

  allowed_ip_ranges {
    cidr_block  = "192.168.0.1/32"
    description = "description!"
  }
*/

  backup_retention_period = "30d"
  cluster_architecture {
    id    = "single"
    nodes = 1
  }
  csp_auth = false

  instance_type = "azure:Standard_D2s_v3"
  password      = resource.random_password.password.result
  pg_config {
    name  = "application_name"
    value = "created through terraform"
  }

  pg_config {
    name  = "array_nulls"
    value = "off"
  }

  storage {
    volume_type       = "azurepremiumstorage"
    volume_properties = "P2"
    size              = "8 Gi"
  }
  maintenance_window = {
    is_enabled = true
    start_day  = 0
    start_time = "00:00"
  }

   # pe_allowed_principal_ids = [
  #   <example_value>
  # ]
  
  pg_type               = "epas"
  pg_version            = "15"
  private_networking    = false
  cloud_provider        = "bah:azure"
  read_only_connections = false
  region                = "uksouth"
}

output "password" {
  sensitive = true
  value     = resource.biganimal_cluster.single_node_cluster.password
}

output "faraway_replica_ids" {
  value = biganimal_cluster.single_node_cluster.faraway_replica_ids
}

output "connection_uri" {
  value = biganimal_cluster.single_node_cluster.connection_uri
}
