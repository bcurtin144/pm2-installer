Write-Host "=== Install Packages ==="

$Epoch = Get-Date

$pm2_package = "$(node src/tools/dependencies/echo.js pm2)"
$pm2_logrotate_package = "$(node src/tools/dependencies/echo.js @jessety/pm2-logrotate)"

# Print out the versions of this package, node, and npm for this host
node src\bundle-info\current.js

Write-Host "Using: "
Write-Host " $pm2_package"
Write-Host " $pm2_logrotate_package"

# Check connectivity to registry.npmjs.org
node src\tools\npm-online.js

if ($? -eq $True) {

  # We *can* connect to the npm registry

  Write-Host "Installing packages.."

  $PriorToInstall = Get-Date

  npm install --global --loglevel=error --no-audit --no-fund $pm2_package
  npm install --global --loglevel=error --no-audit --no-fund $pm2_logrotate_package
  npm install --global --loglevel=error --no-audit --no-fund $node_windows_package


  $daemonDirectory = ".\src\windows\pm2-service\daemon"

  New-Item -ItemType Directory -Force -Path $daemonDirectory | Out-Null

  $winswURL = "https://github.com/winsw/winsw/releases/download/v2.12.0/WinSW.NET461.exe"
  Invoke-WebRequest -Uri $winswURL -OutFile "$daemonDirectory\pm2.exe"
  

  Write-Host "Installing packages took $([Math]::Floor($(Get-Date).Subtract($PriorToInstall).TotalSeconds)) seconds."

}

# Enable execution of pm2's powershell script, so the current user can interact with the pm2 powershell script
$script_path = "$(npm config get prefix)\pm2.ps1"

if (Test-Path $script_path) {
  Write-Host "Unblocking script at $script_path.."
  Unblock-File -Path $script_path
}

$TotalDuration = $(Get-Date).Subtract($Epoch)

Write-Host "=== Install Packages Complete: took $([Math]::Floor($TotalDuration.TotalSeconds)) seconds ==="
