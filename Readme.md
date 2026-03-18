# Radware DefensePro AWS Terraform Deployment

This Terraform project deploys a complete Radware DefensePro DDoS-protection infrastructure on AWS, including a Customer VPC with a target server, a Scrubbing VPC with two DefensePro instances and a Cyber Controller, and a Gateway Load Balancer to route traffic through the scrubbing environment.

---

## Tested Versions

This Terraform configuration has been tested with the following Radware software versions:

| Component | Tested Versions |
|---|---|
| Cyber Controller | 10.7, 10.12 |
| DefensePro | 10.8.0.0_b118, 10.10.4.3_b500 |

---

## Architecture Overview

- **Customer VPC** — Application subnet with a target server (Apache) and a Gateway Load Balancer endpoint
- **Scrubbing VPC** — Two DefensePro instances (data + management interfaces) and one Cyber Controller
- **Gateway Load Balancer** — Routes customer traffic through DefensePro for inspection and scrubbing
- **Default region** — `eu-north-1`; AMI IDs are region-specific

---

## Prerequisites

### 1. Install Terraform

**Ubuntu/Debian:**
```bash
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install -y terraform
terraform version
```

**CentOS/RHEL:**
```bash
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum -y install terraform
terraform version
```

**macOS:**
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
terraform version
```

**Windows:**
1. Download Terraform from https://www.terraform.io/downloads.html
2. Extract to a directory (e.g., `C:\terraform`) and add it to your `PATH`
3. Verify with `terraform version`

Alternatively, run the included dependency installer on Ubuntu:
```bash
chmod +x install_dependencies.sh
./install_dependencies.sh
```

### 2. Configure AWS CLI

```bash
# Install AWS CLI if not present
pip install awscli

# Configure credentials
aws configure
# Enter your Access Key ID, Secret Access Key, Region, and output format

# Verify
aws sts get-caller-identity
```

---

## Step-by-Step Deployment Guide

### Step 1 — Prepare Configuration

1. Navigate to the project directory:
   ```bash
   cd radware-defensepro-aws-terraform
   ```

2. Create your configuration file from the example:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. If you want to change any default values, edit `terraform.tfvars`:
   ```bash
   nano terraform.tfvars
   ```

   **Required variables (no defaults — Terraform will prompt if not set):**
   ```hcl
   aws_region              = "eu-north-1"    # AWS region to deploy into
   aws_username            = "your-name"     # Included in resource name suffixes
   cyber_controller_ami_id = "ami-0908b747ea20df193"  # region-specific
   defensepro_ami_id       = "ami-061f99d84c3c52c61"  # region-specific
   ```

   > **Note:** The provided AMI IDs are for the **eu-north-1** region only. Contact Radware support for AMI IDs in other regions.

   **Optional overrides (defaults shown):**
   ```hcl
   deployment_index               = "1"              # Unique index appended to resource names
   project_name                   = "MyProject"      # Tag applied to all resources
   customer_vpc_cidr              = "10.1.0.0/16"
   scrubbing_vpc_cidr             = "10.10.0.0/16"
   application_subnet_cidr        = "10.1.2.0/24"
   glb_endpoint_subnet_cidr       = "10.1.111.0/24"
   scrubbing_mgmt_subnet_cidr     = "10.10.1.0/24"
   defensepro_data_subnet_cidr    = "10.10.2.0/24"
   availability_zone_suffix_1     = "a"
   availability_zone_suffix_2     = "b"
   cc_instance_type               = "g4dn.4xlarge"
   dp_1_instance_type             = "r5n.large"
   dp_2_instance_type             = "r5n.large"
   target_srv_instance_type       = "t3.micro"
   target_srv_ami_id              = "ami-0989fb15ce71ba39e"  # Ubuntu 22.04 LTS (eu-north-1)
   admin_computer_network_for_ssh = "0.0.0.0/0"             # Restrict to your IP in production
   ```

### Step 2 — Initialize Terraform

```bash
terraform init -upgrade
```

Expected output:
```
Initializing the backend...
Initializing provider plugins...
- Downloading plugin for provider "aws"...
- Downloading plugin for provider "tls"...
- Downloading plugin for provider "local"...

