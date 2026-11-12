output "secret_sync_role_arn" {
  description = "IAM role assumed by the nected-secret-sync job (null when disabled)"
  value       = var.secret_manager.enabled ? aws_iam_role.secret_sync[0].arn : null
}

output "secret_sync_pod_identity_id" {
  description = "Pod Identity association, for use in depends_on so the hook does not run before the binding exists"
  value       = var.secret_manager.enabled ? aws_eks_pod_identity_association.secret_sync[0].association_id : null
}
