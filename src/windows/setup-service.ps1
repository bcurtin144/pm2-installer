param(
  [string] $PM2_HOME = "$($env:ProgramData)\pm2\home",
  [string] $PM2_SERVICE_DIRECTORY = "$($env:ProgramData)\pm2\service"
)

$ErrorActionPreference = "Stop"

function Set-ENV {
  $env:PM2_HOME = $PM2_HOME
  $env:PM2_INSTALL_DIRECTORY = $PM2_INSTALL_DIRECTORY
  $env:PM2_SERVICE_DIRECTORY = $PM2_SERVICE_DIRECTORY

  [Environment]::SetEnvironmentVariable("PM2_HOME", $env:PM2_HOME, "Machine")
  [Environment]::SetEnvironmentVariable("PM2_INSTALL_DIRECTORY", $env:PM2_INSTALL_DIRECTORY, "Machine")
  [Environment]::SetEnvironmentVariable("PM2_SERVICE_DIRECTORY", $env:PM2_SERVICE_DIRECTORY, "Machine")
}

function New-Directory {
  param([string] $Directory)

  Write-Host "Attempting to create `"$Directory`""

  if (Test-Path $Directory) {
    Write-Host "Directory `"$Directory`" already exists, no need to create it."
  } else {
    Write-Host "Directory `"$Directory`" does not exist, creating it.."
    New-Item -ItemType Directory -Force -Path $Directory | Out-Null
  }
}

function Set-Permissions {
  param([string] $Directory, [string] $User)

  Write-Host "Attempting to grant `"$User`" full permissions to `"$Directory`"."

  $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($User, "FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")

  try {
    $acl = Get-Acl -Path $Directory -ErrorAction Stop

    # $acl.SetAccessRuleProtection($true, $false)
    # $acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) | Out-Null }

    $acl.SetAccessRule($rule)

    Set-Acl -Path $Directory -AclObject $acl -ErrorAction Stop

    Write-Host "Successfully set permissions on `"$Directory`"."

  } catch {

    throw "Failed to set permissions on `"$Directory`". Details: $_"
  }
}
function Install-Service-Files {

  $source = ".\src\windows\pm2-service\"

  Write-Host "Copying service files from `"$source`" to `"$PM2_SERVICE_DIRECTORY`"..."

  Copy-Item -Path $source\* -Destination $PM2_SERVICE_DIRECTORY -Recurse -Force

  Write-Host "Copying files complete."

}


Write-Host "=== Creating Service ==="

# Discern where pm2 is installed
# Presumably this should be C:\ProgramData\npm\npm\, but we don't want to make any assumptions
Write-Host "Determining pm2 installation directory.."
$PM2_INSTALL_DIRECTORY = "$(npm config get prefix --global)\node_modules\pm2"

# Query for the name of the Local Service user by its security identifier
# https://support.microsoft.com/en-us/help/243330/well-known-security-identifiers-in-windows-operating-systems
# In English, this is "NT AUTHORITY\LOCAL SERVICE", but in Norwegian it's "NT-MYNDIGHET\LOKAL TJENESTE"
Write-Host "Determining Local Service user name (`"S-1-5-19`").."
$localServiceSID = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-19")
$ServiceUser = ($localServiceSID.Translate([System.Security.Principal.NTAccount])).Value

# Print out configuration
Write-Host "Configuration:"
Write-Host "  PM2_HOME:              $PM2_HOME"
Write-Host "  PM2_SERVICE_DIRECTORY: $PM2_SERVICE_DIRECTORY"
Write-Host "  PM2_INSTALL_DIRECTORY: $PM2_INSTALL_DIRECTORY"
Write-Host "  Service User:          $ServiceUser"
Write-Host ""

# Set the environmental variables we need (PM2_HOME, PM2_SERVICE_DIRECTORY and PM2_INSTALL_DIRECTORY) on a machine level
Set-Env

Write-Host "Generating WinSW XML configuration file"
node "$PSScriptRoot\pm2-service\generateXml.mjs" $PM2_SERVICE_DIRECTORY $ServiceUser

# Create the pm2\home and pm2\service folders
New-Directory -Directory $PM2_HOME
New-Directory -Directory $PM2_SERVICE_DIRECTORY

# Copy the service source code into the pm2\service folder
Install-Service-Files

# Set permissions on pm2\home and pm2\service
Set-Permissions -Directory $PM2_HOME -User $ServiceUser
Set-Permissions -Directory $PM2_SERVICE_DIRECTORY -User $ServiceUser

# Installing Windows service
& "$PM2_SERVICE_DIRECTORY\daemon\pm2.exe" install

Start-Sleep -Milliseconds 500

# Starting Windows service
& "$PM2_SERVICE_DIRECTORY\daemon\pm2.exe" start

Start-Sleep -Milliseconds 500

Write-Host "=== Creating Service Complete ==="
