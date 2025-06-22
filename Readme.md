# Terraform AWS DefensePro Deployment

This Terraform configuration deploys Radware DefensePro and Cyber Controller in AWS.

## Architecture
- **Customer VPC**: Application subnet + GLB endpoint subnet
- **Scrubbing VPC**: DefensePro instances + Cyber Controller management
- **Gateway Load Balancer**: Traffic inspection and scrubbing
- **2 DefensePro instances**: High availability configuration
- **1 Cyber Controller**: Management and monitoring

## Quick Start

1. **Configure variables:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

2. **Deploy infrastructure (with automatic CC configuration):**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```
   *Note: CC configuration runs automatically during deployment*

## Files
- `main.tf` - Main infrastructure configuration
- `variables.tf` - Input variables
- `outputs.tf` - Output values
- `terraform.tfvars.example` - Example configuration
- `run_cc_automation.sh` - Automated CC configuration
- `connect_cc.sh` - Manual CC connection helper

## Cyber Controller Configuration
The CC requires initial network configuration:
- IP: 10.10.1.20
- Subnet: 255.255.255.0  
- Gateway: 10.10.1.1
- DNS: 8.8.8.8, 8.8.4.4
- Interface: G1

Use `./run_cc_automation.sh` for manual re-configuration if needed, or `./connect_cc.sh` for manual setup.

## Access
- **DefensePro 1**: `ssh radware@<DP1_PUBLIC_IP>` (password: radware123)
- **DefensePro 2**: `ssh radware@<DP2_PUBLIC_IP>` (password: radware123)  
- **Cyber Controller**: `ssh radware@<CC_PUBLIC_IP>` (password: radware)
- **CC Web Interface**: `https://<CC_PUBLIC_IP>` (after configuration)

Get public IPs with: `terraform output`
