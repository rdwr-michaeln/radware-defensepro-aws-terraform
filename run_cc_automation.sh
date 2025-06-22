#!/bin/bash
# Automatic CC Configuration Script

echo "=== Cyber Controller Auto-Configuration ==="

# Get CC IP from environment variable (when called from Terraform) or Terraform output
if [ -n "$CC_IP" ]; then
    echo "Using CC IP from environment: $CC_IP"
else
    echo "Getting CC IP from Terraform output..."
    CC_IP=$(terraform output -raw cyber_controller_public_ip 2>/dev/null)
fi

if [ -z "$CC_IP" ]; then
    echo "Error: Could not get CC IP from Terraform or environment"
    echo "Please ensure terraform apply completed successfully or set CC_IP environment variable"
    exit 1
fi

echo "CC IP: $CC_IP"
echo "Auto-configuring with: IP=10.10.1.20, Mask=255.255.255.0, GW=10.10.1.1"
echo ""

# Check if expect is installed
if ! command -v expect &> /dev/null; then
    echo "Installing expect..."
    sudo apt-get update && sudo apt-get install -y expect
fi

# Wait for CC to be accessible via SSH
echo "Waiting for CC SSH to be ready..."
for i in {1..15}; do
    # Simple port check
    if nc -z -w5 $CC_IP 22 2>/dev/null; then
        echo "CC SSH port is ready!"
        break
    fi
    echo "Attempt $i/15: SSH port not ready, waiting 10 seconds..."
    sleep 10
done

echo "Starting automated configuration (prompt-based responses)..."
echo "This will respond to each prompt automatically"
echo "Connecting to CC via SSH..."

# Run expect automation with prompt-based responses
expect -c "
set timeout 300
spawn ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null radware@$CC_IP

puts \"SSH connection initiated to $CC_IP\"

# Login sequence - wait for password prompt and login
expect {
    \"password:\" {
        puts \"Found 'password:' prompt, sending password...\"
        send \"radware\r\"
    }
    \"Password:\" {
        puts \"Found 'Password:' prompt, sending password...\"
        send \"radware\r\"
    }
    timeout {
        puts \"ERROR: Timeout waiting for password prompt\"
        exit 1
    }
}

puts \"Password sent, waiting for login to complete...\"
# Configuration sequence - respond to specific prompts
puts \"Starting configuration sequence...\"

expect \"IP Address:\"
puts \"Found IP Address prompt, sending 10.10.1.20\"
send \"10.10.1.20\r\"

expect \"Netmask/Prefix:\"
puts \"Found Netmask prompt, sending 255.255.255.0\"
send \"255.255.255.0\r\"

expect \"Gateway:\"
puts \"Found Gateway prompt, sending 10.10.1.1\"
send \"10.10.1.1\r\"

expect \"Primary DNS Server:\"
puts \"Found Primary DNS prompt, sending 8.8.8.8\"
send \"8.8.8.8\r\"

expect \"Secondary DNS Server:\"
puts \"Found Secondary DNS prompt, sending 8.8.4.4\"
send \"8.8.4.4\r\"

expect \"Physical Management Interface*G1*:\"
puts \"Found Interface prompt, sending G1\"
send \"G1\r\"

expect \"Docker Subnet*ENTER to use it*:\"
puts \"Found Docker Subnet prompt, pressing ENTER\"
send \"\r\"

expect \"Apply these settings?*y/N*\"
puts \"Found Apply settings prompt, sending y\"
send \"y\r\"

expect \"Do you want to change the root user password?*y/N*:\"
puts \"Found root password prompt, sending n\"
send \"n\r\"

expect \"Do you want to disable ssh login for root user account*Y/n*:\"
puts \"Found SSH login prompt, sending n\"
send \"n\r\"

expect \"Enable and configure the NTP service?*Y/n*\"
puts \"Found NTP service prompt, sending n\"
send \"n\r\"

expect \"\\[CYBER-CONTROLLER\\]$\"
puts \"Found CYBER-CONTROLLER prompt, waiting 15 seconds before exit...\"
sleep 15
puts \"Sending exit command after 15 second wait\"
send \"exit\r\"

puts \"Configuration completed successfully!\"
expect eof
" 

echo ""
echo "✅ CC Auto-Configuration Process Completed!"
echo ""
echo "Configuration applied:"
echo "- IP Address: 10.10.1.20"
echo "- Netmask: 255.255.255.0" 
echo "- Gateway: 10.10.1.1"
echo "- Primary DNS: 8.8.8.8"
echo "- Secondary DNS: 8.8.4.4"
echo "- Interface: G1"
echo "- Docker Subnet: Default (172.17.0.0)"
echo "- Root password: Unchanged"
echo "- SSH root login: Enabled"
echo "- NTP service: Disabled"
echo ""
echo "Next steps:"
echo "1. CC should now show [CYBER-CONTROLLER]$ prompt"
echo "2. Access CC web interface: https://10.10.1.20"
echo "3. SSH access: ssh radware@$CC_IP"
echo "4. Check CC status and complete any remaining setup"
