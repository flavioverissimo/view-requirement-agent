$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectName = Split-Path -Leaf $scriptDir
$venvDir = Join-Path $scriptDir ".venv"
$requirementsFile = Join-Path $scriptDir "requirements.txt"
$requirementsHashFile = Join-Path $venvDir ".requirements.sha256"
$minimumPythonVersion = [Version]"3.10"

function Write-Step {
    param(
        [string]$Step,
        [string]$Message
    )

    Write-Host ""
    Write-Host "[$Step] $Message"
}

function Show-PythonInstallInstructions {
    @"
Python was not found on this computer, or the installed version is older than Python $minimumPythonVersion.

Choose one of the installation options below:

1. Official Python (includes IDLE)
   Download page: https://www.python.org/downloads/
   Installation steps:
   - Open the download page and choose the latest Python 3 release for your operating system.
   - Run the installer.
   - Enable the "Add python.exe to PATH" option before clicking "Install Now".
   - Finish the installation and close the installer.

2. Anaconda Distribution
   Download page: https://www.anaconda.com/download/success?reg=skipped
   Installation steps:
   - Open the download page and choose the installer for your operating system.
   - Run the installer and keep the default options unless your environment requires otherwise.
   - Finish the installation.
   - Open a new PowerShell window after the installation completes.

After installing Python, run one of the commands below from the project root:
  powershell -ExecutionPolicy Bypass -File .\setup.ps1
  .\setup.bat
"@ | Write-Host
}

function Get-PythonCandidate {
    $candidates = @(
        @{ Command = "py"; PrefixArgs = @("-3") },
        @{ Command = "python"; PrefixArgs = @() },
        @{ Command = "python3"; PrefixArgs = @() }
    )

    foreach ($candidate in $candidates) {
        try {
            & $candidate.Command @($candidate.PrefixArgs) -c "import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)" *> $null
            if ($LASTEXITCODE -eq 0) {
                return [PSCustomObject]@{
                    Command = $candidate.Command
                    PrefixArgs = [string[]]$candidate.PrefixArgs
                }
            }
        } catch {
            continue
        }
    }

    return $null
}

function Invoke-NativeChecked {
    param(
        [string]$Command,
        [string[]]$Arguments
    )

    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed: $Command $($Arguments -join ' ')"
    }
}

function Resolve-VenvPython {
    $candidates = @(
        (Join-Path $venvDir "Scripts\python.exe"),
        (Join-Path $venvDir "Scripts\python"),
        (Join-Path $venvDir "bin\python")
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return $candidate
        }
    }

    return $null
}

function Get-RequirementsHash {
    return (Get-FileHash -LiteralPath $requirementsFile -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Test-RequirementsHashMatches {
    if (-not (Test-Path -LiteralPath $requirementsHashFile -PathType Leaf)) {
        return $false
    }

    $storedHash = (Get-Content -LiteralPath $requirementsHashFile -Raw).Trim().ToLowerInvariant()
    $currentHash = Get-RequirementsHash
    return $storedHash -eq $currentHash
}

function Write-RequirementsHash {
    Set-Content -LiteralPath $requirementsHashFile -Value (Get-RequirementsHash) -Encoding ASCII
}

function Test-RequirementsInstalled {
    param(
        [string]$PythonExecutable,
        [switch]$Quiet
    )

    $inspectionScript = @'
from importlib import metadata
from pathlib import Path
import sys

try:
    from pip._vendor.packaging.requirements import Requirement
except Exception as error:
    raise SystemExit(f"Unable to inspect installed dependencies with pip: {error}")

requirements_path = Path(sys.argv[1])
missing_dependencies = []

for raw_line in requirements_path.read_text(encoding="utf-8").splitlines():
    line = raw_line.strip()
    if not line or line.startswith("#"):
        continue

    requirement = Requirement(line)

    try:
        installed_version = metadata.version(requirement.name)
    except metadata.PackageNotFoundError:
        missing_dependencies.append(f"{requirement.name} is not installed.")
        continue

    if requirement.specifier and installed_version not in requirement.specifier:
        missing_dependencies.append(
            f"{requirement.name} {installed_version} does not satisfy {requirement.specifier}."
        )

if missing_dependencies:
    print("\n".join(missing_dependencies), file=sys.stderr)
    raise SystemExit(1)
'@

    if ($Quiet) {
        $inspectionScript | & $PythonExecutable - $requirementsFile 1> $null 2> $null
    } else {
        $inspectionScript | & $PythonExecutable - $requirementsFile
    }

    return ($LASTEXITCODE -eq 0)
}

function Test-PipEnvironmentHealthy {
    param([string]$PythonExecutable)

    & $PythonExecutable -m pip check *> $null
    return ($LASTEXITCODE -eq 0)
}

function Show-NextSteps {
    param([string]$PythonExecutable)

    Write-Host ""
    Write-Host "Environment setup finished for $projectName."
    Write-Host ""
    Write-Host "To run the application:"
    Write-Host "  $PythonExecutable main.py"
    Write-Host ""
    Write-Host "To activate the virtual environment manually:"
    Write-Host "  .\.venv\Scripts\Activate.ps1"

    if (-not (Test-Path -LiteralPath (Join-Path $scriptDir ".env") -PathType Leaf)) {
        Write-Host ""
        Write-Host "Warning: .env was not found in the project root."
        Write-Host "Create a .env file before running the workflow if your environment requires API credentials."
    }
}

Set-Location -LiteralPath $scriptDir

if (-not (Test-Path -LiteralPath $requirementsFile -PathType Leaf)) {
    throw "requirements.txt was not found in the project root."
}

Write-Step "1/4" "Checking Python installation"
$pythonCandidate = Get-PythonCandidate
if ($null -eq $pythonCandidate) {
    Show-PythonInstallInstructions
    exit 1
}

Write-Step "2/4" "Preparing the virtual environment"
if (Test-Path -LiteralPath $venvDir -PathType Container) {
    Write-Host "Using the existing virtual environment at $venvDir"
} else {
    Write-Host "Creating a new virtual environment at $venvDir"
    Invoke-NativeChecked -Command $pythonCandidate.Command -Arguments (@($pythonCandidate.PrefixArgs) + @("-m", "venv", $venvDir))
}

$venvPython = Resolve-VenvPython
if ([string]::IsNullOrWhiteSpace($venvPython)) {
    throw "The virtual environment was created, but its Python executable could not be found."
}

Write-Step "3/4" "Checking project dependencies"
$dependenciesInstalled = Test-RequirementsInstalled -PythonExecutable $venvPython -Quiet
$pipEnvironmentHealthy = Test-PipEnvironmentHealthy -PythonExecutable $venvPython

if ($dependenciesInstalled -and $pipEnvironmentHealthy) {
    if (Test-RequirementsHashMatches) {
        Write-Host "All dependencies are already installed and match requirements.txt"
    } else {
        Write-Host "All dependencies are already installed. Updating the local requirements cache."
        Write-RequirementsHash
    }
} else {
    Write-Host "Installing or updating dependencies from requirements.txt"
    Invoke-NativeChecked -Command $venvPython -Arguments @("-m", "pip", "install", "-r", $requirementsFile)

    if (-not (Test-RequirementsInstalled -PythonExecutable $venvPython)) {
        throw "The environment still does not satisfy requirements.txt after installation."
    }

    Invoke-NativeChecked -Command $venvPython -Arguments @("-m", "pip", "check")
    Write-RequirementsHash
}

Write-Step "4/4" "Done"
Write-RequirementsHash
Show-NextSteps -PythonExecutable $venvPython
