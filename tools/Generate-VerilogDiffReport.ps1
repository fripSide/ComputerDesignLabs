param(
    [string]$BaseSc = "CODExp/demo/sccpu_sim/source",
    [string]$StudentSc = "student-sc",
    [string]$BasePl = "CODExp/demo/plcpu_sim/source",
    [string]$StudentPl = "student-pl",
    [string]$Out = "diff-report",
    [string[]]$Ext = @(".v"),
    [int]$Context = 3,
    [switch]$IncludeUnchanged
)

$ErrorActionPreference = "Stop"

function Resolve-InputPath([string]$PathText) {
    if ([System.IO.Path]::IsPathRooted($PathText)) {
        return $PathText
    }
    return (Join-Path (Get-Location) $PathText)
}

function Normalize-Extensions([string[]]$RawExts) {
    $result = New-Object System.Collections.Generic.List[string]
    foreach ($item in $RawExts) {
        if ([string]::IsNullOrWhiteSpace($item)) { continue }
        $ext = $item.Trim().ToLowerInvariant()
        if (-not $ext.StartsWith(".")) { $ext = ".$ext" }
        if (-not $result.Contains($ext)) { [void]$result.Add($ext) }
    }
    if ($result.Count -eq 0) { [void]$result.Add(".v") }
    return $result.ToArray()
}

function Read-TextLines([string]$PathText) {
    $bytes = [System.IO.File]::ReadAllBytes($PathText)
    $encodings = @(
        [System.Text.UTF8Encoding]::new($true, $true),
        [System.Text.UTF8Encoding]::new($false, $true),
        [System.Text.Encoding]::GetEncoding("gbk"),
        [System.Text.Encoding]::GetEncoding("iso-8859-1")
    )
    foreach ($encoding in $encodings) {
        try {
            $text = $encoding.GetString($bytes)
            $parts = @($text -split "`r`n|`n|`r", -1)
            if ($parts.Count -gt 0 -and $parts[$parts.Count - 1] -eq "") {
                if ($parts.Count -eq 1) { return @() }
                return @($parts[0..($parts.Count - 2)])
            }
            return $parts
        } catch {
            continue
        }
    }
    $fallbackParts = @([System.Text.Encoding]::GetEncoding("iso-8859-1").GetString($bytes) -split "`r`n|`n|`r", -1)
    if ($fallbackParts.Count -gt 0 -and $fallbackParts[$fallbackParts.Count - 1] -eq "") {
        if ($fallbackParts.Count -eq 1) { return @() }
        return @($fallbackParts[0..($fallbackParts.Count - 2)])
    }
    return $fallbackParts
}

