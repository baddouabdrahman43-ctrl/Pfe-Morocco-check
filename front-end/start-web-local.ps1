$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Push-Location $scriptDir
try {
  flutter run -d chrome --web-port 3001 --no-web-resources-cdn
} finally {
  Pop-Location
}
