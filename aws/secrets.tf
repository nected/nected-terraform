# The vault items the secretsmanager chart reads.
locals {
  sm_enabled = var.secret_manager.enabled
  sm_prefix  = trimsuffix(var.secret_manager.name_prefix, "/")
  sm_app_id  = "${local.sm_prefix}/app"
  sm_ear_id  = "${local.sm_prefix}/encryption-at-rest"
  sm_lic_id  = "${local.sm_prefix}/license"

  # The payload the chart splats into the Kubernetes Secret: one flat JSON
  # object of ENV_VAR -> value, every value a string.
  #
  # MASTER_DB_PASSWORD is NOT stored: the chart's alias derives it from
  # DB_PASSWORD, so one rotation updates one place.
  sm_app_payload = {
    DB_PASSWORD      = local.pg_admin_passwd
    REDIS_PASSWORD   = local.valkey_auth_token
    ELASTIC_PASSWORD = local.opensearch_admin_password
    ELASTIC_API_KEY  = ""

    AES_SECRET           = local.nected_aes_secret
    JWT_SECRET           = local.nected_jwt_secret
    NECTED_USER_PASSWORD = local.console_user_passwd

    # Operator-supplied; empty is valid and means the feature is off.
    EMAIL_PASSWORD = var.nected_email_password == null ? "" : var.nected_email_password
    AWS_SECRET_KEY = var.nected_ses_secret_key == null ? "" : var.nected_ses_secret_key
  }
}

resource "aws_secretsmanager_secret" "app" {
  count = local.sm_enabled ? 1 : 0

  name                    = local.sm_app_id
  description             = "Nected application credentials, read by the secretsmanager chart"
  kms_key_id              = var.secret_manager.kms_key_arn
  recovery_window_in_days = var.secret_manager.recovery_window_in_days

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_secretsmanager_secret_version" "app" {
  count = local.sm_enabled ? 1 : 0

  secret_id     = aws_secretsmanager_secret.app[0].id
  secret_string = jsonencode(local.sm_app_payload)
}

resource "aws_secretsmanager_secret" "license" {
  count = local.sm_enabled ? 1 : 0

  name                    = local.sm_lic_id
  description             = "Nected licence key (VIDHAAN_PRE_SHARED_KEY), replace with the real key"
  kms_key_id              = var.secret_manager.kms_key_arn
  recovery_window_in_days = var.secret_manager.recovery_window_in_days

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_secretsmanager_secret_version" "license" {
  count = local.sm_enabled ? 1 : 0

  secret_id     = aws_secretsmanager_secret.license[0].id
  secret_string = jsonencode({ VIDHAAN_PRE_SHARED_KEY = var.nected_pre_shared_key })

  lifecycle {
    ignore_changes = [secret_string]
  }
}