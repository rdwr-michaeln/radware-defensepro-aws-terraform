# 🛡️ Radware DefensePro AWS Terraform Deployment

This Terraform configuration automates the deployment of **Radware DefensePro** and **Cyber Controller** in AWS with complete DDoS protection infrastructure.

## 🏗️ Architecture Overview

- **Customer VPC**: Application subnet + Gateway Load Balancer endpoint
- **Scrubbing VPC**: DefensePro instances + Cyber Controller management
- **Gateway Load Balancer**: Traffic inspection and scrubbing
- **2 DefensePro instances**: High availability DDoS protection
- **1 Cyber Controller**: Centralized management and monitoring
- **Target Server**: Apache web server with automated installation

## 📋 Prerequisites

### 1. Install Terraform
Choose your operating system:

**Ubuntu/Debian:**
```bash
# Add HashiCorp GPG key
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -

# Add HashiCorp repository
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

# Update and install Terraform
sudo apt-get update && sudo apt-get install terraform

# Verify installation
terraform version
```

**CentOS/RHEL:**
```bash
# Add HashiCorp repository
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo

# Install Terraform
sudo yum -y install terraform

# Verify installation
terraform version
```

**macOS:**
```bash
# Using Homebrew
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Verify installation
terraform version
```

**Windows:**
1. Download Terraform from https://www.terraform.io/downloads.html
2. Extract to a directory (e.g., `C:\terraform`)
3. Add the directory to your PATH
4. Verify with `terraform version`

### 2. Configure AWS CLI
```bash
# Install AWS CLI (if not installed)
pip install awscli

# Configure credentials
aws configure
# Enter your Access Key ID, Secret Access Key, Region, and output format
```

## 🚀 Step-by-Step Deployment Guide

### Step 1: Prepare Configuration

1. **Clone/Download the project** to your local machine

2. **Navigate to the project directory:**
   ```bash
   cd Terraform-AWS-DP-main
   ```

3. **Create your configuration file:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

4. **Edit terraform.tfvars with your values:**
   ```bash
   nano terraform.tfvars
   # OR
   vim terraform.tfvars
   ```

   **Required variables to configure:**
   ```hcl
   # AWS Configuration
   aws_region = "eu-north-1"  # Your preferred AWS region
   deployment_name = "MyDeployment"  # Your deployment name
   
   # Network Configuration
   customer_vpc_cidr = "10.1.0.0/16"
   scrubbing_vpc_cidr = "10.10.0.0/16"
   
   # DefensePro AMI IDs (check latest AMIs in your region)
   defensepro_ami_id = "ami-xxxxxxxxxxxxxxxxx"
   cyber_controller_ami_id = "ami-xxxxxxxxxxxxxxxxx"
   ```

### Step 2: Initialize Terraform

```bash
# Initialize Terraform and upgrade providers
terraform init -upgrade
```

**Expected output:**
```
Initializing the backend...
Initializing provider plugins...
- Downloading plugin for provider "aws"...
- Downloading plugin for provider "tls"...
- Downloading plugin for provider "local"...

Terraform has been successfully initialized!
```

### Step 3: Plan the Deployment

```bash
# Create and review the execution plan
terraform plan -out=defensepro-deployment.tfplan
```

**This will:**
- Show all resources that will be created
- Validate your configuration
- Save the plan to a file for consistent apply

**Review the output carefully** to ensure all resources look correct.

### Step 4: Apply the Configuration

```bash
# Apply the planned configuration
terraform apply defensepro-deployment.tfplan
```

**OR apply directly (will prompt for confirmation):**
```bash
terraform apply
```

**During deployment, you'll see:**
- Resource creation progress
- Any errors or warnings
- **Final deployment summary** with all connection details

**Expected deployment time:** 10-15 minutes

### Step 5: Post-Deployment Summary

After successful deployment, you'll see a **clean deployment summary**:

