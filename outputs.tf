# ===================================================================
# TERRAFORM OUTPUTS - CLEAN DISPLAY
# ===================================================================

# =============================================================================
# INDIVIDUAL OUTPUTS (Available via specific terraform output commands)
# =============================================================================
# To access individual values when needed by automation scripts, use:
# - terraform output -raw cyber_controller_public_ip
# - terraform output -raw target_server_public_ip
# - terraform output -raw target_server_ssh_key_file
# - terraform output -raw defensepro_1_mgmt_private_ip
# - terraform output -raw defensepro_2_mgmt_private_ip
# - etc.

# Hidden individual outputs for automation scripts
output "cyber_controller_public_ip" {
  value     = aws_eip.cc_eip_mgmt.public_ip
  sensitive = true
}

output "defensepro_1_mgmt_private_ip" {
  value     = local.scrubbing_mgmt_ip_dp_1
  sensitive = true
}

output "defensepro_2_mgmt_private_ip" {
  value     = local.scrubbing_mgmt_ip_dp_2
  sensitive = true
}

output "target_server_public_ip" {
  value     = aws_eip.target_eip_1.public_ip
  sensitive = true
}

output "defensepro_1_public_ip" {
  value     = aws_eip.defensepro_eip_1.public_ip
  sensitive = true
}

output "defensepro_2_public_ip" {
  value     = aws_eip.defensepro_eip_2.public_ip
  sensitive = true
}

output "cyber_controller_private_ip" {
  value     = local.scrubbing_mgmt_ip_cc
  sensitive = true
}

output "target_server_private_ip" {
  value     = local.target_srv_ip
  sensitive = true
}

output "target_server_ssh_key_name" {
  value     = aws_key_pair.target_server_key_pair.key_name
  sensitive = true
}

output "target_server_ssh_key_file" {
  value     = local_file.target_server_private_key.filename
  sensitive = true
}

# =============================================================================
# MAIN DEPLOYMENT SUMMARY (Only visible output)
# =============================================================================

output "deployment_summary" {
  value = <<-EOT

╔══════════════════════════════════════════════════════════════════════════════════════════════════╗
║                          RADWARE DEFENSEPRO DEPLOYMENT SUMMARY                                   ║
╠══════════════════════════════════════════════════════════════════════════════════════════════════╣
                                                                                       
   🛡️  CYBER CONTROLLER                                                               
      Public IP:  ${aws_eip.cc_eip_mgmt.public_ip}                                    
      Private IP: ${local.scrubbing_mgmt_ip_cc}                                       
      Web URL:    https://${aws_eip.cc_eip_mgmt.public_ip}                       
      SSH:        ssh admin@${aws_eip.cc_eip_mgmt.public_ip}                          
                                                                                       
   🔒 DEFENSEPRO-1                                                                    
      Public IP:  ${aws_eip.defensepro_eip_1.public_ip}                               
      Mgmt IP:    ${local.scrubbing_mgmt_ip_dp_1}                                     
      Data IP:    ${local.defensepro_1_data_ip}                                                       
      SSH:        ssh admin@${aws_eip.defensepro_eip_1.public_ip}                     
                                                                                       
   🔒 DEFENSEPRO-2                                                                    
      Public IP:  ${aws_eip.defensepro_eip_2.public_ip}                               
      Mgmt IP:    ${local.scrubbing_mgmt_ip_dp_2}                                     
      Data IP:    ${local.defensepro_2_data_ip}                                                        
      SSH:        ssh admin@${aws_eip.defensepro_eip_2.public_ip}                     
                                                                                       
   🌐 TARGET SERVER (Apache)                                                          
      Public IP:  ${aws_eip.target_eip_1.public_ip}                                   
      Private IP: ${local.target_srv_ip}                                              
      Web URL:    http://${aws_eip.target_eip_1.public_ip} (after Apache installation)
      SSH Key:    ${local_file.target_server_private_key.filename}                    
      SSH:        ssh -i ${local_file.target_server_private_key.filename} ubuntu@${aws_eip.target_eip_1.public_ip}
                                                                                        
   📋 NETWORK INFORMATION                                                              
      Customer VPC:    ${aws_vpc.customer_vpc.id} (${var.customer_vpc_cidr})          
      Scrubbing VPC:   ${aws_vpc.scrubbing_vpc.id} (${var.scrubbing_vpc_cidr})        
      Gateway LB:      ${aws_lb.gateway_lb.dns_name}                                  
                                                                                      
   🎯 TRAFFIC FLOW                                                                     
      Internet → IGW → GLB Endpoint → DefensePro → Target Server                     
      All traffic is inspected by DefensePro for DDoS protection                     
                                                                                      
   🚀 NEXT STEPS                                                                       
      1. Add DefensePro devices:                          
      2. Install Apache on target:                           
      By running: ./add_dp_to_cc_unified.sh                       
                                                                                      
╚══════════════════════════════════════════════════════════════════════════════════════════════════╝

  EOT
  description = "Complete deployment summary with all connection details"
}

# =============================================================================
# HOW TO ACCESS INDIVIDUAL VALUES (if needed for debugging)
# =============================================================================
# To get individual values, use: terraform output -raw <output_name>
# Example: terraform output -raw cyber_controller_public_ip
# Note: Individual outputs are marked as sensitive to keep the main output clean
