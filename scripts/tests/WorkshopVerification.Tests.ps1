#Requires -Version 7.0
$ErrorActionPreference = 'Stop'
$module = Join-Path (Split-Path -Parent $PSScriptRoot) 'WorkshopVerification.psm1'
Import-Module $module -Force

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

$testRoot = Join-Path ([IO.Path]::GetTempPath()) "workshop-verification-$([guid]::NewGuid())"
try {
    $toolDirectory = Join-Path $testRoot 'nested\tools'
    New-Item -ItemType Directory -Path $toolDirectory -Force | Out-Null
    $toolPath = Join-Path $toolDirectory 'demo-tool.exe'
    Set-Content -LiteralPath $toolPath -Value 'fixture'

    $resolved = Find-WorkshopTool -Name 'missing-demo-tool.exe' -Patterns @('demo-tool.exe') -FallbackRoots @($testRoot) -SkipPath
    Assert-True ($resolved -eq $toolPath) 'Fallback tool discovery did not return the expected executable.'

    $repo = 'C:\workshop\repo\python-eshop\backend'
    $ownedEvidence = "C:\Python\python.exe run.py`n$repo\.venv\Scripts\python.exe run.py"
    Assert-True (Test-WorkshopProcessEvidence -Evidence $ownedEvidence -ExpectedDirectory $repo -ExpectedCommand 'run\.py') 'Repository-owned process evidence was rejected.'

    $foreignEvidence = 'C:\other-app\node.exe server.js'
    Assert-True (-not (Test-WorkshopProcessEvidence -Evidence $foreignEvidence -ExpectedDirectory $repo -ExpectedCommand 'run\.py')) 'Foreign process evidence was accepted.'

    $skillPath = Get-MattPocockSetupSkillPath -UserProfile 'C:\Users\participant' -Version '1.3.1'
    Assert-True ($skillPath -match 'mattpocock-skills\\1\.3\.1\\skills\\engineering\\setup-matt-pocock-skills\\SKILL\.md$') 'The setup skill path did not bind to the requested plugin version.'

    Write-Host 'Workshop verification helper tests passed.' -ForegroundColor Green
} finally {
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}
