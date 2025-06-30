#!/bin/bash

# ===================================================================
# RADWARE DEFENSEPRO TERRAFORM PROJECT - DEPENDENCY INSTALLER
# ===================================================================
# This script installs all necessary dependencies to run the 
# Radware DefensePro AWS Terraform deployment on Ubuntu
# 
# Compatible with: Ubuntu 18.04+, Debian 9+
# Date: June 30, 2025
# ===================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to get Ubuntu version
get_ubuntu_version() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo $VERSION_ID
    else
        echo "unknown"
    fi
}

# Main installation function
main() {
    echo "=================================================================="
    echo "    RADWARE DEFENSEPRO TERRAFORM - DEPENDENCY INSTALLER"
    echo "=================================================================="
    echo ""
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        print_error "Please do not run this script as root. Use sudo when needed."
        exit 1
    fi
    
    # Check Ubuntu version
    UBUNTU_VERSION=$(get_ubuntu_version)
    print_status "Detected Ubuntu version: $UBUNTU_VERSION"
    
    # Update system packages
    print_status "Updating system packages..."
    sudo apt-get update -qq
    
    # Install basic utilities first
    print_status "Installing basic utilities..."
    sudo apt-get install -y \
        curl \
        wget \
        gnupg \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        lsb-release \
        unzip
    
    # Install Terraform
    install_terraform
    
    # Install AWS CLI
    install_aws_cli
    
    # Install additional utilities
    install_utilities
    
    # Install Git (if not present)
    install_git
    
    # Verify installations
    verify_installations
    
    # Show next steps
    show_next_steps
}

# Install Terraform
install_terraform() {
    print_status "Installing Terraform..."
    
    if command_exists terraform; then
        CURRENT_VERSION=$(terraform version -json | jq -r '.terraform_version' 2>/dev/null || terraform version | head -n1 | cut -d' ' -f2 | tr -d 'v')
        print_warning "Terraform is already installed (version: $CURRENT_VERSION)"
        read -p "Do you want to reinstall/update Terraform? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
    fi
    
    # Add HashiCorp GPG key
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
    
    # Add HashiCorp repository
    sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" -y
    
    # Update package index
    sudo apt-get update -qq
    
    # Install Terraform
    sudo apt-get install -y terraform
    
    print_success "Terraform installed successfully"
}

# Install AWS CLI
install_aws_cli() {
    print_status "Installing AWS CLI..."
    
    if command_exists aws; then
        CURRENT_VERSION=$(aws --version 2>&1 | cut -d' ' -f1 | cut -d'/' -f2)
        print_warning "AWS CLI is already installed (version: $CURRENT_VERSION)"
        read -p "Do you want to reinstall/update AWS CLI? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
        # Remove existing AWS CLI if user wants to update
        sudo apt-get remove -y awscli 2>/dev/null || true
    fi
    
    # Install AWS CLI v2 (recommended)
    print_status "Installing AWS CLI v2..."
    
    # Download AWS CLI v2
    cd /tmp
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    
    # Install AWS CLI v2
    sudo ./aws/install --update 2>/dev/null || sudo ./aws/install
    
    # Clean up
    rm -rf aws awscliv2.zip
    
    print_success "AWS CLI v2 installed successfully"
}

# Install additional utilities
install_utilities() {
    print_status "Installing additional utilities..."
    
    # List of required utilities
    UTILITIES=(
        "jq"           # JSON processor
        "expect"       # Automated interaction tool
        "netcat-openbsd" # Network utility (nc command)
        "ssh"          # SSH client
        "openssl"      # SSL/TLS toolkit
        "bc"           # Calculator for scripts
        "vim"          # Text editor
        "tree"         # Directory tree viewer
    )
    
    # Install utilities
    for util in "${UTILITIES[@]}"; do
        if ! dpkg -l | grep -q "^ii  $util "; then
            print_status "Installing $util..."
            sudo apt-get install -y "$util"
        else
            print_status "$util is already installed"
        fi
    done
    
    print_success "Additional utilities installed successfully"
}

# Install Git
install_git() {
    print_status "Checking Git installation..."
    
    if command_exists git; then
        GIT_VERSION=$(git --version | cut -d' ' -f3)
        print_status "Git is already installed (version: $GIT_VERSION)"
    else
        print_status "Installing Git..."
        sudo apt-get install -y git
        print_success "Git installed successfully"
    fi
}

# Verify all installations
verify_installations() {
    echo ""
    print_status "Verifying installations..."
    echo "=================================================================="
    
    # Check Terraform
    if command_exists terraform; then
        TERRAFORM_VERSION=$(terraform version | head -n1 | cut -d' ' -f2)
        print_success "? Terraform: $TERRAFORM_VERSION"
    else
        print_error "? Terraform installation failed"
    fi
    
    # Check AWS CLI
    if command_exists aws; then
        AWS_VERSION=$(aws --version 2>&1 | cut -d' ' -f1)
        print_success "? AWS CLI: $AWS_VERSION"
    else
        print_error "? AWS CLI installation failed"
    fi
    
    # Check other utilities
    UTILITIES=("jq" "expect" "nc" "ssh" "git" "curl")
    for util in "${UTILITIES[@]}"; do
        if command_exists "$util"; then
            print_success "? $util: installed"
        else
            print_error "? $util: not found"
        fi
    done
    
    echo "=================================================================="
}

# Show next steps
show_next_steps() {
    echo ""
    print_success "?? All dependencies installed successfully!"
    echo ""
    echo "=================================================================="
    echo "                           NEXT STEPS"
    echo "=================================================================="
    echo ""
    echo "1. ?? Configure AWS Credentials:"
    echo "   aws configure"
    echo "   (You'll need: Access Key ID, Secret Access Key, Region, Output format)"
    echo ""
    echo "2. ? Verify AWS Configuration:"
    echo "   aws sts get-caller-identity"
    echo ""
    echo "3. ?? Initialize Terraform:"
    echo "   terraform init"
    echo ""
    echo "4. ?? Plan Terraform Deployment:"
    echo "   terraform plan"
    echo ""
    echo "5. ?? Apply Terraform Deployment:"
    echo "   terraform apply"
    echo ""
    echo "=================================================================="
    echo "                      IMPORTANT NOTES"
    echo "=================================================================="
    echo ""
    echo "• This project requires specific AMI IDs:"
    echo "  - Cyber Controller AMI: ami-0908b747ea20df193"
    echo "  - DefensePro AMI: ami-061f99d84c3c52c61"
    echo ""
    echo "• Default region: eu-north-1"
    echo "• Make sure your AWS account has access to these AMIs"
    echo "• Complete licensing in Cyber Controller before running post-deployment scripts"
    echo ""
    echo "?? For detailed instructions, see: README.md"
    echo "=================================================================="
}

# Run main function
main "$@"