Terraform has been successfully initialized!
```

### Step 3 — Plan the Deployment

```bash
terraform plan -out=defensepro-deployment.tfplan
```

Review the output carefully to verify all resources (VPCs, subnets, instances, load balancers) before applying.

### Step 4 — Apply the Configuration

```bash
terraform apply defensepro-deployment.tfplan
```

**Expected deployment time:** 10–15 minutes

After completion you will see a deployment summary similar to:

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                  RADWARE DEFENSEPRO DEPLOYMENT SUMMARY                      ║
╠══════════════════════════════════════════════════════════════════════════════╣

   CYBER CONTROLLER
      Public IP:  X.X.X.X
      Private IP: 10.10.1.20
      Web URL:    https://X.X.X.X
      SSH:        ssh admin@X.X.X.X

   DEFENSEPRO-1
      Public IP:  X.X.X.X
      Mgmt IP:    10.10.1.10
      Data IP:    10.10.2.10
      SSH:        ssh admin@X.X.X.X

   DEFENSEPRO-2
      Public IP:  X.X.X.X
      Mgmt IP:    10.10.1.11
      Data IP:    10.10.2.11
      SSH:        ssh admin@X.X.X.X

   TARGET SERVER (Apache)
      Public IP:  X.X.X.X
      Private IP: 10.1.2.20
      Web URL:    http://X.X.X.X (after Apache installation)
      SSH Key:    ./target_server_key.pem

╚══════════════════════════════════════════════════════════════════════════════╝
```

### Step 5 — Configure the Cyber Controller Network

Run the automated network-configuration script to set the Cyber Controller's management IP, netmask, and gateway via SSH:

```bash
chmod +x run_cc_automation.sh
./run_cc_automation.sh
```

This script connects to the Cyber Controller over SSH and automatically answers the initial network-configuration prompts.

### Step 6 — License Configuration (REQUIRED)

> **Warning:** Do NOT run the post-deployment script in Step 7 until licensing is complete.

1. Open the Cyber Controller web interface:
   ```
   https://<CC_PUBLIC_IP>
   ```
   - **Username:** `radware`
   - **Password:** `radware`
   - Accept the SSL certificate warning

2. Navigate to **System → License Management**

3. Apply the required licenses:
   - Cyber Controller license (vision-activation)
   - DefensePro license for DefensePro-1
   - DefensePro license for DefensePro-2

### Step 7 — Run the Post-Deployment Script

After licensing is complete:

```bash
chmod +x add_dp_to_cc_unified.sh
./add_dp_to_cc_unified.sh
```

This script will:
1. Add DefensePro-1 and DefensePro-2 to the Cyber Controller
2. Install Apache on the target server
3. Configure basic DDoS protection policies
4. Verify connectivity and traffic flow through the Gateway Load Balancer

---

## Verification

```bash
# Check all resource status
terraform show

# Retrieve individual output values
terraform output -raw cyber_controller_public_ip
terraform output -raw target_server_public_ip
terraform output -raw defensepro_1_mgmt_private_ip
terraform output -raw defensepro_2_mgmt_private_ip

# Test the Apache web server
TARGET_IP=$(terraform output -raw target_server_public_ip)
curl http://$TARGET_IP
```

---

## Troubleshooting

### DefensePro devices not appearing correctly in Cyber Controller

1. Open the Cyber Controller web interface
2. Navigate to **Device Management**
3. Edit each DefensePro device and click **Save** without making changes — this refreshes the configuration
4. Verify devices appear correctly in the topology view

### Common errors

| Issue | Resolution |
|---|---|
| `terraform init` fails | Run `rm -rf .terraform/ && terraform init -upgrade` |
| AWS authentication error | Run `aws sts get-caller-identity`; reconfigure with `aws configure` |
| Plan/Apply errors | Check `terraform.tfvars`; verify AMI IDs match the target region |
| DefensePro unreachable from CC | Check security groups allow management ports; verify licenses are applied |

```bash
# Enable debug logging for Terraform
TF_LOG=DEBUG terraform apply

# Enable debug output for AWS CLI
aws --debug ec2 describe-instances
```

---

## Cleanup

```bash
# Preview what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy
```

> **Warning:** This permanently deletes all created AWS resources and data.

---

## Project Files

| File | Description |
|---|---|
| `main.tf` | Main infrastructure configuration (VPCs, subnets, instances, load balancers) |
| `variables.tf` | All input variable declarations and defaults |
| `outputs.tf` | Deployment summary and individual sensitive outputs |
| `terraform.tfvars.example` | Example configuration template — copy to `terraform.tfvars` to get started |
| `install_dependencies.sh` | Installs Terraform, AWS CLI, and other dependencies on Ubuntu |
| `run_cc_automation.sh` | Automates initial Cyber Controller SSH network configuration |
| `add_dp_to_cc_unified.sh` | Adds DefensePro devices to Cyber Controller and installs Apache on the target server |

---

## Security Notes

- SSH key pairs are automatically generated by Terraform and stored locally
- Terraform state files contain sensitive data — store them securely (e.g., S3 backend with encryption)
- Never commit `terraform.tfvars` or `*.pem` key files to version control
- Restrict `admin_computer_network_for_ssh` to your actual IP range in production (`0.0.0.0/0` is for testing only)
- Use IAM roles or IAM users with the minimum required permissions

---

## Support

- Review Terraform logs (`TF_LOG=DEBUG`) and AWS console events for resource creation issues
- Consult Radware DefensePro and Cyber Controller product documentation for configuration details
- Verify all prerequisites (licensing, AMI IDs, AWS permissions) before opening a support case
