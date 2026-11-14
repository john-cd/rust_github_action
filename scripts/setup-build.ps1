# TODO Reviewed ??-??-2026.

$ErrorActionPreference = 'Stop'
if (-not $IsWindows) { throw 'This setup task is for Windows checkouts.' }

$checkout = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$checkoutName = Split-Path -Leaf $checkout
$parent = Split-Path -Parent $checkout
$slot = if ((Split-Path -Leaf $parent) -eq '.worktrees') { $checkoutName } else { 'main' }
$mainRepo = if ($slot -eq 'main') { $checkout } else { Split-Path -Parent $parent }
if ($env:CODE_WORKTREE_SLOT) { $slot = $env:CODE_WORKTREE_SLOT }
if ($slot -notmatch '^(main|[a-z])$') { throw "Invalid checkout slot: $slot" }

$repoName = Split-Path -Leaf $mainRepo
$targetRoot = if ($env:CODE_TARGET_ROOT) { $env:CODE_TARGET_ROOT } else { 'D:\target' }
$buildRoot = if ($env:CODE_BUILD_ROOT) { $env:CODE_BUILD_ROOT } else { 'D:\code_build' }
$targetOutput = if ($env:CARGO_TARGET_DIR) { $env:CARGO_TARGET_DIR } elseif ($env:CARGO_BUILD_TARGET_DIR) { $env:CARGO_BUILD_TARGET_DIR } else { Join-Path (Join-Path $targetRoot $repoName) $slot }
$buildOutput = if ($env:CARGO_BUILD_BUILD_DIR) { $env:CARGO_BUILD_BUILD_DIR } else { Join-Path (Join-Path $buildRoot $repoName) $slot }
$outputs = [ordered]@{
    target = $targetOutput
    build = $buildOutput
}

$blocked = @()
foreach ($name in $outputs.Keys) {
    $link = Join-Path $checkout $name
    $destination = [IO.Path]::GetFullPath($outputs[$name])
    $existing = Get-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue
    if ($existing) {
        if (-not ($existing.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            Write-Warning "Preserving existing directory or file: $link"
            $blocked += $link
            continue
        }
        $resolved = $existing.ResolveLinkTarget($true)
        if (-not $resolved -or [IO.Path]::GetFullPath($resolved.FullName) -ine $destination) {
            throw "Preserving existing $link; expected a link to $destination."
        }
    } else {
        New-Item -ItemType Directory -Path $destination -Force | Out-Null
        New-Item -ItemType Junction -Path $link -Target $destination | Out-Null
    }
    Write-Host "$link -> $destination"
}
if ($blocked.Count -gt 0) {
    throw "Preserved local output path(s): $($blocked -join ', '). Use 'just cargo ...' to build in the central slot."
}
