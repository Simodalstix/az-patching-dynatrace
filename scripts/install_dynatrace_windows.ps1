# install_dynatrace_windows.ps1

# Get variables passed from Terraform
$dynatraceEnvironmentUrl = "${dynatrace_environment_url}"
$dynatraceApiToken = "${dynatrace_api_token}"
$vmName = "${vm_name}"

# Ensure we have the necessary variables
if ([string]::IsNullOrEmpty($dynatraceEnvironmentUrl) -or [string]::IsNullOrEmpty($dynatraceApiToken)) {
    Write-Host "Dynatrace environment URL or API token is missing. Skipping OneAgent installation."
    Exit 0
}

Write-Host "Starting Dynatrace OneAgent installation for Windows..."

$downloadUrl = "${dynatraceEnvironmentUrl}/api/v1/deployment/installer/agent/windows/default/latest?Api-Token=${dynatraceApiToken}"
$outputPath = "C:\Temp\Dynatrace-OneAgent-Windows.exe"

# Create Temp directory if it doesn't exist
if (-not (Test-Path "C:\Temp")) {
    New-Item -Path "C:\Temp" -ItemType Directory | Out-Null
}

try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $outputPath
} catch {
    Write-Error "Failed to download Dynatrace OneAgent installer: $($_.Exception.Message)"
    Exit 1
}

if (-not (Test-Path $outputPath)) {
    Write-Error "Downloaded file not found at $outputPath."
    Exit 1
}

# Run installer silently
# Using HOST_NAME for clarity in Dynatrace.
# For production, consider using process group detection or host metadata from Dynatrace for naming.
Start-Process -FilePath $outputPath -ArgumentList "/S /qn HOST_NAME=$vmName" -Wait -NoNewWindow -ErrorAction Stop

if ($LASTEXITCODE -ne 0) {
    Write-Error "Dynatrace OneAgent installation failed with exit code: $LASTEXITCODE"
    Exit 1
}

Write-Host "Dynatrace OneAgent installed successfully on Windows."