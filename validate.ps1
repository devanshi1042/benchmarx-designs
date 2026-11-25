# validate.ps1 — simple structural + encoding sanity check for the 4 site files
$files = @('index.html','design-1-navy.html','design-2-white.html','design-3-dark.html')
$allOk = $true
foreach ($f in $files) {
    $p = Join-Path $PWD $f
    if (-not (Test-Path $p)) { Write-Host "MISSING: $f"; $allOk = $false; continue }
    $bytes = [IO.File]::ReadAllBytes($p)
    $text = [Text.Encoding]::UTF8.GetString($bytes)
    $hasDoctype = $text -match '<!DOCTYPE html>'
    $hasHtmlClose = $text -match '</html>'
    $utf16Bom = ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE)
    $size = $bytes.Length
    $lineCount = ($text -split "`n").Count
    $ok = $hasDoctype -and $hasHtmlClose -and -not $utf16Bom -and ($size -gt 1000)
    if (-not $ok) { $allOk = $false }
    Write-Host ("{0,-22} size={1,8} lines={2,5} doctype={3} htmlClose={4} utf16BOM={5} => {6}" -f $f,$size,$lineCount,$hasDoctype,$hasHtmlClose,$utf16Bom, ($(if($ok){'OK'}else{'FAIL'})))
}
# Also verify live URLs (network check, tolerate offline by reporting only)
$base = 'https://devanshi1042.github.io/benchmarx-designs'
Write-Host '--- live URL check ---'
foreach ($f in $files) {
    try {
        $r = Invoke-WebRequest "$base/$f" -UseBasicParsing -TimeoutSec 30
        Write-Host ("{0} {1}" -f $r.StatusCode, $f)
    } catch {
        Write-Host ("ERR  {0} ({1})" -f $f, $_.Exception.Message)
        $allOk = $false
    }
}
if ($allOk) { Write-Host 'ALL CHECKS PASSED'; exit 0 } else { Write-Host 'CHECKS FAILED'; exit 1 }
