output "kube_config" {
  value     = module.azure[0].kube_config
  sensitive = true
}