# 🚀 Nected Terraform Deployment — AWS & Azure

This repository contains Terraform configurations to deploy the full **Nected Platform** stack on **AWS** or **Microsoft Azure**.
Each cloud has its **own standalone root module** in a dedicated folder — [`aws/`](./aws/) and [`azure/`](./azure/). Pick a cloud by `cd`-ing into its folder and running Terraform there; each folder carries its own `terraform.tfvars`, `backend.tf`, `provider.tf`, and variable definitions. Both roots share the reusable infrastructure under [`modules/`](./modules/).

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
├── aws/                        # ── AWS root module (run terraform here for AWS) ──
│   ├── main.tf, locals.tf, data.tf, provider.tf, outputs.tf
│   ├── variables.tf            # AWS deployment variables
│   ├── terraform.tfvars        # your AWS deployment values
│   └── backend.tf              # AWS S3 remote state config
│
├── azure/                      # ── Azure root module (run terraform here for Azure) ──
│   ├── main.tf, locals.tf, data.tf, provider.tf, outputs.tf
│   ├── variables.tf            # Azure deployment variables
│   ├── terraform.tfvars        # your Azure deployment values
│   └── backend.tf              # Azure Blob remote state config
│
└── modules/                    # ── shared, reusable infra (referenced by both roots) ──
    ├── aws/                    # AWS infra (VPC, EKS, RDS, OpenSearch, ElastiCache, Cassandra)
    ├── azure/                  # Azure infra (VNet, AKS, PG Flexible, Elasticsearch, Cassandra)
    └── apps/
        ├── aws/                # ALB + AWS Load Balancer Controller
        ├── azure/              # App Gateway + AGIC + Cert-Manager + WAF
        └── common/            # Nected Helm chart, datastore, Temporal
```

> There is **no `cloud_provider` variable**. The cloud is determined by which folder you run Terraform in.

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

## 🔐 License Key
To generate your License Key, click below:
[Get Your License Key](https://www.nected.ai/?license_key=true)

---

## ⚙️ Configuration

Each cloud has its own `terraform.tfvars` inside its folder. Edit only the one for the cloud you're deploying:

* AWS → [`aws/terraform.tfvars`](./aws/terraform.tfvars)
* Azure → [`azure/terraform.tfvars`](./azure/terraform.tfvars)

Replace the secret placeholders (`<...>`) with your real values. Cassandra backs Temporal by default — set `cassandra_node_count = 0` to fall back to PostgreSQL.

### AWS — `aws/terraform.tfvars`

```hcl
########## Project Configuration ##########
project     = "nected"
environment = "dev"
app         = true # deploy apps; false = infra only

# Domains and load balancer
agic_internal         = false           # true = internal ALB, false = internet-facing
allowed_lb_cidrs      = ["0.0.0.0/0"]
base_domain           = "dev.example.com"
ui_domain_prefix      = "ui"
backend_domain_prefix = "backend"
router_domain_prefix  = "router"

# Console (initial admin user for the Nected UI)
console_user_email    = "admin@example.com"
console_user_password = "<password>"

# ACM certificate for the ALB — REQUIRED for AWS
# if left blank Terraform will generate the certificate
aws_certificate_arn = "arn:aws:acm:ap-south-1:<account-id>:certificate/<cert-id>"

# Nected app
nected_pre_shared_key = "<NECTED_LICENSE_KEY>"

######### AWS variables ##################
aws_profile = "aws-dev"
aws_region  = "ap-south-1"
azs         = ["ap-south-1a", "ap-south-1b"]

# Network — create new VPC or reuse existing
vpc_cidr                  = "10.0.0.0/16"
# existing_vpc_id           = "vpc-xxxx"
# existing_public_subnets   = []
# existing_private_subnets  = ["subnet-aaa", "subnet-bbb"]
# existing_database_subnets = ["subnet-aaa", "subnet-bbb"]

