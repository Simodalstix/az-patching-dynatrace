#!/bin/bash
# install_dynatrace_rhel.sh

# Get variables passed from Terraform
DYNATRACE_ENVIRONMENT_URL="${dynatrace_environment_url}"
DYNATRACE_API_TOKEN="${dynatrace_api_token}"
VM_NAME="${vm_name}"

# Ensure we have the necessary variables
if [ -z "$DYNATRACE_ENVIRONMENT_URL" ] || [ -z "$DYNATRACE_API_TOKEN" ]; then
    echo "Dynatrace environment URL or API token is missing. Skipping OneAgent installation."
    exit 0
fi

echo "Starting Dynatrace OneAgent installation for RHEL..."

# Download OneAgent installer
# This command assumes the API token has 'Installer download' permission.
# The URL needs to be adjusted based on your Dynatrace environment type (SaaS/Managed)
# and the correct download path.
# For SaaS: https://<your-tenant>.live.dynatrace.com/api/v1/deployment/installer/agent/unix/default/latest
# For Managed: https://<your-cluster-url>/e/<your-environment-id>/api/v1/deployment/installer/agent/unix/default/latest
# Refer to Dynatrace documentation for the precise URL.
# Example using environment URL from variable (adjust as needed for SaaS/Managed specific path)
wget -O /tmp/Dynatrace-OneAgent-Linux.sh "${DYNATRACE_ENVIRONMENT_URL}/api/v1/deployment/installer/agent/unix/default/latest?Api-Token=${DYNATRACE_API_TOKEN}"

if [ $? -ne 0 ]; then
    echo "Failed to download Dynatrace OneAgent installer."
    exit 1
fi

chmod +x /tmp/Dynatrace-OneAgent-Linux.sh

# Run installer with custom data parameters for Hostname
# Using --set-host-name is good for clarity in Dynatrace
# For production, consider using process group detection or host metadata from Dynatrace for naming.
/tmp/Dynatrace-OneAgent-Linux.sh --set-host-name="${VM_NAME}"

if [ $? -ne 0 ]; then
    echo "Dynatrace OneAgent installation failed."
    exit 1
fi

echo "Dynatrace OneAgent installed successfully on RHEL."