# 🚀 Nected Terraform Deployment — AWS & Azure

This repository contains Terraform configurations to deploy the full **Nected Platform** stack on **AWS** or **Microsoft Azure**.
A single root module supports both clouds — pick one by setting `cloud_provider` in `terraform.tfvars`.

## What it deploys

**Common (both clouds)**

* Managed Kubernetes cluster
* Managed PostgreSQL
* Managed search (Elasticsearch on Azure / OpenSearch on AWS)
* Managed cache (Azure Redis / Valkey on AWS ElastiCache) — optional, defaults to in-cluster
* Ingress with TLS termination, DNS records, and SSL via Cert-Manager or pre-provisioned cert
* Nected application stack (UI, Backend, Router, Vidhaan, etc.) with Helm

**Azure-specific**

* Resource Group reuse + VNet/subnets (existing or new)
* AKS cluster
* PostgreSQL Flexible Server
* Application Gateway + AGIC ingress, optional WAF
* Optional Cassandra (for Temporal)

**AWS-specific**

* VPC + subnets (existing or new)
* EKS cluster
* RDS PostgreSQL
* Application Load Balancer + AWS LBC ingress
* ElastiCache (Valkey) + OpenSearch domain

---

## 📁 Repository Layout

```
.
├── main.tf, locals.tf, data.tf, provider.tf, outputs.tf
├── variables.tf                # common variables
├── variables-aws.tf            # AWS-only variables
├── variables-azure.tf          # Azure-only variables
├── terraform.tfvars            # your deployment values
├── backend.tf                  # remote state config
└── modules/
    ├── aws/                    # AWS infra (VPC, EKS, RDS, OpenSearch, ElastiCache)
    ├── azure/                  # Azure infra (VNet, AKS, PG Flexible, Elasticsearch, Cassandra)
    ├── apps/
    │   ├── aws/                # ALB + AWS Load Balancer Controller
    │   ├── azure/              # App Gateway + AGIC + Cert-Manager + WAF
    │   └── common/             # Nected Helm chart, datastore, Temporal
```

---

## 📌 Prerequisites

| Requirement | Version |
| ----------- | ------- |
| Terraform   | ≥ 1.9   |
| kubectl     | Latest  |
| Helm        | Latest  |
| Azure CLI   | ≥ 2.60 (Azure deployments) |
| AWS CLI     | ≥ 2.15 (AWS deployments)   |

> Terraform **≥ 1.9** is required because validation blocks reference other variables (cross-variable validation).

### Cloud resources you must create beforehand

**For Azure:**

* Active Subscription + Subscription ID
* Resource Group where infra will be created
* Public DNS Hosted Zone (in the same RG or a different one) — required for Cert-Manager to issue SSL certs
* *(Optional)* Existing vNet and subnets if you want to reuse instead of letting Terraform create them
* *(Optional)* Key Vault with a pre-uploaded certificate, if not using Cert-Manager

**For AWS:**

* AWS account + a named CLI profile (e.g., `aws-dev`)
* ACM certificate in the target region for your `base_domain` — `aws_certificate_arn` is **required**
* *(Optional)* Existing VPC + subnets if you want to reuse instead of letting Terraform create them
* Route 53 hosted zone for the `base_domain` (DNS records are managed outside Terraform today)

---

## 🔐 Authentication

**Azure**

```bash
az login
az account set --subscription "<YOUR_SUBSCRIPTION_ID>"
```

**AWS**

Either configure a named profile in `~/.aws/credentials` and set `aws_profile` in `terraform.tfvars`, or export `AWS_PROFILE` / `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` in your shell:

```bash
aws configure --profile aws-dev
```

---

## ⚙️ Configuration

Create `terraform.tfvars` and fill in your deployment values. The file is split into three logical blocks: **common**, **Azure**, **AWS**. Only the block matching `cloud_provider` is consumed; the other can stay at defaults.

### Example `terraform.tfvars`

