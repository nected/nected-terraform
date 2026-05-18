output "kube_config" {
  value     = local.is_azure ? module.azure_infra[0].kube_config : ""
  sensitive = true
}