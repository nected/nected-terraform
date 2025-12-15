# 🚀 Nected Terraform Deployment — Azure

This repository contains Terraform configurations to deploy the full **Nected Platform** stack on **Microsoft Azure**.
It automates provisioning of:

* Azure Resource Group & Networking
* Azure Kubernetes Service (AKS)
* PostgreSQL Flexible Server
* Elasticsearch Cluster
* DNS, routing & SSL setup
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

### Azure Resources  & Nected license key

To successfully deploy the infrastructure, ensure you have:

* **An active Azure Subscription** and its **Subscription ID**
* **One Azure DNS Hosted Zone**, which will be used for:

  * Creating CNAME records for all Nected services
  * Adding DNS entries required for SSL certificate validation
* **One Azure Resource Group** where the entire infrastructure will be created.

  * The **Hosted Zone** can be in the *same* Resource Group or a *different* one.
* **Nected License Key** required for installing the full Nected service
  * Remove it from `terraform.tfvars` if you want to use the free & limited version

---

## 🔐 Authentication

Login into Azure:

```
az login
```

Ensure your correct subscription is selected:

```
az account set --subscription "<YOUR_SUBSCRIPTION_ID>"
```
---

## ⚙️ Configuration

Create a `terraform.tfvars` file and populate it with your deployment values.

### Example `terraform.tfvars`

```
# Prerequisites
resource_group_name = "<YOUR_RESOURCE_GROUP>"
hosted_zone_rg      = "<HOSTED_ZONE_RESOURCE_GROUP>"
hosted_zone         = "<YOUR_HOSTED_ZONE>"
subscription_id     = "<YOUR_SUBSCRIPTION_ID>"

# Nected License (uncomment to use paid version)
# nected_pre_shared_key = "<NECTED_LICENSE_KEY>"

# Project Information
project             = "nected"
environment         = "dev"

# Network Configuration
vnet_address_space = "10.50.0.0/16"

# AKS Configuration
kubernetes_version = "1.32"
aks_node_count     = 2
aks_min_node_count = 2
aks_max_node_count = 5
aks_vm_size        = "Standard_D4ds_v6"

# PostgreSQL
pg_version      = 17
pg_admin_user   = "psqladmin"
pg_admin_passwd = "<password>"
pg_sku_name     = "GP_Standard_D4ds_v5"
pg_disk_size    = 65536       # size in MB

# Elasticsearch
elasticsearch_version        = "8.12.0"
elasticsearch_vm_size        = "Standard_D4ds_v6"
elasticsearch_admin_username = "elastic"
elasticsearch_admin_password = "<password>"

# Application variables
# App resources & autoscaling
temporal_task_partitions = 20
temporal_service_autoscale = false
nected_service_autoscale = false

# Domain Configuration
scheme                = "https"
ui_domain_prefix      = "ui"
backend_domain_prefix = "backend"
router_domain_prefix  = "router"

# Console Access
console_user_email    = "<<user email>>"
console_user_password = "<<password>>"

# SMTP Configuration
smtp_config = {
  SEND_EMAIL         = "false"
  EMAIL_PROVIDER     = "smtp"
  SENDER_EMAIL       = ""
  SENDER_NAME        = ""
  EMAIL_INSECURE_TLS = ""
  EMAIL_HOST         = ""
  EMAIL_PORT         = ""
  EMAIL_USERNAME     = ""
  EMAIL_PASSWORD     = ""
}
```
---

## 📦 Remote Terraform State (Optional)

If you want to use **remote Terraform state** in **Azure Blob Storage**, create the following:

1. **Azure Storage Account**
2. **Blob Container** inside the storage account
3. Update your `backend.tf` file with the correct values.

Example `backend.tf` configuration:

```
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

```
terraform init
```

### 2️⃣ Validate Configuration

```
terraform validate
```

### 3️⃣ Preview Resources

```
terraform plan -out=tfplan
```

### 4️⃣ Apply Deployment

```
terraform apply tfplan
```
---

## 🔍 Post-Deployment

Once the deployment completes, retrieve important outputs
```
terraform output
```

Typical outputs include:

* AKS cluster credentials
* Application URLs
* DB connection strings

Then configure kubectl access:
```
az aks get-credentials --resource-group <resource_group> --name <aks_name>
```

###  Alternatively Kubeconfig generation
```
terraform output -raw kube_config > /tmp/kubeconfig

export KUBECONFIG=/tmp/kubeconfig 
```
---

## 🧹 Destroying Resources (Optional)

To remove the entire environment:

```
terraform destroy
```
---
## ⚡ Jmeter Load testing
Update the following placeholders in the configuration:
- [RULE_ID]
- [RULE_DOMAIN]
- [RULE_DOMAIN_IP] (optional)
- [NECTED_API_KEY]
- [RULE_PAYLOAD] {"environment": "production", "params": {"a": 1}}
#### Run JMeter
```
cd jmeter-test
kubectl create ns jmeter
kubectl -n jmeter apply -f jmeter-test.yaml
kubectl -n jmeter get pods
kubectl -n jmeter logs -f jmeter-master
```
#### Retrieve JMeter Report
To copy the generated JMeter report after the test completes:
```
kubectl -n jmeter cp jmeter-master:/test/output .
```
> 💡 Default configuration supports approximately 25 RPS.
---
### ✅ Access the Application
- Domain: `ui_domain_prefix.hosted_zone`
- Username: `console_user_email`
- Password: `console_user_password`
---

## 🤝 Community & Support
For questions, feedback, or contributions:
- Visit our [documentation](https://docs.nected.ai/)
- Join the conversation on [LinkedIn](https://www.linkedin.com/company/nected-ai/)
- Contact the team via support@nected.ai
