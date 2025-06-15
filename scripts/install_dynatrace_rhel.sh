#!/bin/bash
# install_dynatrace_rhel.sh

# --- Expand root filesystem to use full disk (important for AMA + agent installs) ---
echo "Checking and expanding root filesystem if needed..."

# Check if running on LVM-based system
if lsblk | grep -q "rootlv"; then
    echo "Detected LVM layout. Attempting to grow root logical volume..."
    lvextend -r -l +100%FREE /dev/mapper/rootvg-rootlv
else
    echo "Using XFS on non-LVM. Attempting xfs_growfs on root..."
    xfs_growfs /
fi

# Ensure we have the necessary variables (referencing the template variables directly)
if [ -z "${dynatrace_environment_url}" ] || [ -z "${dynatrace_api_token}" ]; then
    echo "Dynatrace environment URL or API token is missing. Skipping OneAgent installation."
    exit 0
fi

echo "Starting Dynatrace OneAgent installation for RHEL..."

# Download OneAgent installer using Authorization header
wget -O /tmp/Dynatrace-OneAgent-Linux.sh "${dynatrace_environment_url}/api/v1/deployment/installer/agent/unix/default/latest?arch=x86" --header="Authorization: Api-Token ${dynatrace_api_token}"

if [ $? -ne 0 ]; then
    echo "Failed to download Dynatrace OneAgent installer."
    exit 1
fi

chmod +x /tmp/Dynatrace-OneAgent-Linux.sh

# Install agent and assign VM name
/tmp/Dynatrace-OneAgent-Linux.sh --set-host-name="${vm_name}"

if [ $? -ne 0 ]; then
    echo "Dynatrace OneAgent installation failed."
    exit 1
fi

echo "Dynatrace OneAgent installed successfully on RHEL."
