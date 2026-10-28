#Requires -Version 7.0
[CmdletBinding()]
param(
    [switch]$SkipRuntimeChecks,
    [switch]$CheckSkillInvocation
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $PSScriptRoot 'WorkshopVerification.psm1') -Force
$backend = Join-Path $repo 'python-eshop\backend'
$frontend = Join-Path $repo 'python-eshop\frontend'
$frontendPort = 4321
$backendPort = 8765
$stoppedFrontend = $false
$frontendWasRunning = $false

function Invoke-Checked {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string[]]$Arguments,
        [Parameter(Mandatory)][string]$WorkingDirectory
    )

    Push-Location -LiteralPath $WorkingDirectory
    try {
        Write-Host "> $FilePath $($Arguments -join ' ')" -ForegroundColor Cyan
        & $FilePath @Arguments
        if ($LASTEXITCODE -ne 0) {
            throw "$FilePath failed with exit code $LASTEXITCODE."
        }
    } finally {
        Pop-Location
    }
}

function Get-PortOwner {
    param([int]$Port)

    $listener = Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if (-not $listener) { return $null }
    Get-CimInstance Win32_Process -Filter "ProcessId = $($listener.OwningProcess)"
}

function Wait-WorkshopHttp {
    param([Parameter(Mandatory)][string]$Url, [int]$Seconds = 60)

    $deadline = (Get-Date).AddSeconds($Seconds)
    do {
        try {
            $response = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 4
            if ($response.StatusCode -eq 200) { return }
        } catch { }
        Start-Sleep -Milliseconds 500
    } while ((Get-Date) -lt $deadline)
    throw "Service did not become ready: $Url"
}

function Assert-WorkshopOwner {
    param(
        [Parameter(Mandatory)]$Process,
        [Parameter(Mandatory)][string]$ExpectedDirectory,
        [Parameter(Mandatory)][string]$ExpectedCommand,
        [Parameter(Mandatory)][int]$Port
    )

    $processTree = Get-WorkshopProcessEvidence -Process $Process
    if (-not (Test-WorkshopProcessEvidence -Evidence $processTree -ExpectedDirectory $ExpectedDirectory -ExpectedCommand $ExpectedCommand)) {
        throw "Port $Port belongs to an unrelated process (PID $($Process.ProcessId)); refusing to reuse or stop it."
    }
}

function Get-WorkshopProcessEvidence {
    param($Process)

    if (-not $Process) { return '' }
    $evidence = @()
    $current = $Process
    for ($depth = 0; $depth -lt 5 -and $current; $depth++) {
        $evidence += [string]$current.ExecutablePath
        $evidence += [string]$current.CommandLine
        if (-not $current.ParentProcessId) { break }
        $current = Get-CimInstance Win32_Process -Filter "ProcessId = $($current.ParentProcessId)" -ErrorAction SilentlyContinue
    }
    $evidence -join "`n"
}

function Start-WorkshopProcess {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string[]]$Arguments,
        [Parameter(Mandatory)][string]$WorkingDirectory
    )

    Start-Process -FilePath $FilePath -ArgumentList $Arguments -WorkingDirectory $WorkingDirectory `
        -WindowStyle Hidden -Environment @{ Path = $env:Path } | Out-Null
}

function Start-WorkshopFrontend {
    Start-WorkshopProcess -FilePath $npm -Arguments @('run', 'dev', '--', '--host', '127.0.0.1', '--port', "$frontendPort", '--strictPort') -WorkingDirectory $frontend
}

$toolRoots = @(
    (Join-Path (Split-Path -Parent $repo) '.tools'),
    (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'),
    (Join-Path $env:LOCALAPPDATA 'OpenAI\Codex\bin'),
    (Join-Path $env:USERPROFILE '.local\bin')
)
$uv = Find-WorkshopTool -Name 'uv.exe' -Patterns @('uv.exe') -FallbackRoots $toolRoots
$npm = Find-WorkshopTool -Name 'npm.cmd' -Patterns @('npm.cmd') -FallbackRoots $toolRoots
$codex = Find-WorkshopTool -Name 'codex.exe' -Patterns @('codex.exe', 'codex.cmd') -FallbackRoots $toolRoots
$nodeDirectory = Split-Path -Parent $npm
$env:Path = "$nodeDirectory;$env:Path"

Write-Host "uv: $uv"
Write-Host "npm: $npm"
Write-Host "codex: $codex"

$pluginData = (& $codex plugin list --json | Out-String) | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw 'Could not inspect Codex plugins.' }
$plugin = @($pluginData.installed | Where-Object { $_.pluginId -eq 'mattpocock-skills@mattpocock' })
if ($plugin.Count -ne 1 -or -not $plugin[0].enabled) {
    throw 'The mattpocock-skills@mattpocock plugin is not installed and enabled.'
}

$skillPath = Get-MattPocockSetupSkillPath -UserProfile $env:USERPROFILE -Version $plugin[0].version
if (-not (Test-Path -LiteralPath $skillPath)) {
    throw "The setup-matt-pocock-skills file for installed plugin version $($plugin[0].version) is missing."
}
Write-Host "setup skill: $skillPath"

if ($CheckSkillInvocation) {
    $prompt = @'
This is a read-only diagnostic. Attempt to load the installed $setup-matt-pocock-skills skill, but do not perform setup or modify files. If the named skill is available to this fresh Codex process, output exactly SKILL_AVAILABLE. Otherwise output exactly SKILL_UNAVAILABLE.
'@
    $skillResult = $prompt | & $codex exec --sandbox read-only - 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0 -or $skillResult -notmatch '(?m)^SKILL_AVAILABLE\s*$') {
        throw "The plugin is installed, but a fresh Codex process could not invoke setup-matt-pocock-skills. This is a Codex/plugin discoverability failure, not a successful setup.`n$skillResult"
    }
    Write-Host 'Fresh Codex skill invocation: passed' -ForegroundColor Green
}

