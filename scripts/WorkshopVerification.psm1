function Find-WorkshopTool {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string[]]$Patterns,
        [Parameter(Mandatory)][string[]]$FallbackRoots,
        [switch]$SkipPath
    )

    if (-not $SkipPath) {
        $command = Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($command) { return $command.Source }
    }

    foreach ($root in $FallbackRoots | Where-Object { Test-Path -LiteralPath $_ }) {
        foreach ($pattern in $Patterns) {
            $match = Get-ChildItem -LiteralPath $root -Recurse -File -Filter $pattern -ErrorAction SilentlyContinue |
                Sort-Object FullName -Descending |
                Select-Object -First 1
            if ($match) { return $match.FullName }
        }
    }

    throw "Required tool '$Name' was not found on PATH or in known fallback locations."
}

function Test-WorkshopProcessEvidence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Evidence,
        [Parameter(Mandatory)][string]$ExpectedDirectory,
        [Parameter(Mandatory)][string]$ExpectedCommand
    )

    $Evidence -match $ExpectedCommand -and $Evidence -match [regex]::Escape($ExpectedDirectory)
}

function Get-MattPocockSetupSkillPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$UserProfile,
        [Parameter(Mandatory)][string]$Version
    )

    Join-Path $UserProfile ".codex\plugins\cache\mattpocock\mattpocock-skills\$Version\skills\engineering\setup-matt-pocock-skills\SKILL.md"
}

function Get-WorkshopServiceAction {
    [CmdletBinding()]
    param(
        [AllowEmptyString()][string]$ProcessEvidence,
        [Parameter(Mandatory)][string]$ExpectedDirectory,
        [Parameter(Mandatory)][string]$ExpectedCommand
    )

    if (-not $ProcessEvidence) { return 'start' }
    if (Test-WorkshopProcessEvidence -Evidence $ProcessEvidence -ExpectedDirectory $ExpectedDirectory -ExpectedCommand $ExpectedCommand) {
        return 'reuse'
    }
    throw 'The listening port belongs to an unrelated process.'
}

function Invoke-WorkshopRuntimeChecks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$BaseUrl,
        [scriptblock]$GetJson,
        [scriptblock]$GetWeb,
        [scriptblock]$PostJson
    )

    if (-not $GetJson) {
        $GetJson = { param($uri) Invoke-RestMethod -Uri $uri -TimeoutSec 15 }
    }
    if (-not $GetWeb) {
        $GetWeb = { param($uri) Invoke-WebRequest -UseBasicParsing -Uri $uri -TimeoutSec 15 }
    }
    if (-not $PostJson) {
        $PostJson = {
            param($uri, $body)
            Invoke-RestMethod -Method Post -Uri $uri -ContentType 'application/json' -Body $body -TimeoutSec 15
        }
    }

    $health = & $GetJson "$BaseUrl/api/health"
    if ($health.status -ne 'ok') { throw 'Backend proxy health check failed.' }

    $homePage = & $GetWeb "$BaseUrl/"
    if ($homePage.StatusCode -ne 200 -or $homePage.Headers['Content-Security-Policy'] -notmatch "frame-ancestors 'none'") {
        throw 'The browser document is missing its anti-framing policy.'
    }

    $catalog = & $GetJson "$BaseUrl/api/catalog/items"
    if (@($catalog.items).Count -lt 1) { throw 'The catalog is empty.' }
    $products = @($catalog.items)
    for ($page = 2; $page -le $catalog.total_pages; $page++) {
        $nextPage = & $GetJson "$BaseUrl/api/catalog/items?page=$page"
        $products += @($nextPage.items)
    }
    foreach ($product in $products) {
        $image = & $GetWeb "$BaseUrl$($product.picture_uri)"
        if ($image.StatusCode -ne 200 -or $image.Headers['Content-Type'] -notmatch '^image/') {
            throw "Product image check failed: $($product.picture_uri)"
        }
    }

    $body = @{ email = 'demouser@perthai.com.au'; password = 'Pass@word1' } | ConvertTo-Json
    $auth = & $PostJson "$BaseUrl/api/auth/login" $body
    if (-not $auth.access_token) { throw 'Demo account login failed.' }

    $favouritesPage = & $GetWeb "$BaseUrl/favourites"
    if ($favouritesPage.StatusCode -ne 200) { throw 'The browser-facing Favourites route failed.' }
    $products.Count
}

function Invoke-WithWorkshopFrontendPaused {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][bool]$IsRunning,
        [Parameter(Mandatory)][scriptblock]$StopFrontend,
        [Parameter(Mandatory)][scriptblock]$Work,
        [Parameter(Mandatory)][scriptblock]$StartFrontend,
        [Parameter(Mandatory)][scriptblock]$WaitFrontend
    )

    if ($IsRunning) { & $StopFrontend }
    try {
        & $Work
    } finally {
        if ($IsRunning) {
            & $StartFrontend
            & $WaitFrontend
        }
    }
}

function Confirm-WorkshopServices {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateSet('start', 'reuse')][string]$BackendAction,
        [Parameter(Mandatory)][ValidateSet('start', 'reuse')][string]$FrontendAction,
        [Parameter(Mandatory)][scriptblock]$StartBackend,
        [Parameter(Mandatory)][scriptblock]$StartFrontend,
        [Parameter(Mandatory)][scriptblock]$WaitBackend,
        [Parameter(Mandatory)][scriptblock]$WaitFrontend
    )

    if ($BackendAction -eq 'start') { & $StartBackend }
    if ($FrontendAction -eq 'start') { & $StartFrontend }
    & $WaitBackend
    & $WaitFrontend
}

Export-ModuleMember -Function Find-WorkshopTool, Test-WorkshopProcessEvidence, Get-MattPocockSetupSkillPath, Get-WorkshopServiceAction, Invoke-WorkshopRuntimeChecks, Invoke-WithWorkshopFrontendPaused, Confirm-WorkshopServices
