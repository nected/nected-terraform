resource "helm_release" "cert_manager_crds" {
  count = var.key_vault_name == "null" ? 1 : 0

  name             = "cert-manager-crds"
  repository       = "https://wiremind.github.io/wiremind-helm-charts"
  chart            = "cert-manager-crds"
  version          = "v1.19.1"
  namespace        = "cert-manager"
  create_namespace = true

  depends_on = [
    azurerm_kubernetes_cluster.k8s
  ]
}

resource "helm_release" "cert-manager" {
  count = var.key_vault_name == "null" ? 1 : 0

  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = "cert-manager"
  version    = "1.19.1"

  depends_on = [
    azurerm_kubernetes_cluster.k8s,
    helm_release.cert_manager_crds
  ]

  values = [
    <<EOF
  namespace: cert-manager

  podLabels:
    azure.workload.identity/use: "true"

  serviceAccount:
    labels:
      azure.workload.identity/use: "true"

  extraObjects:
    - |
      apiVersion: cert-manager.io/v1
      kind: ClusterIssuer
      metadata:
        name: letsencrypt-prod
      spec:
        acme:
          email: ${var.console_user_email}
          server: https://acme-v02.api.letsencrypt.org/directory
          privateKeySecretRef:
            name: letsencrypt-prod
          solvers:
            - dns01:
                azureDNS:
                  hostedZoneName: ${data.azurerm_dns_zone.dns_zone[0].name}
                  resourceGroupName: ${local.hosted_zone_rg}
                  subscriptionID: ${data.azurerm_client_config.current.subscription_id}
                  environment: AzurePublicCloud
                  managedIdentity:
                    clientID: ${azurerm_user_assigned_identity.identity.client_id}

    - |
      apiVersion: cert-manager.io/v1
      kind: Certificate
      metadata:
        name: ${local.cert_secret_name}
        namespace: ${var.namespace}
      spec:
        secretName: ${local.cert_secret_name}
        issuerRef:
          name: letsencrypt-prod
          kind: ClusterIssuer
        commonName: ${var.base_domain}
        dnsNames:
          - ${var.base_domain}
          - ${local.router_domain}
          - ${local.ui_domain}
          - ${local.backend_domain}
  EOF
  ]
}


resource "helm_release" "azurecert" {
  count = var.key_vault_name == "null" ? 1 : 0

  name       = "azurecert"
  repository = "https://nected.github.io/helm-charts"
  chart      = "azurecert"
  namespace  = var.namespace
  timeout    = 600
  version    = "0.1.6"

  values = [
    yamlencode({
      KEYVAULT_NAME = "${local.cert_vault_name}"
      CERT_NAME     = "${local.cert_secret_name}"
      CLIENT_ID     = "${azurerm_user_assigned_identity.identity.client_id}"
      SCHEDULE      = "0 0 * * 0"
    })
  ]

  depends_on = [
    helm_release.cert-manager,
    azurerm_key_vault.ssl_certs_vault
  ]
}

resource "time_sleep" "wait_for_keyvaultsync" {
  count = var.key_vault_name == "null" ? 1 : 0

  depends_on = [
    helm_release.azurecert,
  ]

  create_duration = "5m"
}