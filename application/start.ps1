Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$backendRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$apiDir = Join-Path $backendRoot "api"
$frontendDir = Join-Path $backendRoot "frontend"
$setupScript = Join-Path $backendRoot "setup.ps1"
$venvPython = Join-Path $apiDir ".venv\Scripts\python.exe"

function Write-Step([string]$Message) {
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Ok([string]$Message) {
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Resolve-NpmCommand() {
    $npmCmd = Get-Command npm.cmd -ErrorAction SilentlyContinue

    if ($npmCmd) {
        return $npmCmd.Source
    }

    $npm = Get-Command npm -ErrorAction SilentlyContinue

    if ($npm) {
        return $npm.Source
    }

    return $null
}

if (-not (Test-Path -LiteralPath $setupScript)) {
    throw "The setup script was not found at '$setupScript'."
}

Write-Step "Preparando o ambiente antes de iniciar a aplicacao."
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $setupScript

if ($LASTEXITCODE -ne 0) {
    throw "The environment setup failed. The application was not started."
}

if (-not (Test-Path -LiteralPath $venvPython)) {
    throw "The backend virtual environment was not found at '$venvPython'."
}

$npmCommand = Resolve-NpmCommand

if (-not $npmCommand) {
    throw "The npm executable was not found after the setup step."
}

$backendCommand = @"
$host.UI.RawUI.WindowTitle = 'Requirement Backend'
& '$venvPython' -m uvicorn main:app --reload
"@

$frontendCommand = @"
$host.UI.RawUI.WindowTitle = 'Requirement Frontend'
& '$npmCommand' run dev
"@

Write-Step "Abrindo o terminal do back-end."
Start-Process `
    -FilePath "powershell.exe" `
    -WorkingDirectory $apiDir `
    -ArgumentList @(
        "-NoExit",
        "-ExecutionPolicy",
        "Bypass",
        "-Command",
        $backendCommand
    )

Start-Sleep -Seconds 1

Write-Step "Abrindo o terminal do front-end."
Start-Process `
    -FilePath "powershell.exe" `
    -WorkingDirectory $frontendDir `
    -ArgumentList @(
        "-NoExit",
        "-ExecutionPolicy",
        "Bypass",
        "-Command",
        $frontendCommand
    )

Write-Host ""
Write-Ok "Os terminais do back-end e do front-end foram iniciados."
