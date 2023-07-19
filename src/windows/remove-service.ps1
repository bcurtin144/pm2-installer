Write-Host "=== Remove Service ==="

$PM2_HOME = $env:PM2_HOME;
$PM2_SERVICE_DIRECTORY = $env:PM2_SERVICE_DIRECTORY;

Write-Host "Stopping service, this may take a minute or so.."

Stop-Service -name "pm2.exe"

Write-Host "Running pm2 kill.."
pm2 kill --silent

$wd = (Get-Item -Path '.\' -Verbose).FullName

if (($null -ne $PM2_SERVICE_DIRECTORY) -and (Test-Path $PM2_SERVICE_DIRECTORY)) {
  Set-Location $PM2_SERVICE_DIRECTORY
}

Write-Host "Running Node service uninstall script.."
& "$PM2_SERVICE_DIRECTORY\daemon\pm2.exe" uninstall

if (($null -ne $PM2_SERVICE_DIRECTORY) -and (Test-Path $PM2_SERVICE_DIRECTORY)) {
  Set-Location $wd

  Write-Host "Deleting pm2 service directory `"$PM2_SERVICE_DIRECTORY`""
  Remove-Item $PM2_SERVICE_DIRECTORY -Recurse -Force | Out-Null
}

if (($null -ne $PM2_HOME) -and (Test-Path $PM2_HOME)) {
  Write-Host "Deleting pm2 home directory `"$PM2_HOME`""
  Remove-Item $PM2_HOME -Recurse -Force | Out-Null
}

$PM2_PARENT_FOLDER = "$($env:ProgramData)\pm2"

if (($null -ne $PM2_PARENT_FOLDER) -and (Test-Path $PM2_PARENT_FOLDER)) {
  Write-Host "Deleting `"$PM2_PARENT_FOLDER`""
  Remove-Item $PM2_PARENT_FOLDER -Recurse -Force | Out-Null
}

Write-Host "Resetting shell environmental variables.."

$env:PM2_HOME = $null
$env:PM2_INSTALL_DIRECTORY = $null
$env:PM2_SERVICE_DIRECTORY = $null

Write-Host "Resetting machine environmental variables.."

[Environment]::SetEnvironmentVariable("PM2_HOME", $env:PM2_HOME, "Machine")
[Environment]::SetEnvironmentVariable("PM2_INSTALL_DIRECTORY", $env:PM2_INSTALL_DIRECTORY, "Machine")
[Environment]::SetEnvironmentVariable("PM2_SERVICE_DIRECTORY", $env:PM2_SERVICE_DIRECTORY, "Machine")

Set-Location $wd

Write-Host "=== Remove Service Complete ==="
