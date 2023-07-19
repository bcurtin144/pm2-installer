Write-Host "=== Remove Packages ==="

Write-Host "Uninstalling packages.."

npm uninstall --global --loglevel=error "pm2"
npm uninstall --global --loglevel=error "@jessety/pm2-logrotate"

Write-Host "=== Remove Packages Complete ==="
