# The Key Vault item the secretsmanager chart reads.
#
# Key Vault secret names allow [a-zA-Z0-9-] only, so the env var names live
# inside the JSON value rather than in the item name.
#
# As on AWS, terraform does NOT create the encryption-at-rest item, and neither
# does the chart: it only READS the vault. A generated key lives only in the
# Kubernetes Secret `encryption-at-rest-secret` until an operator copies it out
# (kubectl get secret ... -o jsonpath='{.data.encryption-at-rest}') and stores
# the base64 value under the item above. Without that copy, rebuilding the
# cluster generates a new key and previously encrypted data is unreadable.

locals {
  sm_enabled = var.secret_manager.enabled
  sm_prefix  = trimsuffix(var.secret_manager.name_prefix, "-")
  sm_app_id  = "${local.sm_prefix}-app"
  sm_ear_id  = "${local.sm_prefix}-encryption-at-rest"
  sm_lic_id  = "${local.sm_prefix}-license"

  # The vault itself is NOT created here. Azure Key Vault is a resource, not a
  # regional endpoint like Secrets Manager, so there has to be one already:
  # modules/azure creates azurerm_key_vault.ssl_certs_vault (or reads an
  # existing vault when key_vault_name is set) and exposes both here. Set
  # secret_manager.key_vault_id/vault_url only to point application secrets at
  # a different vault than the one holding the TLS certificate.
  sm_key_vault_id = coalesce(var.secret_manager.key_vault_id, module.azure_infra.key_vault_id)
  sm_vault_url    = var.secret_manager.vault_url != "" ? var.secret_manager.vault_url : module.azure_infra.key_vault_uri

  # MASTER_DB_PASSWORD is not stored: the chart's alias derives it from
  # DB_PASSWORD, so one rotation updates one place.
  sm_app_payload = {
    DB_PASSWORD = local.pg_admin_passwd
    # Issued by Azure, not generated here.
    REDIS_PASSWORD   = module.azure_infra.redis_password
    ELASTIC_PASSWORD = local.elasticsearch_admin_password
    ELASTIC_API_KEY  = ""

    AES_SECRET           = local.nected_aes_secret
    JWT_SECRET           = local.nected_jwt_secret
    NECTED_USER_PASSWORD = local.console_user_passwd

    EMAIL_PASSWORD = var.nected_email_password == null ? "" : var.nected_email_password
    AWS_SECRET_KEY = var.nected_ses_secret_key == null ? "" : var.nected_ses_secret_key
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_role_assignment" "tf_vault_secrets_officer" {
  count = local.sm_enabled && var.grant_terraform_vault_access ? 1 : 0

  scope                = local.sm_key_vault_id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "time_sleep" "vault_rbac" {
  count = local.sm_enabled && var.grant_terraform_vault_access ? 1 : 0

  depends_on      = [azurerm_role_assignment.tf_vault_secrets_officer]
  create_duration = "60s"
}

resource "azurerm_key_vault_secret" "app" {
  count = local.sm_enabled ? 1 : 0

  name         = local.sm_app_id
  value        = jsonencode(local.sm_app_payload)
  key_vault_id = local.sm_key_vault_id
  content_type = "application/json"

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  depends_on = [time_sleep.vault_rbac]

  lifecycle {
    precondition {
      condition     = can(regex("^[a-zA-Z0-9-]{1,127}$", local.sm_app_id))
      error_message = "Key Vault secret names allow only letters, digits and hyphens: ${local.sm_app_id} is not valid. Use a name_prefix without slashes."
    }
  }
}

resource "azurerm_key_vault_secret" "license" {
  count = local.sm_enabled ? 1 : 0

  name         = local.sm_lic_id
  value        = jsonencode({ VIDHAAN_PRE_SHARED_KEY = var.nected_pre_shared_key })
  key_vault_id = local.sm_key_vault_id
  content_type = "application/json"

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  depends_on = [time_sleep.vault_rbac]

  lifecycle {
    ignore_changes = [value]

    precondition {
      condition     = can(regex("^[a-zA-Z0-9-]{1,127}$", local.sm_lic_id))
      error_message = "Key Vault secret names allow only letters, digits and hyphens: ${local.sm_lic_id} is not valid. Use a name_prefix without slashes."
    }
  }
}
