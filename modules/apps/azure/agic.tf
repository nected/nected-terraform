resource "helm_release" "agic" {
  name       = "application-gateway-ingress-controller"
  repository = "oci://mcr.microsoft.com/azure-application-gateway/charts"
  chart      = "ingress-azure"
  namespace  = "agic-system"
  version    = "1.8.1"

  create_namespace = true

  depends_on = [ 
    azurerm_application_gateway.appgw 
  ]

  values = [
    yamlencode({
      appgw = {
        subscriptionId = var.subscription_id
        resourceGroup  = var.resource_group_name
        name           = azurerm_application_gateway.appgw.name
        usePrivateIP   = false
      }
      armAuth = {
        type               = "workloadIdentity"
        identityResourceID = var.identity_id
        identityClientID   = var.identity_client_id
      }
      rbac = {
        enabled = true
      }
      kubernetes = {
        watchNamespace = ""
      }
    })
  ]
}