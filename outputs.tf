# ===================================================================
# TERRAFORM OUTPUTS - DEPLOYMENT SUMMARY
# ===================================================================

# =============================================================================
# ESSENTIAL OUTPUTS (Used by automation scripts - NOT displayed by default)
# =============================================================================

# These outputs are used by the automation scripts but not shown in terraform output
# They have sensitive = true to hide them from the main output display

output "cyber_controller_public_ip" {
  value       = aws_eip.cc_eip_mgmt.public_ip
  description = "Public IP address of the Cyber Controller for management access"
  sensitive   = true  # Hide from main output display
}

output "defensepro_1_mgmt_private_ip" {
  value       = local.scrubbing_mgmt_ip_dp_1
  description = "Private IP address of DefensePro-1 management interface"
  sensitive   = true  # Hide from main output display
}

output "defensepro_2_mgmt_private_ip" {
  value       = local.scrubbing_mgmt_ip_dp_2
  description = "Private IP address of DefensePro-2 management interface"
  sensitive   = true  # Hide from main output display
}

output "target_server_public_ip" {
  value       = aws_eip.target_eip_1.public_ip
  description = "Public IP address of the Target Server"
  sensitive   = true  # Hide from main output display
}

output "defensepro_1_public_ip" {
  value       = aws_eip.defensepro_eip_1.public_ip
  description = "Public IP address of DefensePro-1"
  sensitive   = true  # Hide from main output display
}

output "defensepro_2_public_ip" {
  value       = aws_eip.defensepro_eip_2.public_ip
  description = "Public IP address of DefensePro-2"
  sensitive   = true  # Hide from main output display
}

output "cyber_controller_private_ip" {
  value       = local.scrubbing_mgmt_ip_cc
  description = "Private IP address of the Cyber Controller"
  sensitive   = true  # Hide from main output display
}

output "target_server_private_ip" {
  value       = local.target_srv_ip
  description = "Private IP address of the Target Server"
  sensitive   = true  # Hide from main output display
}

output "gateway_load_balancer_dns" {
  value       = aws_lb.gateway_lb.dns_name
  description = "DNS name of the Gateway Load Balancer"
}

output "gateway_load_balancer_arn" {
  value       = aws_lb.gateway_lb.arn
  description = "ARN of the Gateway Load Balancer"
}

output "vpc_endpoint_service_name" {
  value       = aws_vpc_endpoint_service.gwlb_endpoint_service.service_name
  description = "Service name of the Gateway Load Balancer VPC Endpoint Service"
}

output "gateway_load_balancer_endpoint_id" {
  value       = aws_vpc_endpoint.gwlb_endpoint.id
  description = "ID of the Gateway Load Balancer VPC Endpoint"
}

# =============================================================================
# CONNECTION STRINGS AND ACCESS INFORMATION
# =============================================================================

output "cyber_controller_web_url" {
  value       = "https://${aws_eip.cc_eip_mgmt.public_ip}:2189"
  description = "Web management URL for Cyber Controller"
}

output "cyber_controller_ssh_command" {
  value       = "ssh admin@${aws_eip.cc_eip_mgmt.public_ip}"
  description = "SSH command to connect to Cyber Controller"
}

output "defensepro_1_web_url" {
  value       = "https://${aws_eip.defensepro_eip_1.public_ip}:2189"
  description = "Web management URL for DefensePro-1"
}

output "defensepro_1_ssh_command" {
  value       = "ssh admin@${aws_eip.defensepro_eip_1.public_ip}"
  description = "SSH command to connect to DefensePro-1"
}

output "defensepro_2_web_url" {
  value       = "https://${aws_eip.defensepro_eip_2.public_ip}:2189"
  description = "Web management URL for DefensePro-2"
}

output "defensepro_2_ssh_command" {
  value       = "ssh admin@${aws_eip.defensepro_eip_2.public_ip}"
  description = "SSH command to connect to DefensePro-2"
}

output "target_server_web_url" {
  value       = "http://${aws_eip.target_eip_1.public_ip}"
  description = "Web URL to access the Target Server (Apache)"
}

output "target_server_ssh_command" {
  value       = "ssh ubuntu@${aws_eip.target_eip_1.public_ip}"
  description = "SSH command to connect to Target Server"
}

# =============================================================================
# CIDR BLOCKS AND NETWORK RANGES
# =============================================================================

