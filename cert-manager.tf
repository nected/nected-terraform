resource "helm_release" "cert_manager_crds" {
  name             = "cert-manager-crds"
  repository       = "https://wiremind.github.io/wiremind-helm-charts"
  chart            = "cert-manager-crds"
  version          = "v1.19.1"
  namespace        = "cert-manager"
  create_namespace = true
}

resource "helm_release" "cert-manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = "cert-manager"
  version    = "1.19.1"

  depends_on = [
    azurerm_kubernetes_cluster.k8s,
    helm_release.agic,
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
                  hostedZoneName: ${data.azurerm_dns_zone.dns_zone.name}
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
        commonName: ${var.hosted_zone}
        dnsNames:
          - ${var.hosted_zone}
          - ${local.router_domain}
          - ${local.ui_domain}
          - ${local.backend_domain}
  EOF
  ]
}