# # Application Gateway Outputs

# output "application_gateway_id" {
#   description = "The ID of the Application Gateway"
#   value       = azurerm_application_gateway.appgw.id
# }

# output "application_gateway_name" {
#   description = "The name of the Application Gateway"
#   value       = azurerm_application_gateway.appgw.name
# }

# output "application_gateway_public_ip" {
#   description = "The public IP address of the Application Gateway"
#   value       = azurerm_public_ip.appgw_pip.ip_address
# }

# output "application_gateway_public_ip_fqdn" {
#   description = "The FQDN of the Application Gateway public IP"
#   value       = azurerm_public_ip.appgw_pip.fqdn
# }

# output "application_gateway_identity_id" {
#   description = "The ID of the User Assigned Identity for Application Gateway"
#   value       = azurerm_user_assigned_identity.appgw_identity.id
# }

# output "application_gateway_identity_principal_id" {
#   description = "The Principal ID of the User Assigned Identity for Application Gateway"
#   value       = azurerm_user_assigned_identity.appgw_identity.principal_id
# }

# output "application_gateway_identity_client_id" {
#   description = "The Client ID of the User Assigned Identity for Application Gateway"
#   value       = azurerm_user_assigned_identity.appgw_identity.client_id
# }

# output "application_gateway_backend_pool_id" {
#   description = "The ID of the Application Gateway backend address pool"
#   value       = tolist(azurerm_application_gateway.appgw.backend_address_pool)[0].id
# }

# output "application_gateway_subnet_id" {
#   description = "The ID of the Application Gateway subnet"
#   value       = azurerm_subnet.subnets["appgw"].id
# }











