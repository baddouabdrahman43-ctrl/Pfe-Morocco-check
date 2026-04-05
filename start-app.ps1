$ErrorActionPreference = 'Stop'

$rootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendDir = Join-Path $rootDir 'back-end'
$frontendScript = Join-Path $rootDir 'front-end\start-web-local.ps1'
$backendHealthUrl = 'http://127.0.0.1:5001/api/health'

function Test-ServiceReady {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Url
  )

  try {
    $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 3
    return $response.StatusCode -ge 200 -and $response.StatusCode -lt 500
  } catch {
    return $false
  }
}

function Wait-ServiceReady {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Url,
    [int]$MaxAttempts = 20,
    [int]$DelaySeconds = 2
  )

  for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
    if (Test-ServiceReady -Url $Url) {
      return $true
    }

    Start-Sleep -Seconds $DelaySeconds
  }

  return $false
}

if (-not (Test-Path $backendDir)) {
  throw "Backend directory not found: $backendDir"
}

if (-not (Test-Path $frontendScript)) {
  throw "Frontend launcher not found: $frontendScript"
}

Write-Host 'Checking backend status...' -ForegroundColor Cyan

if (Test-ServiceReady -Url $backendHealthUrl) {
  Write-Host 'Backend is already running on port 5001.' -ForegroundColor Green
} else {
  Write-Host 'Starting backend in a separate PowerShell window...' -ForegroundColor Cyan

  $backendCommand =
    "`$Host.UI.RawUI.WindowTitle = 'MoroccoCheck Backend'; " +
    "Set-Location '$backendDir'; " +
    "npm run dev"

  Start-Process `
    -FilePath 'powershell.exe' `
    -WorkingDirectory $backendDir `
    -ArgumentList '-NoExit', '-Command', $backendCommand | Out-Null

  Write-Host 'Waiting for backend health check...' -ForegroundColor Cyan

  if (-not (Wait-ServiceReady -Url $backendHealthUrl)) {
    throw "Backend did not become ready at $backendHealthUrl"
  }

  Write-Host 'Backend is ready.' -ForegroundColor Green
}

Write-Host 'Starting frontend on Chrome at http://127.0.0.1:3001 ...' -ForegroundColor Cyan
& $frontendScript
