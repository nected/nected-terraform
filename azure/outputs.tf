output "kube_config" {
  value     = module.azure_infra.kube_config
  sensitive = true
}