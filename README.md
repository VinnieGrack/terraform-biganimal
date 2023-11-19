# Terraform Provider BigAnimal

A Terraform Provider to manage your workloads
on [EDB BigAnimal](https://www.enterprisedb.com/products/biganimal-cloud-postgresql) interacting with the BigAnimal API.
The provider is licensed under the [MPL v2](https://www.mozilla.org/en-US/MPL/2.0/).

## Requirements

- [Terraform](https://www.terraform.io/downloads.html) >= 0.13.x
- [Go](https://golang.org/doc/install) >= 1.19
- [Install the BA CLI v2.0.0 or later](https://www.enterprisedb.com/docs/biganimal/latest/reference/cli/#installing-the-cli) and [jq - Command Line JSON Processor ](https://stedolan.github.io/jq/).

### Using BA CLI to help initializing Provider credentials

1. [Authenticate as a valid user and create a credential](https://www.enterprisedb.com/docs/biganimal/latest/reference/cli/#installing-the-cli). This command will direct you to your browser.
```shell
biganimal credential create \
  --name "ba-user1"
```
2. Add the following bash functions to your shellrc file (For example: `.bashrc` if you're using bash, `.zshrc` if you're using ZSH) and start a new shell. Or alternate you can copy this code into the terraform project folder under .profile file and use that as source for command line terminal by mapping the source e.g. source ./.profile
```bash
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
3. Now, you can use `export_BA_env_vars` command to manage your BA_BEARER_TOKEN and BA_API_URI environment variables, as well as TF_VAR_project_id terraform environment variable.
```console
$> export_BA_env_vars ba-user1
ba-user1 BA_BEARER_TOKEN and BA_API_URI are exported.
TF_VAR_project_id terraform variable is also exported. Value is prj_0123456789abcdef
```
# Now let us start with Terraform code to deploy your first cluster. I'd recommend VSCODE for IDE for code managment.

## Start with BigAnimal provider

Step 1 : To install the BigAnimal provider, copy and paste this code into your Terraform configuration provider.tf file.

```hcl
terraform {
  required_providers {
    biganimal = {
      source  = "EnterpriseDB/biganimal"
      version = "0.6.1"
    }
  }
}

provider "biganimal" {
  # Configuration options
  ba_bearer_token = <redacted> // See Getting an API Token section for details
  // ba_api_uri   = "https://portal.biganimal.com/api/v3" // Optional
}
```
## Let us declare data-sources and variable
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
## Now, Let us define the BigAnimal cluster type. In this example using [Single node cluster example on Azure(BigAnimal's Cloud Account)](./resources/biganimal_cluster/single_node/bah_azure/resource.tf)
Please take a look at various BigAnimal Cluster example listed public github url https://github.com/EnterpriseDB/terraform-provider-biganimal.git

Step 3 : Simply copy and paste this code into your Terraform configuration resource.tf file.
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
