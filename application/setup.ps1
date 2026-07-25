Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$backendRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$apiDir = Join-Path $backendRoot "api"
$frontendDir = Join-Path $backendRoot "frontend"
$venvDir = Join-Path $apiDir ".venv"
$venvPython = Join-Path $venvDir "Scripts\python.exe"
$requirementsFile = Join-Path $apiDir "requirements.txt"
$requirementsMarker = Join-Path $venvDir ".requirements.sha256"
$frontendLockFile = Join-Path $frontendDir "package-lock.json"
$frontendPackageFile = Join-Path $frontendDir "package.json"
$frontendNodeModulesDir = Join-Path $frontendDir "node_modules"
$frontendMarker = Join-Path $frontendNodeModulesDir ".package-lock.sha256"

function Write-Step([string]$Message) {
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Skip([string]$Message) {
    Write-Host "[SKIP] $Message" -ForegroundColor Yellow
}

function Write-Ok([string]$Message) {
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Resolve-PythonCommand() {
    $python = Get-Command python -ErrorAction SilentlyContinue

    if ($python) {
        return @{
            Executable = $python.Source
            Prefix = @()
        }
    }

    $pyLauncher = Get-Command py -ErrorAction SilentlyContinue

    if ($pyLauncher) {
        return @{
            Executable = $pyLauncher.Source
            Prefix = @("-3")
        }
    }

    return $null
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

function Invoke-BasePython([string[]]$Arguments) {
    & $script:pythonCommand.Executable @($script:pythonCommand.Prefix + $Arguments)
}

function Get-FileDigest([string]$FilePath) {
    $pythonCode = @'
import hashlib
import pathlib
import sys

print(hashlib.sha256(pathlib.Path(sys.argv[1]).read_bytes()).hexdigest())
'@

    $output = & $script:pythonCommand.Executable @(
        $script:pythonCommand.Prefix +
        @("-c", $pythonCode, $FilePath)
    )

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to compute SHA-256 for '$FilePath'."
    }

    return ($output | Select-Object -Last 1).Trim()
}

function Get-StoredDigest([string]$FilePath) {
    if (-not (Test-Path -LiteralPath $FilePath)) {
        return $null
    }

    return (Get-Content -LiteralPath $FilePath -Raw).Trim()
}

function Set-StoredDigest([string]$FilePath, [string]$Digest) {
    Set-Content -LiteralPath $FilePath -Value $Digest -NoNewline -Encoding ASCII
}

function Get-RequirementPackages([string]$FilePath) {
    $packages = [System.Collections.Generic.List[string]]::new()

    foreach ($line in Get-Content -LiteralPath $FilePath) {
        $trimmed = $line.Trim()

        if (-not $trimmed -or $trimmed.StartsWith("#") -or $trimmed.StartsWith("-")) {
            continue
        }

        $match = [regex]::Match($trimmed, "^[A-Za-z0-9_.-]+")

        if ($match.Success -and -not $packages.Contains($match.Value)) {
            $packages.Add($match.Value)
        }
    }

    return $packages
}

function Test-ApiRequirementsInstalled([string]$PythonPath, [string]$FilePath) {
    if (-not (Test-Path -LiteralPath $PythonPath)) {
        return $false
    }

    foreach ($package in Get-RequirementPackages -FilePath $FilePath) {
        & $PythonPath -m pip show $package *> $null

        if ($LASTEXITCODE -ne 0) {
            return $false
        }
    }

    return $true
}

function Test-FrontendDependenciesInstalled() {
    if (-not (Test-Path -LiteralPath $frontendNodeModulesDir)) {
        return $false
    }

    Push-Location $frontendDir
    try {
        & $script:npmCommand list --depth=0 --silent *> $null
        return $LASTEXITCODE -eq 0
    }
    finally {
        Pop-Location
    }
}

if (-not (Test-Path -LiteralPath $apiDir -PathType Container)) {
    throw "The 'api' directory was not found at '$apiDir'."
}

if (-not (Test-Path -LiteralPath $frontendDir -PathType Container)) {
    throw "The 'frontend' directory was not found at '$frontendDir'."
}

$pythonCommand = Resolve-PythonCommand
$nodeCommand = Get-Command node -ErrorAction SilentlyContinue
$npmCommand = Resolve-NpmCommand
$missingDependencies = [System.Collections.Generic.List[string]]::new()

if (-not $pythonCommand) {
    $missingDependencies.Add("Python: https://www.python.org/downloads/")
}

if (-not $nodeCommand) {
    $missingDependencies.Add("Node.js: https://nodejs.org/en/download")
}

if (-not $npmCommand) {
    $missingDependencies.Add("npm: https://nodejs.org/en/download")
}

if ($missingDependencies.Count -gt 0) {
    Write-Host ""
    Write-Host "Nao foi possivel continuar porque as dependencias abaixo nao estao instaladas:" -ForegroundColor Red

    foreach ($dependency in $missingDependencies) {
        Write-Host " - $dependency" -ForegroundColor Red
    }

    exit 1
}

Write-Step "Python detectado em '$($pythonCommand.Executable)'."
Write-Step "Node detectado em '$($nodeCommand.Source)'."
Write-Step "npm detectado em '$npmCommand'."

if (-not (Test-Path -LiteralPath $venvPython)) {
    Write-Step "Criando o ambiente virtual em '$venvDir'."

    Push-Location $apiDir
    try {
        Invoke-BasePython -Arguments @("-m", "venv", ".venv")
    }
    finally {
        Pop-Location
    }

    if (-not (Test-Path -LiteralPath $venvPython)) {
        throw "Falha ao criar o ambiente virtual em '$venvDir'."
    }

    Write-Ok "Ambiente virtual criado."
}
else {
    Write-Skip "Ambiente virtual ja existe em '$venvDir'."
}

$requirementsDigest = Get-FileDigest -FilePath $requirementsFile
$storedRequirementsDigest = Get-StoredDigest -FilePath $requirementsMarker
$apiDependenciesReady = $false

if ($storedRequirementsDigest -and $storedRequirementsDigest -eq $requirementsDigest) {
    $apiDependenciesReady = $true
}
elseif (Test-ApiRequirementsInstalled -PythonPath $venvPython -FilePath $requirementsFile) {
    Set-StoredDigest -FilePath $requirementsMarker -Digest $requirementsDigest
    $apiDependenciesReady = $true
}

if ($apiDependenciesReady) {
    Write-Skip "Dependencias do backend ja estao instaladas."
}
else {
    Write-Step "Instalando dependencias do backend."

    Push-Location $apiDir
    try {
        & $venvPython -m pip install -r requirements.txt
    }
    finally {
        Pop-Location
    }

    Set-StoredDigest -FilePath $requirementsMarker -Digest $requirementsDigest
    Write-Ok "Dependencias do backend instaladas."
}

$frontendManifestFile = if (Test-Path -LiteralPath $frontendLockFile) {
    $frontendLockFile
}
else {
    $frontendPackageFile
}

$frontendDigest = Get-FileDigest -FilePath $frontendManifestFile
$storedFrontendDigest = Get-StoredDigest -FilePath $frontendMarker
$frontendDependenciesReady = $false

if ($storedFrontendDigest -and $storedFrontendDigest -eq $frontendDigest) {
    $frontendDependenciesReady = $true
}
elseif (Test-FrontendDependenciesInstalled) {
    if (-not (Test-Path -LiteralPath $frontendNodeModulesDir)) {
        New-Item -ItemType Directory -Path $frontendNodeModulesDir | Out-Null
    }

    Set-StoredDigest -FilePath $frontendMarker -Digest $frontendDigest
    $frontendDependenciesReady = $true
}

if ($frontendDependenciesReady) {
    Write-Skip "Dependencias do front-end ja estao instaladas."
}
else {
    Write-Step "Instalando dependencias do front-end."

    Push-Location $frontendDir
    try {
        & $npmCommand install
    }
    finally {
        Pop-Location
    }

    Set-StoredDigest -FilePath $frontendMarker -Digest $frontendDigest
    Write-Ok "Dependencias do front-end instaladas."
}

Write-Host ""
Write-Host "Ambiente preparado com sucesso." -ForegroundColor Green
Write-Host "Abra 2 terminais e execute os comandos abaixo nesta ordem:" -ForegroundColor Green
Write-Host ""
Write-Host "1. Back-end" -ForegroundColor Cyan
Write-Host "   cd `"$apiDir`""
Write-Host "   .\.venv\Scripts\Activate.ps1"
Write-Host "   uvicorn main:app --reload"
Write-Host ""
Write-Host "2. Front-end" -ForegroundColor Cyan
Write-Host "   cd `"$frontendDir`""
Write-Host "   npm run dev"
Write-Host ""
Write-Host "Simpler option:" -ForegroundColor Cyan
Write-Host " - To prepare and start everything automatically on Windows, run .\start.ps1"