$frontendOwner = Get-PortOwner -Port $frontendPort
if ($frontendOwner) {
    Assert-WorkshopOwner -Process $frontendOwner -ExpectedDirectory $frontend -ExpectedCommand 'vite' -Port $frontendPort
    $frontendWasRunning = $true
    Write-Host "Stopping workshop frontend PID $($frontendOwner.ProcessId) for a clean install."
    Stop-Process -Id $frontendOwner.ProcessId -Force
    $stoppedFrontend = $true
}

try {
    Invoke-Checked -FilePath $uv -Arguments @('sync', '--python', '3.13', '--frozen') -WorkingDirectory $backend
    Invoke-Checked -FilePath $uv -Arguments @('run', '--python', '3.13', 'pytest', '-q') -WorkingDirectory $backend
    Invoke-Checked -FilePath $npm -Arguments @('ci') -WorkingDirectory $frontend
    Invoke-Checked -FilePath $npm -Arguments @('test') -WorkingDirectory $frontend
    Invoke-Checked -FilePath $npm -Arguments @('run', 'build') -WorkingDirectory $frontend
    Invoke-Checked -FilePath $npm -Arguments @('audit') -WorkingDirectory $frontend
} finally {
    if ($stoppedFrontend) {
        Start-WorkshopFrontend
        Wait-WorkshopHttp -Url "http://127.0.0.1:$frontendPort/"
    }
}

if (-not $SkipRuntimeChecks) {
    $backendOwner = Get-PortOwner -Port $backendPort
    $backendAction = Get-WorkshopServiceAction -ProcessEvidence (Get-WorkshopProcessEvidence -Process $backendOwner) -ExpectedDirectory $backend -ExpectedCommand 'run\.py|uvicorn'
    if ($backendAction -eq 'start') {
        Write-Host 'Starting workshop backend.'
        Start-WorkshopProcess -FilePath $uv -Arguments @('run', '--python', '3.13', 'python', 'run.py') -WorkingDirectory $backend
    }

    if (-not $frontendWasRunning) {
        $frontendOwner = Get-PortOwner -Port $frontendPort
        $frontendAction = Get-WorkshopServiceAction -ProcessEvidence (Get-WorkshopProcessEvidence -Process $frontendOwner) -ExpectedDirectory $frontend -ExpectedCommand 'vite'
        if ($frontendAction -eq 'start') {
            Write-Host 'Starting workshop frontend.'
            Start-WorkshopFrontend
        }
    }

    Wait-WorkshopHttp -Url "http://127.0.0.1:$backendPort/api/health"
    Wait-WorkshopHttp -Url "http://127.0.0.1:$frontendPort/"

    $productCount = Invoke-WorkshopRuntimeChecks -BaseUrl "http://127.0.0.1:$frontendPort"
    Write-Host "Runtime API, proxy, $productCount catalog images, login, and Favourites route: passed" -ForegroundColor Green
}

Write-Host 'Workshop verification passed.' -ForegroundColor Green