function Get-SourceFiles([string]$Root, [string[]]$Extensions) {
    $map = @{}
    if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
        return $map
    }
    $rootInfo = Get-Item -LiteralPath $Root
    $rootPrefix = $rootInfo.FullName.TrimEnd("\", "/") + [System.IO.Path]::DirectorySeparatorChar
    Get-ChildItem -LiteralPath $Root -Recurse -File | ForEach-Object {
        $ext = $_.Extension.ToLowerInvariant()
        if ($Extensions -contains $ext) {
            $rel = $_.FullName.Substring($rootPrefix.Length).Replace("\", "/")
            $map[$rel] = $_.FullName
        }
    }
    return $map
}

function New-DiffRows([string[]]$OldLines, [string[]]$NewLines) {
    $m = $OldLines.Count
    $n = $NewLines.Count
    $lcs = New-Object 'int[,]' ($m + 1), ($n + 1)

    for ($i = $m - 1; $i -ge 0; $i--) {
        for ($j = $n - 1; $j -ge 0; $j--) {
            if ($OldLines[$i] -ceq $NewLines[$j]) {
                $lcs[$i, $j] = $lcs[($i + 1), ($j + 1)] + 1
            } elseif ($lcs[($i + 1), $j] -ge $lcs[$i, ($j + 1)]) {
                $lcs[$i, $j] = $lcs[($i + 1), $j]
            } else {
                $lcs[$i, $j] = $lcs[$i, ($j + 1)]
            }
        }
    }

    $rows = New-Object System.Collections.Generic.List[object]
    $oldNo = 1
    $newNo = 1
    $a = 0
    $b = 0
    while ($a -lt $m -and $b -lt $n) {
        if ($OldLines[$a] -ceq $NewLines[$b]) {
            [void]$rows.Add([pscustomobject]@{
                Kind = "context"; OldNo = $oldNo; NewNo = $newNo; Text = $OldLines[$a]
            })
            $a++; $b++; $oldNo++; $newNo++
        } elseif ($lcs[($a + 1), $b] -ge $lcs[$a, ($b + 1)]) {
            [void]$rows.Add([pscustomobject]@{
                Kind = "delete"; OldNo = $oldNo; NewNo = $null; Text = $OldLines[$a]
            })
            $a++; $oldNo++
        } else {
            [void]$rows.Add([pscustomobject]@{
                Kind = "insert"; OldNo = $null; NewNo = $newNo; Text = $NewLines[$b]
            })
            $b++; $newNo++
        }
    }
    while ($a -lt $m) {
        [void]$rows.Add([pscustomobject]@{
            Kind = "delete"; OldNo = $oldNo; NewNo = $null; Text = $OldLines[$a]
        })
        $a++; $oldNo++
    }
    while ($b -lt $n) {
        [void]$rows.Add([pscustomobject]@{
            Kind = "insert"; OldNo = $null; NewNo = $newNo; Text = $NewLines[$b]
        })
        $b++; $newNo++
    }
    return $rows
}

function Test-RowVisible($Rows, [int]$Index, [int]$ContextLines) {
    if ($Rows[$Index].Kind -ne "context") { return $true }
    $start = [Math]::Max(0, $Index - $ContextLines)
    $end = [Math]::Min($Rows.Count - 1, $Index + $ContextLines)
    for ($i = $start; $i -le $end; $i++) {
        if ($Rows[$i].Kind -ne "context") { return $true }
    }
    return $false
}

function ConvertTo-HtmlText([string]$Text) {
    return [System.Net.WebUtility]::HtmlEncode($Text)
}

function New-PatchText([string]$Name, [string]$RelPath, [object[]]$Rows) {
    $lines = New-Object System.Collections.Generic.List[string]
    $oldCount = @($Rows | Where-Object { $null -ne $_.OldNo }).Count
    $newCount = @($Rows | Where-Object { $null -ne $_.NewNo }).Count
    $oldStart = if ($oldCount -eq 0) { 0 } else { 1 }
    $newStart = if ($newCount -eq 0) { 0 } else { 1 }
    [void]$lines.Add("--- a/$Name/$RelPath")
    [void]$lines.Add("+++ b/$Name/$RelPath")
    [void]$lines.Add("@@ -$oldStart,$oldCount +$newStart,$newCount @@")
    foreach ($row in $Rows) {
        if ($row.Kind -eq "insert") {
            [void]$lines.Add("+" + $row.Text)
        } elseif ($row.Kind -eq "delete") {
            [void]$lines.Add("-" + $row.Text)
        } else {
            [void]$lines.Add(" " + $row.Text)
        }
    }
    return ($lines -join "`n")
}

function New-ComparisonDiffs([string]$Name, [string]$BaseDir, [string]$StudentDir, [string[]]$Extensions) {
    $warnings = New-Object System.Collections.Generic.List[string]
    if (-not (Test-Path -LiteralPath $BaseDir -PathType Container)) {
        [void]$warnings.Add("[$Name] base directory not found: $BaseDir")
    }
    if (-not (Test-Path -LiteralPath $StudentDir -PathType Container)) {
        [void]$warnings.Add("[$Name] student directory not found: $StudentDir")
    }
    if ($warnings.Count -gt 0) {
        return [pscustomobject]@{
            Diffs = New-Object System.Collections.Generic.List[object]
            Warnings = $warnings
        }
    }

    $baseFiles = Get-SourceFiles $BaseDir $Extensions
    $studentFiles = Get-SourceFiles $StudentDir $Extensions
    $relPaths = @($baseFiles.Keys + $studentFiles.Keys | Sort-Object -Unique)
    $diffs = New-Object System.Collections.Generic.List[object]

    foreach ($relPath in $relPaths) {
        $oldPath = $baseFiles[$relPath]
        $newPath = $studentFiles[$relPath]
        $oldLines = if ($oldPath) { Read-TextLines $oldPath } else { @() }
        $newLines = if ($newPath) { Read-TextLines $newPath } else { @() }
        $same = ($oldLines.Count -eq $newLines.Count)
        if ($same) {
            for ($i = 0; $i -lt $oldLines.Count; $i++) {
                if ($oldLines[$i] -cne $newLines[$i]) { $same = $false; break }
            }
        }
        if ($same -and -not $IncludeUnchanged) { continue }

        if ($oldPath -and -not $newPath) {
            $status = "deleted"
        } elseif ($newPath -and -not $oldPath) {
            $status = "added"
        } elseif ($same) {
            $status = "unchanged"
        } else {
            $status = "modified"
        }

        $rows = @(New-DiffRows $oldLines $newLines)
        $added = @($rows | Where-Object { $_.Kind -eq "insert" }).Count
        $deleted = @($rows | Where-Object { $_.Kind -eq "delete" }).Count
        $patch = if ($status -eq "unchanged") { "" } else { New-PatchText $Name $relPath $rows }
        [void]$diffs.Add([pscustomobject]@{
            Comparison = $Name
            RelPath = $relPath
            Status = $status
            Rows = $rows
            Added = $added
            Deleted = $deleted
            Patch = $patch
        })
    }
    return [pscustomobject]@{ Diffs = $diffs; Warnings = $warnings }
}

function Render-DiffRows($Rows, [int]$ContextLines) {
    $parts = New-Object System.Collections.Generic.List[string]
    $skipped = $false
    for ($i = 0; $i -lt $Rows.Count; $i++) {
        $row = $Rows[$i]
        if ($row.Kind -eq "context" -and -not (Test-RowVisible $Rows $i $ContextLines)) {
            if (-not $skipped) {
                [void]$parts.Add('<tr class="skip"><td></td><td></td><td class="code">...</td></tr>')
                $skipped = $true
            }
            continue
        }
        $skipped = $false
        $marker = if ($row.Kind -eq "insert") { "+" } elseif ($row.Kind -eq "delete") { "-" } else { " " }
        $oldNo = if ($null -eq $row.OldNo) { "" } else { [string]$row.OldNo }
        $newNo = if ($null -eq $row.NewNo) { "" } else { [string]$row.NewNo }
        $text = ConvertTo-HtmlText $row.Text
        [void]$parts.Add("<tr class=`"$($row.Kind)`"><td class=`"ln`">$oldNo</td><td class=`"ln`">$newNo</td><td class=`"code`"><span class=`"marker`">$marker</span>$text</td></tr>")
    }
    return ($parts -join "`n")
}

function Render-ReportHtml($Diffs, $Warnings, $Comparisons, [string]$OutputDir, [int]$ContextLines) {
    $generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $changedCount = @($Diffs | Where-Object { $_.Status -ne "unchanged" }).Count
    $totalAdded = (@($Diffs | ForEach-Object { $_.Added }) | Measure-Object -Sum).Sum
    $totalDeleted = (@($Diffs | ForEach-Object { $_.Deleted }) | Measure-Object -Sum).Sum
    if ($null -eq $totalAdded) { $totalAdded = 0 }
    if ($null -eq $totalDeleted) { $totalDeleted = 0 }

    $comparisonRows = ($Comparisons | ForEach-Object {
        "<li><strong>$(ConvertTo-HtmlText $_.Name)</strong>: $(ConvertTo-HtmlText $_.Base) -&gt; $(ConvertTo-HtmlText $_.Student)</li>"
    }) -join "`n"

    $warningHtml = ""
    if ($Warnings.Count -gt 0) {
        $items = ($Warnings | ForEach-Object { "<li>$(ConvertTo-HtmlText $_)</li>" }) -join "`n"
        $warningHtml = "<section class=`"warnings`"><h2>Warnings</h2><ul>$items</ul></section>"
    }

    $summaryParts = New-Object System.Collections.Generic.List[string]
    for ($i = 0; $i -lt $Diffs.Count; $i++) {
        $item = $Diffs[$i]
        [void]$summaryParts.Add("<a href=`"#file-$i`"><span class=`"status $($item.Status)`">$(ConvertTo-HtmlText $item.Status)</span>$(ConvertTo-HtmlText "$($item.Comparison)/$($item.RelPath)")<span class=`"numbers`">+$($item.Added) -$($item.Deleted)</span></a>")
    }
    $summary = if ($summaryParts.Count -gt 0) { $summaryParts -join "`n" } else { "<a>No matching changes found.</a>" }

    $fileParts = New-Object System.Collections.Generic.List[string]
    for ($i = 0; $i -lt $Diffs.Count; $i++) {
        $item = $Diffs[$i]
        $rows = Render-DiffRows $item.Rows $ContextLines
        [void]$fileParts.Add(@"
<section class="file" id="file-$i">
  <header>
    <div><span class="status $($item.Status)">$(ConvertTo-HtmlText $item.Status)</span> <strong>$(ConvertTo-HtmlText "$($item.Comparison)/$($item.RelPath)")</strong></div>
    <div class="numbers">+$($item.Added) -$($item.Deleted)</div>
  </header>
  <table><tbody>
$rows
  </tbody></table>
</section>
"@)
    }
    $filesHtml = $fileParts -join "`n"
    $patchPath = Join-Path $OutputDir "diff.patch"

    return @"
<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Verilog Diff Report</title>
  <style>
    :root { --border:#d0d7de; --text:#1f2328; --muted:#656d76; --bg:#f6f8fa; --add-bg:#dafbe1; --add-line:#aceebb; --del-bg:#ffebe9; --del-line:#ffcecb; }
    * { box-sizing:border-box; }
    body { margin:0; background:var(--bg); color:var(--text); font:14px/1.5 -apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif; }
    main { max-width:1180px; margin:0 auto; padding:24px; }
    h1 { margin:0 0 8px; font-size:26px; }
    h2 { margin:0 0 12px; font-size:18px; }
    .meta,.numbers { color:var(--muted); }
    .overview,.warnings,.summary,.file { background:#fff; border:1px solid var(--border); border-radius:8px; margin-top:16px; }
    .overview { padding:16px 18px; }
    .overview ul,.warnings ul { margin:8px 0 0; padding-left:22px; }
    .stats { display:flex; flex-wrap:wrap; gap:10px; margin-top:14px; }
    .stats span { border:1px solid var(--border); border-radius:999px; padding:4px 10px; background:#fff; }
    .warnings { padding:14px 18px; border-color:#d29922; background:#fff8c5; }
    .summary { overflow:hidden; }
    .summary a { display:flex; gap:10px; align-items:center; padding:10px 14px; border-top:1px solid var(--border); color:var(--text); text-decoration:none; font-family:ui-monospace,SFMono-Regular,Consolas,"Liberation Mono",monospace; }
    .summary a:first-child { border-top:0; }
    .summary a:hover { background:#f6f8fa; }
    .summary .numbers { margin-left:auto; }
    .status { display:inline-block; min-width:68px; border-radius:999px; padding:2px 8px; text-align:center; color:#fff; font:12px/1.5 -apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif; }
    .status.modified { background:#8250df; }
    .status.added { background:#1a7f37; }
    .status.deleted { background:#cf222e; }
    .status.unchanged { background:#57606a; }
    .file { overflow:hidden; }
    .file header { display:flex; align-items:center; justify-content:space-between; gap:16px; padding:10px 14px; border-bottom:1px solid var(--border); background:#fff; font-family:ui-monospace,SFMono-Regular,Consolas,"Liberation Mono",monospace; }
    table { width:100%; border-collapse:collapse; background:#fff; table-layout:fixed; }
    td { padding:0; vertical-align:top; font-family:ui-monospace,SFMono-Regular,Consolas,"Liberation Mono",monospace; font-size:12px; line-height:20px; white-space:pre-wrap; overflow-wrap:anywhere; }
    .ln { width:56px; color:var(--muted); text-align:right; padding:0 10px; border-right:1px solid var(--border); user-select:none; }
    .code { padding-left:10px; }
    .marker { display:inline-block; width:18px; color:var(--muted); }
    tr.insert td { background:var(--add-bg); }
    tr.insert .ln { background:var(--add-line); }
    tr.delete td { background:var(--del-bg); }
    tr.delete .ln { background:var(--del-line); }
    tr.skip td { background:#f6f8fa; color:var(--muted); }
    @media (max-width:760px) { main { padding:14px; } .file header,.summary a { align-items:flex-start; flex-direction:column; } .summary .numbers { margin-left:0; } .ln { width:42px; padding:0 6px; } }
  </style>
</head>
<body>
  <main>
    <h1>Verilog Diff Report</h1>
    <div class="meta">Generated at $(ConvertTo-HtmlText $generatedAt). Patch file: $(ConvertTo-HtmlText $patchPath)</div>
    <section class="overview">
      <h2>Comparisons</h2>
      <ul>$comparisonRows</ul>
      <div class="stats"><span>$changedCount changed files</span><span>+$totalAdded additions</span><span>-$totalDeleted deletions</span></div>
    </section>
    $warningHtml
    <nav class="summary">$summary</nav>
    $filesHtml
  </main>
</body>
</html>
"@
}

$extensions = Normalize-Extensions $Ext
$outDir = Resolve-InputPath $Out
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$comparisons = @(
    [pscustomobject]@{ Name = "single-cycle"; Base = $BaseSc; Student = $StudentSc },
    [pscustomobject]@{ Name = "pipeline"; Base = $BasePl; Student = $StudentPl }
)

$allDiffs = New-Object System.Collections.Generic.List[object]
$allWarnings = New-Object System.Collections.Generic.List[string]
foreach ($comparison in $comparisons) {
    $result = New-ComparisonDiffs `
        $comparison.Name `
        (Resolve-InputPath $comparison.Base) `
        (Resolve-InputPath $comparison.Student) `
        $extensions
    foreach ($diff in $result.Diffs) { [void]$allDiffs.Add($diff) }
    foreach ($warning in $result.Warnings) { [void]$allWarnings.Add($warning) }
}

$patchText = (($allDiffs | Where-Object { -not [string]::IsNullOrWhiteSpace($_.Patch) } | ForEach-Object { $_.Patch }) -join "`n`n")
$patchPath = Join-Path $outDir "diff.patch"
[System.IO.File]::WriteAllText($patchPath, $patchText, [System.Text.UTF8Encoding]::new($false))

$htmlText = Render-ReportHtml $allDiffs $allWarnings $comparisons $outDir $Context
$htmlPath = Join-Path $outDir "report.html"
[System.IO.File]::WriteAllText($htmlPath, $htmlText, [System.Text.UTF8Encoding]::new($false))

$changed = @($allDiffs | Where-Object { $_.Status -ne "unchanged" }).Count
$additions = (@($allDiffs | ForEach-Object { $_.Added }) | Measure-Object -Sum).Sum
$deletions = (@($allDiffs | ForEach-Object { $_.Deleted }) | Measure-Object -Sum).Sum
if ($null -eq $additions) { $additions = 0 }
if ($null -eq $deletions) { $deletions = 0 }

Write-Host "Compared extensions: $($extensions -join ', ')"
Write-Host "Changed files: $changed, additions: $additions, deletions: $deletions"
Write-Host "Wrote $patchPath"
Write-Host "Wrote $htmlPath"
if ($allWarnings.Count -gt 0) {
    Write-Host "Warnings:"
    foreach ($warning in $allWarnings) {
        Write-Host "  - $warning"
    }
}
