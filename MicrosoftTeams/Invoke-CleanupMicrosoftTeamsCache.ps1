# Stop Teams process
$paramGetProcess = @{
   Name        = 'Teams'
   ErrorAction = 'SilentlyContinue'
}
$paramStopProcess = @{
   Force         = $true
   Confirm       = $false
   ErrorAction   = 'SilentlyContinue'
   WarningAction = 'SilentlyContinue'
}
$null = (Get-Process @paramGetProcess | Stop-Process @paramStopProcess)
# Calm down
Start-Sleep -Seconds 3
# Try again
$null = (Get-Process @paramGetProcess | Stop-Process @paramStopProcess)
# Cleanup
$paramGetProcess = $null
$paramStopProcess = $null
# Calm down, again
Start-Sleep -Seconds 2

# List of possible cache locations
$AllTeamsCachePath = @(
   "$env:APPDATA\Microsoft\Teams"
   "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe"
)

# Loop over our list of Catch path values
foreach ($TeamsCachePath in $AllTeamsCachePath)
{
   # Does the path exist?
   if (Test-Path -Path $TeamsCachePath -ErrorAction SilentlyContinue) 
   {
      # Delete the content
      $null = (Get-ChildItem -Path $TeamsCachePath -Recurse -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue -WarningAction SilentlyContinue)
   }
}