```
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                          RADWARE DEFENSEPRO DEPLOYMENT SUMMARY                      ║
╠══════════════════════════════════════════════════════════════════════════════════════╣
║                                                                                      ║
║  🛡️  CYBER CONTROLLER                                                               ║
║     Public IP:  X.X.X.X                                                             ║
║     Private IP: 10.10.1.20                                                          ║
║     Web URL:    https://X.X.X.X:2189                                                ║
║     SSH:        ssh admin@X.X.X.X                                                   ║
║                                                                                      ║
║  🔒 DEFENSEPRO-1 & DEFENSEPRO-2                                                     ║
║     [Connection details...]                                                          ║
║                                                                                      ║
║  🌐 TARGET SERVER (Apache)                                                          ║
║     [Connection details...]                                                          ║
║                                                                                      ║
║  🚀 NEXT STEPS                                                                       ║
║     1. Add DefensePro devices: ./add_dp_to_cc_unified.sh                            ║
║     2. License configuration required                                               ║
║                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════╝
```

## 🔑 Step 6: License Configuration (REQUIRED)

**⚠️ IMPORTANT:** Before running the unified script, you **MUST** configure licenses:

### 1. Access Cyber Controller Web Interface
```bash
# Get the Cyber Controller IP from the deployment summary
# Open in browser: https://CC_PUBLIC_IP
```

### 2. Initial Login
- **Username:** `radware`
- **Password:** `radware`
- Accept SSL certificate warnings
- Provide vision-activation license




## 🔧 Step 3: Complete Setup with Unified Script

After licensing is complete, run the unified configuration script:

```bash
# Make script executable (if needed)
chmod +x add_dp_to_cc_unified.sh

# Run the unified script
./add_dp_to_cc_unified.sh
```

**This script will:**
1. ✅ **Add DefensePro devices** to Cyber Controller
2. ✅ **Install Apache** on the target server
3. ✅ **Configure basic DDoS protection policies**
4. ✅ **Verify connectivity** and traffic flow

## 📊 Verification and Testing

### 1. Verify Deployment
```bash
# Check all resource status
terraform show

# Get specific output values
terraform output -raw cyber_controller_public_ip
terraform output -raw target_server_public_ip
```

### 2. Test Web Server
```bash
# Get target server IP
TARGET_IP=$(terraform output -raw target_server_public_ip)

# Test Apache installation
curl http://$TARGET_IP
```

### 3. Verify DDoS Protection
1. **Access Cyber Controller** web interface
2. **Check DefensePro status** in topology view - maybe you need to click on edit for each dp and press save this will solve the problem.
3. **Review traffic statistics** in monitoring section
4. **Test traffic flow** through Gateway Load Balancer

## 🛠️ Troubleshooting

### Common Issues

**1. Terraform Init Fails:**
```bash
# Clear cache and reinitialize
rm -rf .terraform/
terraform init -upgrade
```

**2. AWS Authentication Issues:**
```bash
# Verify AWS credentials
aws sts get-caller-identity

# Reconfigure if needed
aws configure
```

**3. Plan/Apply Errors:**
- Check your `terraform.tfvars` file
- Verify AMI IDs are correct for your region
- Ensure you have sufficient AWS permissions

**4. DefensePro Connection Issues:**
- Verify security groups allow required ports
- Check Cyber Controller can reach DefensePro management IPs
- Ensure licenses are properly applied

### Getting Help

**Check logs:**
```bash
# Terraform debug output
TF_LOG=DEBUG terraform apply

# AWS CLI debug
aws --debug ec2 describe-instances
```

## 🧹 Cleanup

To destroy all resources when no longer needed:

```bash
# Plan destruction
terraform plan -destroy

# Destroy all resources
terraform destroy
```

**⚠️ Warning:** This will permanently delete all created resources and data.

## 📁 Project Files

- `main.tf` - Main infrastructure configuration
- `variables.tf` - Input variables and descriptions
- `outputs.tf` - Clean deployment summary output
- `terraform.tfvars.example` - Example configuration template
- `add_dp_to_cc_unified.sh` - Unified post-deployment script
- `.gitignore` - Git ignore file (excludes sensitive data)

## 🔐 Security Notes

- SSH keys are automatically generated and managed
- Terraform state contains sensitive data - store securely
- Never commit `terraform.tfvars` or `*.pem` files to version control
- Use IAM roles with minimal required permissions
- Regularly update DefensePro and Cyber Controller software

## 🆘 Support

For technical support:
- Review Terraform logs and error messages
- Check AWS CloudFormation events for resource creation issues
- Consult Radware DefensePro documentation
- Verify all prerequisites are met

---

**Happy Deploying! 🚀** Your DDoS protection infrastructure will be ready in minutes!