output "customer_vpc_cidr" {
  value       = var.customer_vpc_cidr
  description = "CIDR block of the Customer VPC"
}

output "scrubbing_vpc_cidr" {
  value       = var.scrubbing_vpc_cidr
  description = "CIDR block of the Scrubbing VPC"
}

output "application_subnet_cidr" {
  value       = var.application_subnet_cidr
  description = "CIDR block of the Application Subnet"
}

output "glb_endpoint_subnet_cidr" {
  value       = var.glb_endpoint_subnet_cidr
  description = "CIDR block of the Gateway Load Balancer Endpoint Subnet"
}

output "scrubbing_mgmt_subnet_cidr" {
  value       = var.scrubbing_mgmt_subnet_cidr
  description = "CIDR block of the Scrubbing Management Subnet"
}

output "defensepro_data_subnet_cidr" {
  value       = var.defensepro_data_subnet_cidr
  description = "CIDR block of the DefensePro Data Subnet"
}

# =============================================================================
# SUMMARY OUTPUT (Formatted for easy reading)
# =============================================================================

output "deployment_summary" {
  value = <<-EOT
  
  ╔══════════════════════════════════════════════════════════════════════════════════════╗
  ║                          RADWARE DEFENSEPRO DEPLOYMENT SUMMARY                      ║
  ╠══════════════════════════════════════════════════════════════════════════════════════╣
  ║                                                                                      ║
  ║  🛡️  CYBER CONTROLLER                                                               ║
  ║     Public IP:  ${aws_eip.cc_eip_mgmt.public_ip}                                                         ║
  ║     Private IP: ${local.scrubbing_mgmt_ip_cc}                                                        ║
  ║     Web URL:    https://${aws_eip.cc_eip_mgmt.public_ip}:2189                                        ║
  ║     SSH:        ssh admin@${aws_eip.cc_eip_mgmt.public_ip}                                           ║
  ║                                                                                      ║
  ║  🔒 DEFENSEPRO-1                                                                    ║
  ║     Public IP:  ${aws_eip.defensepro_eip_1.public_ip}                                                         ║
  ║     Mgmt IP:    ${local.scrubbing_mgmt_ip_dp_1}                                                        ║
  ║     Data IP:    ${local.defensepro_1_data_ip}                                                        ║
  ║     Web URL:    https://${aws_eip.defensepro_eip_1.public_ip}:2189                                        ║
  ║     SSH:        ssh admin@${aws_eip.defensepro_eip_1.public_ip}                                           ║
  ║                                                                                      ║
  ║  🔒 DEFENSEPRO-2                                                                    ║
  ║     Public IP:  ${aws_eip.defensepro_eip_2.public_ip}                                                         ║
  ║     Mgmt IP:    ${local.scrubbing_mgmt_ip_dp_2}                                                        ║
  ║     Data IP:    ${local.defensepro_2_data_ip}                                                        ║
  ║     Web URL:    https://${aws_eip.defensepro_eip_2.public_ip}:2189                                        ║
  ║     SSH:        ssh admin@${aws_eip.defensepro_eip_2.public_ip}                                           ║
  ║                                                                                      ║
  ║  🌐 TARGET SERVER (Apache)                                                          ║
  ║     Public IP:  ${aws_eip.target_eip_1.public_ip}                                                         ║
  ║     Private IP: ${local.target_srv_ip}                                                        ║
  ║     Web URL:    http://${aws_eip.target_eip_1.public_ip}                                              ║
  ║     SSH:        ssh ubuntu@${aws_eip.target_eip_1.public_ip}                                          ║
  ║                                                                                      ║
  ║  📋 NETWORK INFORMATION                                                              ║
  ║     Customer VPC:    ${aws_vpc.customer_vpc.id} (${var.customer_vpc_cidr})                               ║
  ║     Scrubbing VPC:   ${aws_vpc.scrubbing_vpc.id} (${var.scrubbing_vpc_cidr})                              ║
  ║     Gateway LB:      ${aws_lb.gateway_lb.dns_name}               ║
  ║                                                                                      ║
  ║  🎯 TRAFFIC FLOW                                                                     ║
  ║     Internet → IGW → GLB Endpoint → DefensePro → Target Server                      ║
  ║     All traffic is inspected by DefensePro for DDoS protection                      ║
  ║                                                                                      ║
  ╚══════════════════════════════════════════════════════════════════════════════════════╝
  
  EOT
  description = "Complete deployment summary with all connection details"
}
