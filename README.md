# 🚀 Nected Terraform Deployment — Azure

This repository contains Terraform configurations to deploy the full **Nected Platform** stack on **Microsoft Azure**.
It automates provisioning of:

* Azure Resource Group & Networking
* Azure Kubernetes Service (AKS)
* PostgreSQL Flexible Server
* Elasticsearch Cluster
* DNS, routing
* SSL setup using Cert-Manager
* Nected service configuration

---

## 📌 Prerequisites

Before running Terraform, ensure the following are installed and configured:

| Requirement | Version |
| ----------- | ------- |
| Terraform   | ≥ 1.6   |
| Azure CLI   | ≥ 2.60  |
| kubectl     | Latest  |
| Helm        | Latest  |

### Azure Resources & Nected license key

To successfully deploy the infrastructure, ensure you have:

* **An active Azure Subscription** and its **Subscription ID**
* **One Azure DNS Hosted Zone**, which will be used for:

  * Creating CNAME records for all Nected services
  * Adding DNS entries required for SSL certificate validation
  * **Important:** To issue an SSL certificate using Cert-Manager, the domain must have a public DNS zone for verification.
* **One Azure Resource Group** where the entire infrastructure will be created.

  * The **Hosted Zone** can be in the *same* Resource Group or a *different* one.

---

## 🔐 Authentication

Log in to Azure:

```bash
az login
```

Ensure your correct subscription is selected:

```bash
az account set --subscription "<YOUR_SUBSCRIPTION_ID>"
```

---

## ⚙️ Configuration

Create a `terraform.tfvars` file and populate it with your deployment values.

### Example `terraform.tfvars`

```hcl
# Prerequisites
subscription_id     = "<YOUR_SUBSCRIPTION_ID>"
resource_group_name = "<YOUR_RESOURCE_GROUP>"
base_domain         = "<YOUR_BASE_DOMAIN>"

# Set false if base_domain hosted zone is not available
# If az_hosted_zone = false
#  - Manual DNS mapping required post deployement
#  - Required key_vault_name for SSL
az_hosted_zone      = true

# set hosted_zone_rg if base_domain hosted zone is in different resource group
# default: "null" and expect hosted zone in resource_group_name
# hosted_zone_rg    = "<HOSTED_ZONE_RESOURCE_GROUP>"

# SSL certificates, provide vault name & certificate name
# default: "null" and generate using Let's Encrypt
# key_vault_name = "<KEY_VAULT_NAME>"
# key_vault_certificate_name = "<KEY_VAULT_CERTIFICATE_NAME>"

# Nected License (uncomment to use paid version)
# default: free key with limited usage
# nected_pre_shared_key = "<NECTED_LICENSE_KEY>"

# Project Information
project             = "nected"
environment         = "dev"

# Network Configuration
vnet_address_space = "10.50.0.0/16"

# AKS Configuration
kubernetes_version = "1.33"
aks_node_count     = 2
aks_min_node_count = 2
aks_max_node_count = 4
aks_vm_size        = "Standard_D4s_v6"

# Application Gateway private ip
# default public ip
agic_internal = false

# PostgreSQL
pg_version          = 17
pg_admin_user       = "psqladmin"
pg_admin_passwd     = "<password>"
pg_sku_name         = "GP_Standard_D4ds_v5"
pg_disk_size        = 262144       # 256 GB
pg_backup_retention = 7

# Redis (use Azure Redis Cache)
# default redis via datastore helm chart
use_managed_redis = false

# Elasticsearch
elasticsearch_version        = "8.12.0"
elasticsearch_vm_size        = "Standard_D2ds_v4"
elasticsearch_admin_username = "elastic"
elasticsearch_admin_password = "<password>"

# Application variables
# Chart versions
nected_chart_version = "0.4.35"

# Domain Configuration
scheme                = "https"
ui_domain_prefix      = "ui"
backend_domain_prefix = "backend"
router_domain_prefix  = "router"

# Serivices env configs
nected_env_overrides = {
  "nalanda" = {
    # notifications setiings
    SEND_EMAIL         = "false"
    EMAIL_PROVIDER     = "smtp"
    SENDER_EMAIL       = ""
    SENDER_NAME        = ""
    EMAIL_INSECURE_TLS = ""
    EMAIL_HOST         = ""
    EMAIL_PORT         = ""
    EMAIL_USERNAME     = ""
    EMAIL_PASSWORD     = ""

    # to restrict signup/invite user email domain
    SIGNUP_DOMAINS = ""
  }
}

# Console Access
# username is always an email and password should be alphanumeric at least 8 characters
console_signup_domains = ""
console_user_email    = "<<user email>>"
console_user_password = "<<password>>"

```
> ⚠️ Do not commit terraform.tfvars to version control. Add it to .gitignore.