```hcl
########## Project Configuration ##########
project        = "nected"
environment    = "dev"
app            = true     # deploy apps; false = infra only
cloud_provider = "azure"  # "aws" or "azure"

######### Common variables ##################
# K8s
k8s_version        = "1.33"
k8s_node_count     = 2
k8s_min_node_count = 2
k8s_max_node_count = 5

# PostgreSQL
pg_version      = 17
pg_admin_user   = "psqladmin"
pg_admin_passwd = "<password>"

# Use managed cache (Azure Redis / AWS Valkey). Default deploys redis in-cluster.
use_managed_cache = false

# Application gateway / ALB private vs public
agic_internal = false

# Domains
base_domain           = "<<YOUR_BASE_DOMAIN>>"
ui_domain_prefix      = "ui"
backend_domain_prefix = "backend"
router_domain_prefix  = "router"

# Console (initial admin user for the Nected UI)
console_user_email    = "<admin@example.com>"
console_user_password = "<password>"

# Nected app
nected_pre_shared_key  = "<NECTED_LICENSE_KEY>"
temporal_task_partitions = 10
nected_env_overrides = {
  nalanda = {
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

######### Azure variables ##################
az_subscription_id     = "<SUBSCRIPTION_ID>"
az_resource_group_name = "<RESOURCE_GROUP>"

# Hosted zone in same or different RG. Set false to skip DNS+cert automation.
az_hosted_zone = true
# az_hosted_zone_rg = "<HOSTED_ZONE_RG>"   # if hosted zone lives in another RG

# AKS
aks_vm_size = "Standard_D4s_v6"

# Postgres
az_pg_sku_name  = "GP_Standard_D4ds_v5"
az_pg_disk_size = 65536

# Network — reuse existing or create new
network_address_space    = "10.5.0.0/16"
# az_existing_network_name = "my-existing-vnet"
# az_existing_subnets = {
#   psql    = "ex-psql"
#   redis   = "ex-redis"
#   aks     = "ex-aks"
#   appgw   = "ex-appgw"
#   private = "ex-private"
# }

# SSL — default uses Let's Encrypt via Cert-Manager.
# To use a pre-uploaded Key Vault certificate instead:
# az_key_vault_name             = "<KEY_VAULT_NAME>"
# az_key_vault_certificate_name = "<CERT_NAME>"

# Elasticsearch
elasticsearch_vm_size        = "Standard_D2ds_v4"
elasticsearch_admin_password = "<password>"

######### AWS variables ##################
aws_profile = "aws-dev"
aws_region  = "ap-south-1"
azs         = ["ap-south-1a", "ap-south-1b"]

# Network — create new VPC or reuse existing
vpc_cidr = "10.0.0.0/16"
# existing_vpc_id           = "vpc-xxxx"
# existing_public_subnets   = ["subnet-aaa", "subnet-bbb"]
# existing_private_subnets  = ["subnet-ccc", "subnet-ddd"]
# existing_database_subnets = ["subnet-eee", "subnet-fff"]

# EKS
eks_node_instance_types    = ["m6a.xlarge"]

# ACM certificate for the ALB — REQUIRED when cloud_provider = "aws"
aws_certificate_arn = "arn:aws:acm:ap-south-1:<account-id>:certificate/<cert-id>"

# RDS Postgres
db_instance_class        = "db.t3.xlarge"
db_allocated_storage     = 50
db_max_allocated_storage = 200

# Valkey (Redis-compatible ElastiCache)
valkey_node_type  = "cache.t4g.small"
valkey_auth_token = "<auth-token>"

# OpenSearch
opensearch_instance_type  = "t3.medium.search"
opensearch_instance_count = 1
opensearch_admin_password = "<password>"
opensearch_volume_size    = 50
```

For the full variable list with defaults and descriptions, see [variables.tf](./variables.tf), [variables-aws.tf](./variables-aws.tf), and [variables-azure.tf](./variables-azure.tf).

---

