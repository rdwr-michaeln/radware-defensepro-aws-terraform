#!/bin/bash

# ===================================================================
# UNIFIED SCRIPT TO ADD DEFENSEPRO DEVICES AND INSTALL APACHE
# ===================================================================

USERNAME="radware"
PASSWORD="radware"

echo "=================================================================="
echo "    ADD DEFENSEPRO DEVICES TO CC & INSTALL APACHE ON TARGET"
echo "=================================================================="
echo ""

# Function to get terraform output
get_terraform_output() {
    local output_name=$1
    terraform output -json "$output_name" 2>/dev/null | sed 's/"//g'
}

# Function to validate IP format
validate_ip() {
    local ip=$1
    if [[ ! $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo "❌ Error: Invalid IP address format: $ip" >&2
        return 1
    fi
    return 0
}

# Function to get CC IP from Terraform
get_cc_ip_from_terraform() {
    echo "🔍 Getting CC public IP from Terraform output..." >&2
    
    if ! command -v terraform &> /dev/null; then
        echo "❌ Error: Terraform is not installed or not in PATH" >&2
        exit 1
    fi
    
    if [ ! -f "main.tf" ] || [ ! -f "outputs.tf" ]; then
        echo "❌ Error: Not in a Terraform directory" >&2
        exit 1
    fi
    
    if ! terraform show &>/dev/null; then
        echo "❌ Error: No Terraform state found" >&2
        exit 1
    fi
    
    local cc_ip=$(get_terraform_output "cyber_controller_public_ip")
    if [ -z "$cc_ip" ]; then
        echo "❌ Error: Could not get CC public IP from Terraform output" >&2
        exit 1
    fi
    
    echo "✅ Found CC public IP from Terraform: $cc_ip" >&2
    echo "$cc_ip"
}

# Function to get DefensePro IPs from Terraform
get_defensepro_ips() {
    echo "🔍 Getting DefensePro management IPs from Terraform..." >&2
    
    local dp1_ip=$(get_terraform_output "defensepro_1_mgmt_private_ip")
    local dp2_ip=$(get_terraform_output "defensepro_2_mgmt_private_ip")
    
    if [ -z "$dp1_ip" ] || [ -z "$dp2_ip" ]; then
        echo "❌ Error: Could not get DefensePro management IPs, using fallback" >&2
        echo "dpx1:10.10.1.10,dpx2:10.10.1.11"
    else
        echo "✅ Found DefensePro IPs: DP1=$dp1_ip, DP2=$dp2_ip" >&2
        echo "dpx1:$dp1_ip,dpx2:$dp2_ip"
    fi
}

# Function to login to CC
login_to_cc() {
    local base_url=$1
    echo "🔐 Logging into Cyber Controller..." >&2
    
    local login_url="${base_url}mgmt/system/user/login"
    local login_payload="{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\"}"
    
    local response=$(curl -s -k -X POST \
                          -H "Content-Type: application/json" \
                          -d "$login_payload" \
                          -c /tmp/cookies.txt \
                          "$login_url")
    
    local http_code=$(curl -s -k -X POST \
                           -H "Content-Type: application/json" \
                           -d "$login_payload" \
                           -c /tmp/cookies.txt \
                           -w "%{http_code}" \
                           -o /dev/null \
                           "$login_url")
    
    if [ "$http_code" != "200" ]; then
        echo "❌ Login failed with HTTP code: $http_code" >&2
        echo "Response: $response" >&2
        exit 1
    fi
    
    echo "✅ Successfully logged into Cyber Controller (Status: $http_code)" >&2
}

# Function to get ormID
get_orm_id() {
    local base_url=$1
    echo "🔍 Getting ormID from Cyber Controller..." >&2
    
    local orm_url="${base_url}mgmt/system/config/tree/site/byname/Default"
    local response=$(curl -s -k -X GET -b /tmp/cookies.txt "$orm_url")
    
    local orm_id=$(echo "$response" | grep -o '"ormID":"[^"]*"' | sed 's/"ormID":"\([^"]*\)"/\1/')
    
    if [ -z "$orm_id" ]; then
        echo "❌ Cannot get ormID" >&2
        echo "Response: $response" >&2
        exit 1
    fi
    
    echo "✅ Found ormID: $orm_id" >&2
    echo "$orm_id"
}

# Function to add DefensePro device
add_defensepro_device() {
    local base_url=$1
    local orm_id=$2
    local device_name=$3
    local management_ip=$4
    
    echo "➕ Adding device: $device_name with IP: $management_ip"
    
    local device_url="${base_url}mgmt/system/config/tree/device"
    
    local payload=$(cat << EOF
{
    "name": "$device_name",
    "parentOrmID": "$orm_id",
    "type": "DefensePro",
    "deviceSetup": {
        "deviceAccess": {
            "cliPassword": "radware123",
            "cliPort": 22,
            "cliUsername": "radware",
            "exclusivelyReceiveDeviceEvents": false,
            "httpPassword": "radware123",
            "httpUsername": "radware",
            "httpsPassword": "radware123",
            "httpsUsername": "radware",
            "managementIp": "$management_ip",
            "registerDeviceEvents": true,
            "snmpV1ReadCommunity": "public",
            "snmpV1WriteCommunity": "public",
            "snmpV2ReadCommunity": "public",
            "snmpV2WriteCommunity": "public",
            "snmpV3AuthenticationPassword": "radware",
            "snmpV3AuthenticationProtocol": "MD5",
            "snmpV3PrivacyPassword": "radware",
            "snmpV3PrivacyProtocol": "DES",
            "snmpV3Username": "radware",
            "snmpVersion": "SNMP_V3",
            "useSnmpV3Authentication": true,
            "useSnmpV3Privacy": true,
            "verifyHttpCredentials": false,
            "verifyHttpsCredentials": true,
            "visionMgtPort": "G1"
        }
    }
}
EOF
)
    
    local http_code=$(curl -s -k -X POST \
                           -H "Content-Type: application/json" \
                           -d "$payload" \
                           -b /tmp/cookies.txt \
                           -w "%{http_code}" \
                           -o /dev/null \
                           "$device_url")
    
    if [ "$http_code" != "200" ] && [ "$http_code" != "201" ]; then
        echo "❌ Error adding device $device_name (HTTP: $http_code)"
    else
        echo "✅ Successfully added device $device_name"
    fi
}



# Function to get target server IP from Terraform
get_target_server_ip() {
    echo "🔍 Getting Target Server IP from Terraform..." >&2
    
    local target_ip=$(get_terraform_output "target_server_public_ip")
    
    if [ -z "$target_ip" ]; then
        echo "❌ Error: Could not get target server IP from Terraform output" >&2
        echo "Run: terraform output target_server_public_ip" >&2
        exit 1
    fi
    
    if ! validate_ip "$target_ip"; then
        echo "❌ Error: Invalid target server IP: $target_ip" >&2
        exit 1
    fi
    
    echo "✅ Target Server IP: $target_ip" >&2
    echo "$target_ip"
}

# Function to find SSH key file
get_ssh_key_file() {
    echo "🔑 Looking for SSH key file..." >&2
    
    local key_file=$(ls target-server-key-*.pem 2>/dev/null | head -1)
    
    if [ ! -f "$key_file" ]; then
        echo "❌ Error: SSH key file not found" >&2
        echo "Expected: target-server-key-*.pem" >&2
        echo "Make sure Terraform has created the key file" >&2
        exit 1
    fi
    
    echo "✅ Found SSH key: $key_file" >&2
    
    # Set correct permissions
    chmod 600 "$key_file"
    
    echo "$key_file"
}

# Function to wait for SSH connection
wait_for_ssh() {
    local target_ip=$1
    local key_file=$2
    
    echo "⏳ Waiting for SSH connection to be ready..." >&2
    
    for i in {1..10}; do
        if ssh -i "$key_file" -o StrictHostKeyChecking=no -o ConnectTimeout=5 ubuntu@$target_ip "echo 'SSH ready'" &>/dev/null; then
            echo "✅ SSH connection successful!" >&2
            return 0
        else
            echo "   Attempt $i/10: waiting 10 seconds..." >&2
            sleep 10
        fi
    done
    
    echo "❌ Cannot connect via SSH after 100 seconds" >&2
    echo "Check if:" >&2
    echo "- Target server is running" >&2
    echo "- Security group allows SSH (port 22)" >&2
    echo "- Network connectivity is working" >&2
    return 1
}

# Function to install Apache on target server
install_apache_on_target() {
    local target_ip=$1
    local key_file=$2
    
    echo "🚀 Installing Apache on Target Server: $target_ip"
    echo "   Using SSH key: $key_file"
    echo ""
    
    # Install Apache via SSH
    ssh -i "$key_file" -o StrictHostKeyChecking=no ubuntu@$target_ip << 'EOF'
        set -e
        
        echo "Starting Apache installation..."
        
        # Update system
        sudo apt update -y
        
        # Install Apache
        sudo apt install -y apache2
        
        # Start and enable Apache
        sudo systemctl start apache2
        sudo systemctl enable apache2
        
        # Create custom index page
        sudo tee /var/www/html/index.html > /dev/null << 'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Target Server - DefensePro Protected</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f0f0f0; }
        .container { background-color: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #333; }
        .status { color: #28a745; font-weight: bold; }
        .info { background-color: #e9ecef; padding: 10px; border-radius: 4px; margin: 10px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>&#x1F6E1;&#xFE0F; Target Server - Protected by Radware DefensePro</h1>
        <p class="status">&#x2705; Apache is running and accessible through DefensePro!</p>
        
        <div class="info">
            <strong>&#x1F4CA; Server Information:</strong><br>
            Operating System: Ubuntu 24.04 LTS<br>
            Web Server: Apache HTTP Server<br>
            Protection: Radware DefensePro<br>
            Installation Method: SSH deployment after Terraform<br>
            Deployment Time: $(date)<br>
        </div>
        
        <div class="info">
            <strong>&#x1F6E1;&#xFE0F; DefensePro Protection:</strong><br>
            All traffic to this server is inspected and protected by Radware DefensePro.<br>
            DDoS attacks, malicious traffic, and threats are automatically mitigated.
        </div>
        
        <div class="info">
            <strong>&#x1F527; Technical Details:</strong><br>
            Server deployed via Terraform<br>
            SSH key pair auto-generated<br>
            Apache installed post-deployment<br>
            DefensePro devices configured in Cyber Controller<br>
        </div>
    </div>
</body>
</html>
HTML
        
        # Set proper permissions
        sudo chown -R www-data:www-data /var/www/html/
        
        # Check Apache status
        if sudo systemctl is-active --quiet apache2; then
            echo "✅ Apache is running successfully!"
        else
            echo "❌ Apache failed to start"
            exit 1
        fi
        
        echo "Apache installation completed successfully!"
EOF

    return $?
}

# Main function
main() {
    # Get CC IP
    if [ $# -eq 0 ]; then
        CC_IP=$(get_cc_ip_from_terraform)
    else
        CC_IP=$1
        validate_ip "$CC_IP" || exit 1
        echo "🎯 Using provided CC IP: $CC_IP" >&2
    fi
    
    BASE_URL="https://$CC_IP/"
    echo "🌐 BASE_URL: $BASE_URL"
    
    rm -f /tmp/cookies.txt
    
    # Login to CC
    login_to_cc "$BASE_URL"
    
    # Get ormID
    ORM_ID=$(get_orm_id "$BASE_URL")
    
    # Get DefensePro IPs
    DP_LIST=$(get_defensepro_ips)
    
    echo ""
    echo "🛡️  Adding DefensePro devices..."
    
    # Add devices
    IFS=',' read -ra DEVICES <<< "$DP_LIST"
    for device in "${DEVICES[@]}"; do
        IFS=':' read -ra DEVICE_INFO <<< "$device"
        device_name="${DEVICE_INFO[0]}"
        management_ip="${DEVICE_INFO[1]}"
        
        add_defensepro_device "$BASE_URL" "$ORM_ID" "$device_name" "$management_ip"
        echo ""
    done
    
    rm -f /tmp/cookies.txt
    
    echo ""
    echo "✅ COMPLETE: DefensePro devices added to Cyber Controller!"
    
    # Install Apache on target server
    echo ""
    echo "🌐 Installing Apache on Target Server..."
    
    TARGET_IP=$(get_target_server_ip)
    SSH_KEY_FILE=$(get_ssh_key_file)
    
    echo "🎯 Target Server IP: $TARGET_IP"
    echo "🔑 SSH Key File: $SSH_KEY_FILE"
    
    # Wait for SSH to be ready
    if ! wait_for_ssh "$TARGET_IP" "$SSH_KEY_FILE"; then
        echo "❌ Failed to establish SSH connection to target server"
        echo "DefensePro devices were added successfully, but Apache installation failed"
        exit 1
    fi
    
    # Install Apache
    if install_apache_on_target "$TARGET_IP" "$SSH_KEY_FILE"; then
        echo ""
        echo "🎉 SUCCESS: Apache installation completed!"
        echo ""
        echo "🌐 Test your server:"
        echo "   curl http://$TARGET_IP"
        echo "   Or open: http://$TARGET_IP"
        echo ""
        echo "🔑 SSH access (if needed):"
        echo "   ssh -i $SSH_KEY_FILE ubuntu@$TARGET_IP"
        echo ""
        echo "✅ COMPLETE: DefensePro devices added & Apache installed successfully!"
    else
        echo ""
        echo "❌ Apache installation failed!"
        echo "DefensePro devices were added successfully, but Apache installation failed"
        echo "You can try manual installation:"
        echo "   ssh -i $SSH_KEY_FILE ubuntu@$TARGET_IP"
        exit 1
    fi
    
    # Install Apache on target server
    echo ""
    echo "🚀 Installing Apache on Target Server..."
    
    TARGET_IP=$(get_target_server_ip)
    SSH_KEY_FILE=$(get_ssh_key_file)
    
    # Wait for SSH to be ready
    wait_for_ssh "$TARGET_IP" "$SSH_KEY_FILE" || exit 1
    
    # Install Apache
    install_apache_on_target "$TARGET_IP" "$SSH_KEY_FILE" || exit 1
    
    echo ""
    echo "✅ COMPLETE: Apache installed on Target Server!"
}

# Run main function
main "$@"

echo ""
echo "=================================================================="
echo "✅ UNIFIED SCRIPT EXECUTION COMPLETED!"
echo "   DefensePro devices added to Cyber Controller"
echo "   Apache installed and configured on Target Server" 
echo "=================================================================="
