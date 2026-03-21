
param(
    [string]$SolutionName
)

$solutionFile = $SolutionName ? $SolutionName : "$(New-Guid)"

function Write-Header {
    param (
        [string]$text
    )
    Write-Host ""
    Write-Host -ForegroundColor Cyan "===== $text ====="
    Write-Host ""
}

try {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'
    $PSNativeCommandUseErrorActionPreference = $true

    Write-Header -ForegroundColor Yellow "Creating solution file: $solutionFile.slnx"
    dotnet new sln --name $solutionFile --format slnx --force
    $solutionFile = "$solutionFile.slnx"
    $projects = fd --glob *.csproj

    foreach ($chunk in ([Linq.Enumerable]::Chunk([string[]]$projects, 50))) {
        dotnet sln $solutionFile add --in-root $chunk
    }

    Write-Header -ForegroundColor Yellow "Restoring solution"
    dotnet restore $solutionFile -p:TreatWarningsAsErrors=false -p:WarningsAsErrors=

    Write-Header -ForegroundColor Yellow "Building solution"
    dotnet build $solutionFile --no-restore --no-dependencies -p:TreatWarningsAsErrors=false -p:WarningsAsErrors= | & "$PSScriptRoot/build-summary.ps1"
}
finally {
    if (!$SolutionName) {
        Write-Header -ForegroundColor Yellow "Deleting solution"
        Remove-Item $solutionFile
    }
}