## 📦 Remote Terraform State

Pick the backend matching your `cloud_provider`. Edit [backend.tf](./backend.tf) before `terraform init`.

### Azure Blob backend

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "<RESOURCE_GROUP>"
    storage_account_name = "<STORAGE_ACCOUNT_NAME>"
    container_name       = "<CONTAINER_NAME>"
    key                  = "nected.terraform.tfstate"
  }
}
```

Create the storage account + container in Azure before `init`.

### AWS S3 backend

```hcl
terraform {
  backend "s3" {
    bucket         = "<TFSTATE_BUCKET>"
    key            = "nected/terraform.tfstate"
    region         = "ap-south-1"
    profile        = "aws-dev"
    encrypt        = true
    use_lockfile   = true            # native S3 state locking (Terraform ≥ 1.10)
    # dynamodb_table = "<LOCK_TABLE>" # alternative for Terraform < 1.10
  }
}
```

Create the S3 bucket (with versioning enabled) before `init`. If you're on Terraform ≥ 1.10 you can skip the DynamoDB lock table and use `use_lockfile = true` instead.

> Only one `backend` block can be active at a time. Keep the other commented in the file or in a sibling `.tf.example`.

---

## 🏗️ Deployment Steps

```bash
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

> Validation blocks gated on `cloud_provider` will only enforce per-cloud rules — e.g., `azs`, `aws_certificate_arn` are only required when deploying AWS; `az_hosted_zone`/`az_key_vault_name` cross-checks only fire on Azure.

---

## 🔍 Post-Deployment

Retrieve outputs:

```bash
terraform output
```

### Kubeconfig

**Azure**

```bash
az aks get-credentials --resource-group <resource_group> --name <aks_name>
# or
terraform output -raw kube_config > /tmp/kubeconfig
export KUBECONFIG=/tmp/kubeconfig
```

**AWS**

```bash
aws eks update-kubeconfig --region <aws_region> --name <eks_cluster_name> --profile <aws_profile>
```
> eks_cluster_name: `project-environment`

### Encryption-at-rest secret

Back this up — without it, encrypted data is unrecoverable on a fresh cluster:

```bash
kubectl get secret encryption-at-rest-secret -o yaml > encryption-at-rest-secret
```

---

## 🔄 Upgrading Nected Apps

### Via Terraform

Update `terraform.tfvars`:

```hcl
nected_chart_version = "<version-number>"
```

```bash
terraform apply
```

### Via Helm

```bash
helm get values nected > nected-values.yaml
helm upgrade -i nected nected/nected -f nected-values.yaml --version <version-number>
```

---

## ✅ Access the Application

* URL: `https://<ui_domain_prefix>.<base_domain>` (e.g., `https://ui.example.com`)
* Username: value of `console_user_email`
* Password: value of `console_user_password`

---

## 🧹 Destroying Resources

```bash
terraform destroy
```

**Warning:** destroys the cluster, databases, and all data. Irreversible.

---

## ⚡ JMeter Load Testing

Replace placeholders in [jmeter-test/](./jmeter-test/) configs:

* `[RULE_ID]`
* `[RULE_DOMAIN]`
* `[RULE_DOMAIN_IP]` (optional)
* `[NECTED_API_KEY]`
* `[RULE_PAYLOAD]` — e.g., `{"environment": "production", "params": {"a": 1}}`

```bash
kubectl create ns jmeter
kubectl apply -f jmeter-test/jmeter-k8s.yaml
kubectl -n jmeter get pods
kubectl -n jmeter logs -f jmeter-master
```

Pull the report:

```bash
kubectl -n jmeter cp jmeter-master:/test/output .
```

> 💡 Default configuration supports ~25 RPS.

---

## 🤝 Community & Support

* Documentation: [docs.nected.ai](https://docs.nected.ai/)
* LinkedIn: [nected-ai](https://www.linkedin.com/company/nected-ai/)
* Email: support@nected.ai