---

## 📦 Remote Terraform State (Optional)

If you want to use **remote Terraform state** in **Azure Blob Storage**, create the following:

1. **Azure Storage Account**
2. **Blob Container** inside the storage account
3. Update your `backend.tf` file with the correct values.

Example `backend.tf` configuration:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "<RESOURCE_GROUP>"
    storage_account_name = "<STORAGE_ACCOUNT_NAME>"
    container_name       = "<CONTAINER_NAME>"
    key                  = "<TFSTATE_FILE_NAME>.tfstate"
  }
}
```

Ensure these resources are created **before** running `terraform init`.

---

## 🏗️ Deployment Steps

### 1️⃣ Initialize Terraform

```bash
terraform init
```

### 2️⃣ Validate Configuration

```bash
terraform validate
```

### 3️⃣ Preview Resources

```bash
terraform plan -out=tfplan
```

### 4️⃣ Apply Deployment

```bash
terraform apply tfplan
```

---

## 🔍 Post-Deployment

Once the deployment completes, retrieve important outputs:
```bash
terraform output
```

Typical outputs include:

* AKS cluster credentials
* Application URLs
* DB connection strings

Then configure kubectl access:
```bash
az aks get-credentials --resource-group <resource_group> --name <aks_name>
```

### Alternative: Kubeconfig via Terraform Output
```bash
terraform output -raw kube_config > /tmp/kubeconfig

export KUBECONFIG=/tmp/kubeconfig 
```

## Retrieving encryption key
Ensure the following secret is retrieved and backed up:

```bash
kubectl get secret encryption-at-rest-secret -o yaml > encryption-at-rest-secret
```

To upgrade Nected apps:
### Upgrade using Tearraform
update terraform.tfvars:
```
nected_chart_version =  <version-number>
```

```bash
terraform apply
```

### Upgrade using Helm

```bash
helm get values nected > nected-values.yaml
helm upgrade -i nected nected/nected -f nected-values.yaml --version <version-number>
```

---

## ✅ Access the Application
- Domain: `https://ui.example.com`
- Username: `console_user_email`
- Password: `console_user_password`

---

## 🧹 Destroying Resources

To remove the entire environment:

```bash
terraform destroy
```

**Important:** This will delete all infrastructure including databases, and data loss is irreversible.

---

## ⚡ JMeter Load testing
Update the following placeholders in the configuration:
- [RULE_ID]
- [RULE_DOMAIN]
- [RULE_DOMAIN_IP] (optional)
- [NECTED_API_KEY]
- [RULE_PAYLOAD] {"environment": "production", "params": {"a": 1}}
#### Run JMeter
```bash
kubectl create ns jmeter
kubectl apply -f jmeter-test/jmeter-k8s.yaml
kubectl -n jmeter get pods
kubectl -n jmeter logs -f jmeter-master
```
#### Retrieve JMeter Report
To copy the generated JMeter report after the test completes:
```bash
kubectl -n jmeter cp jmeter-master:/test/output .
```
> 💡 Default configuration supports approximately 25 RPS.

---

## 🤝 Community & Support
For questions, feedback, or contributions:
- Visit our [documentation](https://docs.nected.ai/)
- Join the conversation on [LinkedIn](https://www.linkedin.com/company/nected-ai/)
- Contact the team via support@nected.ai
