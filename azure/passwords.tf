# Datastore and application credentials (Azure).
#
# A value supplied in tfvars always wins. Anything left null is generated here,
# so no password has to be invented by hand and none ships as a default.
#
# Charset: `!#$^-` is kept identical to the AWS side so a value generated here
# is also valid there, and it avoids the characters that cause quoting trouble
# if a value ever passes through a shell or a .env parser.

locals {
  pw_special = "!#$^-"
}

# Redis is not here: Azure Cache for Redis issues its own primary access key,
# which the infra module exposes as an output.
#
# ---------------------------------------------------------------------------
# Datastore credentials
#
# Regenerating one of these means the engine and the vault must change
# together, so keepers are tied to a single version knob rather than to
# anything that changes incidentally.
# ---------------------------------------------------------------------------

resource "random_password" "pg_admin" {
  count = var.pg_admin_passwd == null ? 1 : 0

  keepers          = { version = var.datastore_password_version }
  length           = 32
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = local.pw_special
}

resource "random_password" "elasticsearch_admin" {
  count = var.elasticsearch_admin_password == null ? 1 : 0

  keepers          = { version = var.datastore_password_version }
  length           = 32
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = local.pw_special
}

# ---------------------------------------------------------------------------
# Application secrets
#
# Nobody should pick these by hand. They are split across two version knobs
# because they are not equally safe to rotate.
# ---------------------------------------------------------------------------

# Rotating JWT_SECRET logs every user out; disruptive, not destructive.
resource "random_password" "jwt_secret" {
  count = var.nected_jwt_secret == null ? 1 : 0

  keepers = { version = var.app_password_version }
  length  = 48
  special = false
}

resource "random_password" "console_user_password" {
  count = var.console_user_password == null ? 1 : 0

  keepers          = { version = var.app_password_version }
  length           = 24
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = local.pw_special
}

# AES_SECRET encrypts stored data. Changing it makes everything encrypted
# under the old value unreadable, so it is deliberately NOT tied to
# app_password_version: nothing short of removing it from state can rotate it.
#
# That also means terraform state is the only copy until the chart has pushed
# it to the vault. Keep state on an encrypted, versioned backend.
resource "random_password" "aes_secret" {
  count = var.nected_aes_secret == null ? 1 : 0

  keepers = { immutable = "do-not-change" }
  length  = 32
  special = false
}

locals {
  # A supplied value wins; otherwise the generated one.
  pg_admin_passwd              = coalesce(var.pg_admin_passwd, one(random_password.pg_admin[*].result))
  elasticsearch_admin_password = coalesce(var.elasticsearch_admin_password, one(random_password.elasticsearch_admin[*].result))

  nected_jwt_secret   = coalesce(var.nected_jwt_secret, one(random_password.jwt_secret[*].result))
  console_user_passwd = coalesce(var.console_user_password, one(random_password.console_user_password[*].result))
  nected_aes_secret   = coalesce(var.nected_aes_secret, one(random_password.aes_secret[*].result))
}
