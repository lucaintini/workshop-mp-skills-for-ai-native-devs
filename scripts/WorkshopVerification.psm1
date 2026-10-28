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

Export-ModuleMember -Function Find-WorkshopTool, Test-WorkshopProcessEvidence, Get-MattPocockSetupSkillPath