# EKS
k8s_version                = "1.35"
k8s_node_count             = 2
k8s_min_node_count         = 2
k8s_max_node_count         = 5
eks_node_instance_types    = ["m6a.xlarge"]
eks_endpoint_public_access = true
allowed_k8s_cidrs          = ["0.0.0.0/0"]

# RDS PostgreSQL
pg_version               = 17
pg_admin_user            = "psqladmin"
pg_admin_passwd          = "<password>"
db_instance_class        = "db.m6g.xlarge"
db_allocated_storage     = 256
db_max_allocated_storage = 512
db_multi_az              = false

# Cache — Valkey 
use_managed_cache       = false
valkey_engine_version   = "8.0"
valkey_node_type        = "cache.t4g.small"
valkey_auth_token       = "<auth-token>"
valkey_num_cache_nodes  = 1
valkey_multi_az_enabled = false

# OpenSearch
opensearch_instance_type    = "r6g.large.search"
opensearch_instance_count   = 1
opensearch_admin_username   = "elastic"
opensearch_admin_password   = "<password>"
opensearch_volume_size      = 256
opensearch_multi_az_enabled = false

```

### Azure — `azure/terraform.tfvars`

```hcl
########## Project Configuration ##########
project     = "nected"
environment = "dev"
app         = true # deploy apps; false = infra only

# Domains and application gateway
agic_internal         = true            # true = internal App Gateway, false = public
base_domain           = "dev.example.com"
ui_domain_prefix      = "ui"
backend_domain_prefix = "backend"
router_domain_prefix  = "router"

# Console (initial admin user for the Nected UI)
console_user_email    = "admin@example.com"
console_user_password = "<password>"

# SSL — default uses Let's Encrypt via Cert-Manager.
# To use a pre-uploaded Key Vault certificate instead:
# az_key_vault_name             = "<KEY_VAULT_NAME>"
# az_key_vault_certificate_name = "<CERT_NAME>"

# Nected app
nected_pre_shared_key    = "<NECTED_LICENSE_KEY>"

######### Azure variables ##################
az_subscription_id     = "<SUBSCRIPTION_ID>"
az_resource_group_name = "<RESOURCE_GROUP>"

# Hosted zone in same or different RG. Set false to skip DNS + cert automation.
az_hosted_zone = true
# az_hosted_zone_rg = "<HOSTED_ZONE_RG>"   # if hosted zone lives in another RG

# Network — create new vNet or reuse existing
network_address_space    = "10.0.0.0/16"

# AKS
k8s_version        = "1.33"
k8s_node_count     = 2
k8s_min_node_count = 2
k8s_max_node_count = 5
aks_vm_size        = "Standard_D4ds_v5"

# PostgreSQL Flexible Server
pg_version      = 17
pg_admin_user   = "psqladmin"
pg_admin_passwd = "<password>"
az_pg_sku_name  = "GP_Standard_D4ds_v5"
az_pg_disk_size = 65536

# Cache — managed Azure Redis. Default deploys redis in-cluster.
use_managed_cache = true

# Elasticsearch
elasticsearch_version         = "8.12.0"
elasticsearch_vm_size         = "Standard_D2ds_v4"
elasticsearch_admin_username  = "elastic"
elasticsearch_admin_password  = "<password>"
elasticsearch_os_disk_size_gb = 256

```

For the full variable list with defaults and descriptions, see [`aws/variables.tf`](./aws/variables.tf) and [`azure/variables.tf`](./azure/variables.tf).

---

## 📦 Remote Terraform State

Each root has its own backend file. Edit the one for the cloud you're deploying before `terraform init`: [`aws/backend.tf`](./aws/backend.tf) or [`azure/backend.tf`](./azure/backend.tf).

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

> The S3 / azurerm backend block is commented out by default so the root inits with local state. Uncomment and fill it in to use remote state.

---

## 🏗️ Deployment Steps

Run Terraform from inside the folder for your target cloud.

**AWS**

```bash
cd aws
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

**Azure**

```bash
cd azure
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

> Required values differ per cloud — e.g., `aws_certificate_arn` is required for AWS; `az_subscription_id` / `az_resource_group_name` are required for Azure.

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
