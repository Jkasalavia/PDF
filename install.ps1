Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ZipUrl = "https://github.com/Jkasalavia/PDF/releases/download/V1/fastinstall.zip"
$InstallRoot = Join-Path $env:TEMP ("pdf-fastinstall-" + [guid]::NewGuid().ToString("N"))
$ZipPath = Join-Path $InstallRoot "fastinstall.zip"
$ExtractPath = Join-Path $InstallRoot "extracted"

function Write-Step {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-Host "==> $Message"
}

try {
    New-Item -ItemType Directory -Path $InstallRoot, $ExtractPath -Force | Out-Null

    Write-Step "Downloading installer package"
    Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipPath -UseBasicParsing

    Write-Step "Extracting package"
    Expand-Archive -LiteralPath $ZipPath -DestinationPath $ExtractPath -Force

    $CmdFiles = Get-ChildItem -LiteralPath $ExtractPath -Recurse -File -Filter "*.cmd"
    if ($CmdFiles.Count -eq 0) {
        throw "No .cmd file was found inside the downloaded zip."
    }

    if ($CmdFiles.Count -gt 1) {
        $Names = ($CmdFiles | ForEach-Object { $_.FullName }) -join [Environment]::NewLine
        throw "More than one .cmd file was found. Please keep only one command file in the zip:$([Environment]::NewLine)$Names"
    }

    $CmdFile = $CmdFiles[0]
    Write-Step "Running $($CmdFile.Name)"
    Push-Location $CmdFile.DirectoryName
    try {
        & $CmdFile.FullName
        if ($LASTEXITCODE -ne 0) {
            throw "$($CmdFile.Name) exited with code $LASTEXITCODE."
        }
    }
    finally {
        Pop-Location
    }
}
finally {
    if (Test-Path -LiteralPath $InstallRoot) {
        Remove-Item -LiteralPath $InstallRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
