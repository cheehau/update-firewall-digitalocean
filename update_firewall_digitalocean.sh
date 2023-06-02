#!/bin/bash
#
# Config
## DigitalOcean API token
api_token="YOUR_API_TOKEN"
#
## Preserve dedicated IP addresses for port 22
preserved_ips=("YOUR_IPs")
#
## URLs
ip_url="ifconfig.me"
forge_ip_url="https://forge.laravel.com/ips-v4.txt"
#
#
#
#
#
# Check if jq command is available
if ! command -v jq &>/dev/null; then
  echo "jq command not found. Please install jq to run this script."
  exit 1
fi

# Fetch the list of firewalls
response=$(curl -s -X GET -H "Authorization: Bearer $api_token" "https://api.digitalocean.com/v2/firewalls")

# Extract firewall IDs and names
ids=($(echo "$response" | jq -r '.firewalls[].id'))
names=($(echo "$response" | jq -r '.firewalls[].name'))

# Display the list of firewalls and prompt the user to select one
echo "Available Firewalls:"
for ((i=0; i<${#names[@]}; i++)); do
  echo "$(($i+1)). ${names[$i]}"
done

echo -n "Select a firewall (enter the corresponding number): "
read choice

# Validate the user's choice
if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#ids[@]})); then
  selected_firewall_id=${ids[$(($choice-1))]}
  selected_firewall_name=${names[$(($choice-1))]}
  echo "Selected Firewall: ${names[$(($choice-1))]} (ID: $selected_firewall_id)"
else
  echo "Invalid choice. Exiting."
  exit 1
fi

# Get the current dynamic IP
current_ip=$(curl -s $ip_url)

# Fetch the list of preserved IPs from the Laravel Forge URL
forge_ips=($(curl -s $forge_ip_url))

# Get default configuration
firewall_response=$(curl -s -X GET -H "Authorization: Bearer $api_token" "https://api.digitalocean.com/v2/firewalls/$selected_firewall_id")
firewall_inbound_rules="[ ]"
firewall_outbound_rules=$(echo "$firewall_response" | jq '.firewall.outbound_rules' )
firewall_droplet_ids=$(echo "$firewall_response" | jq '.firewall.droplet_ids' )
firewall_tags=$(echo "$firewall_response" | jq '.firewall.tags' )

# Check if the current IP is already present in the inbound rules
if ! echo "$firewall_inbound_rules" | jq -e ".[] | select(.protocol == \"tcp\" and .ports == \"22\" and .sources.addresses[] == \"$current_ip\")" > /dev/null; then
  # Add the current IP to the inbound rules
  firewall_inbound_rules=$(echo "$firewall_inbound_rules" | jq --arg ip "$current_ip" '. + [{"protocol": "tcp", "ports": "22", "sources": {"addresses": [$ip]}}]')
fi

# Add preserved IPs for port 22
for ip in "${preserved_ips[@]}"; do
  if ! echo "$firewall_inbound_rules" | jq -e ".[] | select(.protocol == \"tcp\" and .ports == \"22\" and .sources.addresses[] == \"$ip\")" > /dev/null; then
    # Add preserved IP to the inbound rules
    firewall_inbound_rules=$(echo "$firewall_inbound_rules" | jq --arg ip "$ip" '. + [{"protocol": "tcp", "ports": "22", "sources": {"addresses": [$ip]}}]')
  fi
done

# Add Forge IPs for port 22
for ip in "${forge_ips[@]}"; do
  if ! echo "$firewall_inbound_rules" | jq -e ".[] | select(.protocol == \"tcp\" and .ports == \"22\" and .sources.addresses[] == \"$ip\")" > /dev/null; then
    # Add preserved IP to the inbound rules
    firewall_inbound_rules=$(echo "$firewall_inbound_rules" | jq --arg ip "$ip" '. + [{"protocol": "tcp", "ports": "22", "sources": {"addresses": [$ip]}}]')
  fi
done

# Port 443
if ! echo "$firewall_inbound_rules" | jq -e ".[] | select(.protocol == \"tcp\" and .ports == \"443\")" > /dev/null; then
  # Add the current IP to the inbound rules
  firewall_inbound_rules=$(echo "$firewall_inbound_rules" | jq '. + [{"protocol": "tcp", "ports": "443", "sources": {"addresses": [ "0.0.0.0/0", "::/0" ]}}]')
fi

# Port 80
if ! echo "$firewall_inbound_rules" | jq -e ".[] | select(.protocol == \"tcp\" and .ports == \"80\")" > /dev/null; then
  # Add the current IP to the inbound rules
  firewall_inbound_rules=$(echo "$firewall_inbound_rules" | jq '. + [{"protocol": "tcp", "ports": "80", "sources": {"addresses": [ "0.0.0.0/0", "::/0" ]}}]')
fi

# Combine
payload='{"name": "'$selected_firewall_name'","inbound_rules": '$firewall_inbound_rules',"outbound_rules": '$firewall_outbound_rules',"droplet_ids": '$firewall_droplet_ids',"tags": '$firewall_tags'}'

# Execute
response=$(curl -s -o /dev/null -w "%{http_code}" -X PUT -H "Content-Type: application/json" -H "Authorization: Bearer $api_token" -d "$payload" "https://api.digitalocean.com/v2/firewalls/$selected_firewall_id")

# Check the response code
if [[ "$response" == "200" ]]; then
  echo "Firewall updated successfully!"
  exit 0
else
  echo "Failed to update the firewall. Response code: $response"
  exit 1
fi
