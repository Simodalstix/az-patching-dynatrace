#!/bin/bash
# install_dynatrace_rhel.sh

# Directly use variables passed from Terraform's templatefile
# Terraform's templatefile will replace these placeholders before the script runs.

# Ensure we have the necessary variables (referencing the template variables directly)
if [ -z "${dynatrace_environment_url}" ] || [ -z "${dynatrace_api_token}" ]; then
    echo "Dynatrace environment URL or API token is missing. Skipping OneAgent installation."
    exit 0
fi

echo "Starting Dynatrace OneAgent installation for RHEL..."

# Download OneAgent installer using Authorization header, not query parameter
# Adding ?arch=x86 to the URL for Linux installer as seen in Dynatrace examples.
# Note: Using the lowercase_underscore variables directly
wget -O /tmp/Dynatrace-OneAgent-Linux.sh "${dynatrace_environment_url}/api/v1/deployment/installer/agent/unix/default/latest?arch=x86" --header="Authorization: Api-Token ${dynatrace_api_token}"

if [ $? -ne 0 ]; then
    echo "Failed to download Dynatrace OneAgent installer."
    exit 1
fi

chmod +x /tmp/Dynatrace-OneAgent-Linux.sh

# Run installer with custom data parameters for Hostname
# Using --set-host-name is good for clarity in Dynatrace
# Note: Using the lowercase_underscore vm_name directly
/tmp/Dynatrace-OneAgent-Linux.sh --set-host-name="${vm_name}"

if [ $? -ne 0 ]; then
    echo "Dynatrace OneAgent installation failed."
    exit 1
fi

echo "Dynatrace OneAgent installed successfully on RHEL."