# install_dynatrace_windows.ps1

# Directly use variables passed from Terraform's templatefile
# Terraform's templatefile will replace these placeholders before the script runs.

# Ensure we have the necessary variables for proceeding with the installation (referencing the template variables directly)
if ([string]::IsNullOrEmpty("${dynatrace_environment_url}") -or [string]::IsNullOrEmpty("${dynatrace_api_token}")) {
    Write-Host "Dynatrace environment URL or API token is missing. Skipping OneAgent installation."
    Exit 0
}

Write-Host "Starting Dynatrace OneAgent installation for Windows..."

# Define the headers, including the Authorization header for the API token
# Note: Using the lowercase_underscore variable directly
$Headers = @{
    "Authorization" = "Api-Token ${dynatrace_api_token}"
}

# Construct the download URL. Note: The API token is now in the headers, not the URL query string.
# Adding ?arch=x86 to the URL for Windows installer as seen in common Dynatrace examples.
# Note: Using the lowercase_underscore variable directly
$downloadUrl = "${dynatrace_environment_url}/api/v1/deployment/installer/agent/windows/default/latest?arch=x86"
$outputPath = "C:\Temp\Dynatrace-OneAgent-Windows.exe"

# Create Temp directory if it doesn't exist
if (-not (Test-Path "C:\Temp")) {
    New-Item -Path "C:\Temp" -ItemType Directory | Out-Null
}

try {
    Write-Host "Downloading Dynatrace OneAgent from: $downloadUrl to $outputPath"
    # Use Invoke-WebRequest with the defined headers
    Invoke-WebRequest -Uri $downloadUrl -Headers $Headers -OutFile $outputPath -ErrorAction Stop
} catch {
    Write-Error "Failed to download Dynatrace OneAgent installer: $($_.Exception.Message)"
    Exit 1
}

# Verify if the file was downloaded
if (-not (Test-Path $outputPath)) {
    Write-Error "Downloaded file not found at $outputPath."
    Exit 1
}

# Run installer silently
# Using HOST_NAME for clarity in Dynatrace.
# For production, consider using process group detection or host metadata from Dynatrace for naming.
Write-Host "Running Dynatrace OneAgent installer..."
# Note: Using the lowercase_underscore vm_name directly
Start-Process -FilePath $outputPath -ArgumentList "/S /qn HOST_NAME=${vm_name}" -Wait -NoNewWindow -ErrorAction Stop

if ($LASTEXITCODE -ne 0) {
    Write-Error "Dynatrace OneAgent installation failed with exit code: $LASTEXITCODE"
    Exit 1
}

Write-Host "Dynatrace OneAgent installed successfully on Windows."