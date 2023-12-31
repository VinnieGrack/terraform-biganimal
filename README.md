# BigAnimal Terraform provider

BigAnimal’s Terraform provider is an infrastructure-as-code service that allows you to provision cloud resources with the Terraform CLI and incorporate those resources into your existing BigAnimal cloud infrastructure workflows.

The current version of the Terraform provider offers resources and data sources for creating, reading, updating, and deleting clusters and regions.

The current version of the Terraform provider offers resources and data sources for:

Creating, updating, and deleting clusters.
Creating, updating, and deleting faraway replicas. Promoting faraway replica isn't supported in the current version.
Activating and deactivating regions.
Creating projects. Connecting the cloud service provider isn't supported in the current version.

A Terraform Provider to manage your workloads
on [EDB BigAnimal](https://www.enterprisedb.com/products/biganimal-cloud-postgresql) interacting with the BigAnimal API.
The provider is licensed under the [MPL v2](https://www.mozilla.org/en-US/MPL/2.0/).

## Requirements

- [Terraform](https://www.terraform.io/downloads.html) >= 0.13.x
- [Go](https://golang.org/doc/install) >= 1.19
- [Install the BA CLI v2.0.0 or later](https://www.enterprisedb.com/docs/biganimal/latest/reference/cli/#installing-the-cli) and [jq - Command Line JSON Processor ](https://stedolan.github.io/jq/).

## Let us start building your Terraform code using VSCODE.

## Start with BigAnimal provider

Step 1 : To install the BigAnimal provider, copy and paste this code into your Terraform configuration provider.tf file.

```hcl
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
```
## Let us declare the data-sources and variables

Step 2 : To declare data-sources, copy and paste this code into your Terraform configuration data-sources.tf file.

```hcl
data "biganimal_projects" "this" {
  query = var.query
}

output "projects" {
  value = data.biganimal_projects.this.projects
}

output "number_of_projects" {
  value = length(data.biganimal_projects.this.projects)
}

variable "query" {
  type        = string
  description = "Query string for the projects"
  default     = ""
}
```
## Now, Let us define the BigAnimal cluster type. 
In this example, i'm using [Single node cluster example on Azure(BigAnimal's Cloud Account)](./resources/biganimal_cluster/single_node/bah_azure/resource.tf)
For various other BigAnimal Cluster types, please take a look at our public github repo  https://github.com/EnterpriseDB/terraform-provider-biganimal.git

Step 3 : Simply copy and paste this code into your Terraform configuration resource.tf file.
```hcl
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

```
### Let us initializing BigAnimal credentials Using BA CLI

1. [Authenticate as a valid user and create a credential](https://www.enterprisedb.com/docs/biganimal/latest/reference/cli/#installing-the-cli). This command will direct you to your browser.
   
```shell
biganimal credential create \
  --name "ba-user1"
```
2.  Copy and paste this code in current terraform folder under file .profile, which will help you with exporting $BEARER_TOKEN . Or you can add the following bash functions to your shellrc file (For example: `.bashrc` if you're using bash, `.zshrc` if you're using ZSH) and start a new shell.
   
```hcl
ba_api_get_call () {
	endpoint=$1
	curl -s --request GET --header "content-type: application/json" --header "authorization: Bearer $BA_BEARER_TOKEN" --url "$BA_API_URI$endpoint"
}

ba_get_default_proj_id () {
	echo $(ba_api_get_call "/user-info" | jq -r ".data.organizationId" | cut -d"_" -f2)
}

export_BA_env_vars () {
	cred_name="${1:-ba-user1}" ## Replace "ba-user1" with your credential name, if you're using something different
	if ! biganimal cluster show -c $cred_name > /dev/null
	then
		echo "!!! Running the credential reset command now !!!"
		biganimal credential reset $cred_name
	fi
	biganimal cluster show -c $cred_name >&/dev/null
	export BA_BEARER_TOKEN=$(biganimal credential show -o json| jq -r --arg CREDNAME "$cred_name" '.[]|select(.name==$CREDNAME).accessToken')
	export BA_API_URI="https://"$(biganimal credential show -o json | jq -r --arg CREDNAME "$cred_name" '.[]|select(.name==$CREDNAME).address')/api/v3
	export BA_CRED_NAME="$cred_name"
	echo "$cred_name BA_BEARER_TOKEN and BA_API_URI are exported."
	export TF_VAR_project_id="prj_$(ba_get_default_proj_id)"
	echo "TF_VAR_project_id terraform variable is also exported. Value is $TF_VAR_project_id"
}
```
3. Now, If you have pasted the code from step 2 into .profile file under terraform project, then you can use `source ./.profile` command to to use code above in your current terminal. Otherwise, use your bash `.bashrc` or zsh `.zshrc` profile for source.
   
```console
source ./.profile
```
4. Now, you can use ba_api_get_call & ba_get_default_project_id  and other export commands to manage your BA_BEARER_TOKEN and BA_API_URI environment variables, as well as TF_VAR_project_id terraform environment variable as follows.
   
```console
ba_api_get_call
export_BA_env_vars
export TF_VAR_cluster_name=<type the name of the test cluster>
```
## Let us start with the Terraform initialize your configuration
In order to generate your execution plan, Terraform needs to install the BigAnimal providers and modules referenced by your configuration defined in above steps.

1. In the "Terminal" tab, initialize the project, which downloads a plugin that allows Terraform to interact with BigAnimal by command "terraform init".
```console
terraform init
```
2. Use the terraform plan command to compare your configuration to your resource state, review any changes before you apply them in next step.
   
```console
terraform plan
```
3. Let us executes the terraform plan defined in above using "terraform apply". You can use additional arguments like " --auto-approve" to autoapprove terraform apply command.
   
```console
terraform apply --auto-approve
```
4. Now, Let us find the password for cluster recreated in step 3 generated using Random password provider from terraform as defined in resource.tf.
   
```console
echo "$(terraform output -raw password)"
```
Use PSQL or your favourite tool to interect with BigAnimal cluster to make everything works well. 

5. When you're ready to destroy resources, simply use "terraform destroy" to clean up the resources from BigAnimal.
   
```console
terraform destroy
```
