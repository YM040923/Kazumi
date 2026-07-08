param(
  [string]$UpstreamRepo = "Predidit/Kazumi",
  [string]$UpstreamBranch = "main",
  [string]$BaseRef = "HEAD",
  [string]$Output = "upstream-sync-report.md",
  [int]$MaxCommits = 80
)

$ErrorActionPreference = "Stop"

function Run-Git {
  param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
  & git @Args
  if ($LASTEXITCODE -ne 0) {
    throw "git $($Args -join ' ') failed with exit code $LASTEXITCODE"
  }
}

function Add-ListSection {
  param(
    [System.Text.StringBuilder]$Builder,
    [string]$Title,
    [string[]]$Items,
    [string]$EmptyText = "None"
  )
  [void]$Builder.AppendLine("## $Title")
  [void]$Builder.AppendLine()
  if ($Items.Count -eq 0) {
    [void]$Builder.AppendLine($EmptyText)
  } else {
    foreach ($item in $Items) {
      [void]$Builder.AppendLine("- ``$item``")
    }
  }
  [void]$Builder.AppendLine()
}

$upstreamUrl = "https://github.com/$UpstreamRepo.git"
$upstreamRef = "refs/remotes/upstream-sync/$UpstreamBranch"

Run-Git fetch --no-tags $upstreamUrl "+refs/heads/$UpstreamBranch`:$upstreamRef" | Out-Null

$upstreamSha = (Run-Git rev-parse $upstreamRef).Trim()
$baseSha = (Run-Git rev-parse $BaseRef).Trim()

$mergeBase = ""
try {
  $mergeBase = (Run-Git merge-base $BaseRef $upstreamRef).Trim()
} catch {
  $mergeBase = ""
}

if ($mergeBase) {
  $commitRange = "$mergeBase..$upstreamRef"
  $diffRange = "$mergeBase..$upstreamRef"
  $historyNote = "A merge base was found: ``$mergeBase``."
  $changedFiles = @(Run-Git diff --name-only $diffRange | Sort-Object -Unique)
} else {
  $commitRange = $upstreamRef
  $historyNote = "No merge base was found. Treat this as a forensic/manual port, not a direct merge."
  $changedFiles = @(Run-Git log --name-only "--format=" "--max-count=$MaxCommits" $upstreamRef |
      Where-Object { $_ -and $_.Trim().Length -gt 0 } |
      Sort-Object -Unique)
}

$commits = @(Run-Git log --oneline "--max-count=$MaxCommits" $commitRange)

$uiPatterns = @(
  "^lib/pages/(popular|info|timeline|settings|search|collect|history|menu|my)/",
  "^lib/bean/(appbar|card|widget)/",
  "^lib/design/",
  "^assets/",
  "^windows/",
  "^macos/",
  "^linux/",
  "^android/app/src/main/res/"
)

$corePatterns = @(
  "^lib/plugins/",
  "^lib/webview/",
  "^lib/utils/",
  "^lib/modules/",
  "^lib/pages/player/",
  "^lib/pages/video/",
  "^pubspec.yaml$",
  "^pubspec.lock$"
)

$testPatterns = @(
  "^test/",
  "^.github/workflows/",
  "^analysis_options.yaml$"
)

$uiFiles = @()
$coreFiles = @()
$testFiles = @()
$otherFiles = @()

foreach ($file in $changedFiles) {
  if ($uiPatterns | Where-Object { $file -match $_ }) {
    $uiFiles += $file
  } elseif ($corePatterns | Where-Object { $file -match $_ }) {
    $coreFiles += $file
  } elseif ($testPatterns | Where-Object { $file -match $_ }) {
    $testFiles += $file
  } else {
    $otherFiles += $file
  }
}

$risk = "Low"
if ($uiFiles.Count -gt 0) {
  $risk = "High"
} elseif ($coreFiles.Count -gt 0) {
  $risk = "Medium"
}

$recommendation = switch ($risk) {
  "High" { "Do not auto-merge. Review and manually port core changes while preserving the UI redesign." }
  "Medium" { "Create a manual sync branch and port core/runtime changes first. Run full tests and a Windows build." }
  default { "Safe to review quickly. A small cherry-pick or patch may be enough." }
}

$builder = [System.Text.StringBuilder]::new()
[void]$builder.AppendLine("# Upstream Sync Report")
[void]$builder.AppendLine()
[void]$builder.AppendLine("- Upstream: ``$UpstreamRepo`` / ``$UpstreamBranch``")
[void]$builder.AppendLine("- Upstream SHA: ``$upstreamSha``")
[void]$builder.AppendLine("- Local base: ``$BaseRef`` / ``$baseSha``")
[void]$builder.AppendLine("- Risk: **$risk**")
[void]$builder.AppendLine("- Recommendation: $recommendation")
[void]$builder.AppendLine("- History: $historyNote")
[void]$builder.AppendLine()

Add-ListSection -Builder $builder -Title "Recent Upstream Commits" -Items $commits -EmptyText "No new commits detected."
Add-ListSection -Builder $builder -Title "High-Risk UI / Shell Files" -Items $uiFiles
Add-ListSection -Builder $builder -Title "Core / Runtime Files" -Items $coreFiles
Add-ListSection -Builder $builder -Title "Tests / CI Files" -Items $testFiles
Add-ListSection -Builder $builder -Title "Other Files" -Items $otherFiles

[void]$builder.AppendLine("## Suggested Next Step")
[void]$builder.AppendLine()
[void]$builder.AppendLine("Use this report to decide whether to skip, manually port only core changes, or open a dedicated upstream-sync branch. Avoid direct merge when risk is High.")

$report = $builder.ToString()
Set-Content -LiteralPath $Output -Value $report -Encoding UTF8
Write-Output $report
