#######################
# nected-secret-sync
#
# Workload Identity for the secret-manager hook that both the nected and
# temporal charts run as a pre-install/pre-upgrade job. It reads the
# application credentials out of Key Vault and writes them into a Kubernetes
# Secret.
#
# Reuses the shared user-assigned identity and adds one federated credential,
# matching the cert-manager / keyvault-sync pattern in identity.tf. The chart
# sets the client-id annotation on the service account and the
# azure.workload.identity/use label on the job pod.
#######################

resource "azurerm_federated_identity_credential" "secret_sync" {
  count = var.secret_manager.enabled ? 1 : 0

  name                      = "${var.project}-secret-sync-${var.environment}"
  resource_group_name       = local.resource_group_name
  user_assigned_identity_id = azurerm_user_assigned_identity.identity.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = azurerm_kubernetes_cluster.k8s.oidc_issuer_url
  subject                   = "system:serviceaccount:${var.namespace}:${var.secret_manager.service_account_name}"

  depends_on = [
    azurerm_user_assigned_identity.identity,
    azurerm_kubernetes_cluster.k8s,
  ]
}

# Read-only on the vault holding the application credentials. This is a
# separate vault from the certificate vault in identity.tf when
# secret_manager.key_vault_id is supplied.
# Only when the credentials live in a SEPARATE vault. On the shared vault the
# same identity already holds Key Vault Secrets User via
# azurerm_role_assignment.appgw_kv_secrets, and Azure rejects a second
# assignment of the same role to the same principal at the same scope with
# RoleAssignmentExists.
resource "azurerm_role_assignment" "secret_sync_kv_reader" {
  count = var.secret_manager.enabled && var.secret_manager.key_vault_id != null ? 1 : 0

  scope = var.secret_manager.key_vault_id
  # Read-only is sufficient: the chart only ever reads from Key Vault.
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
}
