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
    Assert-True ((Get-WorkshopServiceAction -ProcessEvidence '' -ExpectedDirectory $repo -ExpectedCommand 'run\.py') -eq 'start') 'A missing service did not request startup.'
    Assert-True ((Get-WorkshopServiceAction -ProcessEvidence $ownedEvidence -ExpectedDirectory $repo -ExpectedCommand 'run\.py') -eq 'reuse') 'An owned service was not reused.'
    $foreignRejected = $false
    try {
        Get-WorkshopServiceAction -ProcessEvidence $foreignEvidence -ExpectedDirectory $repo -ExpectedCommand 'run\.py'
    } catch {
        $foreignRejected = $true
    }
    Assert-True $foreignRejected 'A foreign service owner was not rejected.'

    $skillPath = Get-MattPocockSetupSkillPath -UserProfile 'C:\Users\participant' -Version '1.3.1'
    Assert-True ($skillPath -match 'mattpocock-skills\\1\.3\.1\\skills\\engineering\\setup-matt-pocock-skills\\SKILL\.md$') 'The setup skill path did not bind to the requested plugin version.'

    $requestedJson = [Collections.Generic.List[string]]::new()
    $requestedWeb = [Collections.Generic.List[string]]::new()
    $getJson = {
        param($uri)
        $requestedJson.Add($uri)
        if ($uri -like '*/api/health') { return [pscustomobject]@{ status = 'ok' } }
        if ($uri -like '*page=2') { return [pscustomobject]@{ items = @([pscustomobject]@{ picture_uri = '/static/2.png' }); total_pages = 2 } }
        [pscustomobject]@{ items = @([pscustomobject]@{ picture_uri = '/static/1.png' }); total_pages = 2 }
    }.GetNewClosure()
    $getWeb = {
        param($uri)
        $requestedWeb.Add($uri)
        $contentType = if ($uri -like '*/static/*') { 'image/png' } else { 'text/html' }
        [pscustomobject]@{ StatusCode = 200; Headers = @{ 'Content-Type' = $contentType } }
    }.GetNewClosure()
    $postJson = { param($uri, $body) [pscustomobject]@{ access_token = 'test-token' } }
    $count = Invoke-WorkshopRuntimeChecks -BaseUrl 'http://workshop.test' -GetJson $getJson -GetWeb $getWeb -PostJson $postJson
    Assert-True ($count -eq 2) 'Runtime checks did not aggregate every catalog page.'
    Assert-True ($requestedJson.Contains('http://workshop.test/api/catalog/items?page=2')) 'Runtime checks skipped the second catalog page.'
    Assert-True ($requestedWeb.Contains('http://workshop.test/static/1.png') -and $requestedWeb.Contains('http://workshop.test/static/2.png')) 'Runtime checks skipped a product image.'
    Assert-True ($requestedWeb.Contains('http://workshop.test/favourites')) 'Runtime checks skipped the browser-facing Favourites route.'

    Write-Host 'Workshop verification helper tests passed.' -ForegroundColor Green
} finally {
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}
