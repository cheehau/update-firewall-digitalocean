# Dynamic IP Firewall Updater For Digital Ocean

## Introduction

As a developer, it's essential to secure your server by blocking access to certain ports like port 22 (SSH). However, if you have a dynamic IP address, it can be troublesome to manage firewall rules. This script helps simplify the process by automatically updating your firewall rules on DigitalOcean to allow only certain IP addresses, including your current dynamic IP.

## Features

- Fetches the list of firewalls from your DigitalOcean account.
- Allows you to select a specific firewall to update.
- Retrieves your current dynamic IP address.
- Preserves dedicated IP addresses for port 22 while removing unknown IPs.
- Adds your current dynamic IP to the firewall's inbound rules for port 22.
- Updates the firewall with the modified inbound rules using the DigitalOcean API.

## Prerequisites

- DigitalOcean API token: You'll need a valid DigitalOcean API token to access and modify your firewall rules.
- jq: Ensure that the `jq` command-line tool is installed. You can install it using the package manager for your operating system.

## Installation

1. Clone this repository to your local machine.
2. Make sure you have the necessary prerequisites mentioned above.
3. Set your DigitalOcean API token in the script: `api_token="YOUR_API_TOKEN"`.
4. Make the script executable: `chmod +x firewall_updater.sh`.

## Usage

1. Open a terminal and navigate to the script's directory.
2. Run the script: `./firewall_updater.sh`.
3. Follow the on-screen instructions to select the firewall and update the rules.
4. The script will fetch your current dynamic IP and modify the firewall rules accordingly.
5. After updating the firewall, the script will display a success or failure message.

## License

This project is licensed under the MIT License. You can find more details in the [LICENSE](LICENSE) file.

## Contributing

Contributions are welcome! If you encounter any issues or have suggestions for improvements, please feel free to submit a pull request or open an issue.

## Contact

For any questions or inquiries, please contact [Chee Hau](https://cheehau.dev).

