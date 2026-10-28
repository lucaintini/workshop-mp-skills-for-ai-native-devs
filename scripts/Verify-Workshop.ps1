#Requires -Version 7.0
[CmdletBinding()]
param(
    [switch]$SkipRuntimeChecks,
    [switch]$CheckSkillInvocation
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$backend = Join-Path $repo 'python-eshop\backend'
$frontend = Join-Path $repo 'python-eshop\frontend'
$frontendPort = 4321
$backendPort = 8765
$stoppedFrontend = $false
$frontendWasRunning = $false

function Resolve-WorkshopTool {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string[]]$Patterns
    )

    $command = Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) { return $command.Source }

    $roots = @(
        (Join-Path (Split-Path -Parent $repo) '.tools'),
        (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'),
        (Join-Path $env:LOCALAPPDATA 'OpenAI\Codex\bin'),
        (Join-Path $env:USERPROFILE '.local\bin')
    ) | Where-Object { Test-Path -LiteralPath $_ }

    foreach ($root in $roots) {
        foreach ($pattern in $Patterns) {
            $match = Get-ChildItem -LiteralPath $root -Recurse -File -Filter $pattern -ErrorAction SilentlyContinue |
                Sort-Object FullName -Descending |
                Select-Object -First 1
            if ($match) { return $match.FullName }
        }
    }

    throw "Required tool '$Name' was not found on PATH or in known workshop, WinGet, or Codex locations."
}

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

    $evidence = @()
    $current = $Process
    for ($depth = 0; $depth -lt 5 -and $current; $depth++) {
        $evidence += [string]$current.ExecutablePath
        $evidence += [string]$current.CommandLine
        if (-not $current.ParentProcessId) { break }
        $current = Get-CimInstance Win32_Process -Filter "ProcessId = $($current.ParentProcessId)" -ErrorAction SilentlyContinue
    }
    $processTree = $evidence -join "`n"
    if ($processTree -notmatch $ExpectedCommand -or $processTree -notmatch [regex]::Escape($ExpectedDirectory)) {
        throw "Port $Port belongs to an unrelated process (PID $($Process.ProcessId)); refusing to reuse or stop it."
    }
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

$uv = Resolve-WorkshopTool -Name 'uv.exe' -Patterns @('uv.exe')
$npm = Resolve-WorkshopTool -Name 'npm.cmd' -Patterns @('npm.cmd')
$codex = Resolve-WorkshopTool -Name 'codex.exe' -Patterns @('codex.exe', 'codex.cmd')
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

$skillPath = Join-Path $env:USERPROFILE ".codex\plugins\cache\mattpocock\mattpocock-skills\$($plugin[0].version)\skills\engineering\setup-matt-pocock-skills\SKILL.md"
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
        Start-WorkshopProcess -FilePath $npm -Arguments @('run', 'dev', '--', '--host', '127.0.0.1', '--port', "$frontendPort", '--strictPort') -WorkingDirectory $frontend
        Wait-WorkshopHttp -Url "http://127.0.0.1:$frontendPort/"
    }
}

if (-not $SkipRuntimeChecks) {
    $backendOwner = Get-PortOwner -Port $backendPort
    if ($backendOwner) {
        Assert-WorkshopOwner -Process $backendOwner -ExpectedDirectory $backend -ExpectedCommand 'run\.py|uvicorn' -Port $backendPort
    } else {
        Write-Host 'Starting workshop backend.'
        Start-WorkshopProcess -FilePath $uv -Arguments @('run', '--python', '3.13', 'python', 'run.py') -WorkingDirectory $backend
    }

    if (-not $frontendWasRunning) {
        $frontendOwner = Get-PortOwner -Port $frontendPort
        if ($frontendOwner) {
            Assert-WorkshopOwner -Process $frontendOwner -ExpectedDirectory $frontend -ExpectedCommand 'vite' -Port $frontendPort
        } else {
            Write-Host 'Starting workshop frontend.'
            Start-WorkshopProcess -FilePath $npm -Arguments @('run', 'dev', '--', '--host', '127.0.0.1', '--port', "$frontendPort", '--strictPort') -WorkingDirectory $frontend
        }
    }

    Wait-WorkshopHttp -Url "http://127.0.0.1:$backendPort/api/health"
    Wait-WorkshopHttp -Url "http://127.0.0.1:$frontendPort/"

    $base = "http://127.0.0.1:$frontendPort"
    $health = Invoke-RestMethod -Uri "$base/api/health" -TimeoutSec 15
    if ($health.status -ne 'ok') { throw 'Backend proxy health check failed.' }

    $catalog = Invoke-RestMethod -Uri "$base/api/catalog/items" -TimeoutSec 15
    if (@($catalog.items).Count -lt 1) { throw 'The catalog is empty.' }
    $products = @($catalog.items)
    for ($page = 2; $page -le $catalog.total_pages; $page++) {
        $nextPage = Invoke-RestMethod -Uri "$base/api/catalog/items?page=$page" -TimeoutSec 15
        $products += @($nextPage.items)
    }
    foreach ($product in $products) {
        $image = Invoke-WebRequest -UseBasicParsing -Uri "$base$($product.picture_uri)" -TimeoutSec 15
        if ($image.StatusCode -ne 200 -or $image.Headers['Content-Type'] -notmatch '^image/') {
            throw "Product image check failed: $($product.picture_uri)"
        }
    }

    $body = @{ email = 'demouser@perthai.com.au'; password = 'Pass@word1' } | ConvertTo-Json
    $auth = Invoke-RestMethod -Method Post -Uri "$base/api/auth/login" -ContentType 'application/json' -Body $body -TimeoutSec 15
    if (-not $auth.access_token) { throw 'Demo account login failed.' }
    $favouritesPage = Invoke-WebRequest -UseBasicParsing -Uri "$base/favourites" -TimeoutSec 15
    if ($favouritesPage.StatusCode -ne 200) { throw 'The browser-facing Favourites route failed.' }
    Write-Host "Runtime API, proxy, $($products.Count) catalog images, login, and Favourites route: passed" -ForegroundColor Green
}

Write-Host 'Workshop verification passed.' -ForegroundColor Green
