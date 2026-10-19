# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does the M1 migration survive a power cut at every step, and does the app refuse a store it cannot trust (round 4, G5)?
# Date: 2026-10-19
# Tamper helper (run as cashier), one line of output:
#   -what flip -file <name> -offset <n> -count <k>   XOR k bytes with 0xFF at offset n (opened with ReadWrite sharing, so it
#                                                     works while the app holds the file); prints before/after SHA-256 prefix
#   -what key -kind wrong|truncated|empty            save key.bin to key.bin.orig (once) and write a bad key.bin
#   -what key -kind restore                          put key.bin.orig back
#   -what delete -file <name>                        try to delete the file; prints the result or the Windows error
#   -what hold -point <p> | -what nohold             write / remove hold.txt
param([string]$rt = 'a', [string]$what = '', [string]$file = 'store.db', [long]$offset = 0, [int]$count = 16, [string]$kind = '', [string]$point = '')
$d = Join-Path $env:LOCALAPPDATA "KodeeboSpike\$rt"
$p = Join-Path $d $file
function sha($x) { if (Test-Path -LiteralPath $x) { (Get-FileHash -LiteralPath $x -Algorithm SHA256).Hash.Substring(0,16) } else { 'absent' } }
switch ($what) {
  'flip' {
    $h0 = sha $p
    $fs = [IO.File]::Open($p, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::ReadWrite)
    try {
      $len = $fs.Length
      $buf = New-Object byte[] $count
      $fs.Position = $offset; $n = $fs.Read($buf, 0, $count)
      for ($i = 0; $i -lt $n; $i++) { $buf[$i] = $buf[$i] -bxor 0xFF }
      $fs.Position = $offset; $fs.Write($buf, 0, $n); $fs.Flush($true)
    } finally { $fs.Close() }
    "flip file=$file len=$len offset=$offset bytes=$n before=$h0 after=$(sha $p)"
  }
  'key' {
    $k = Join-Path $d 'key.bin'; $o = Join-Path $d 'key.bin.orig'
    if ($kind -eq 'restore') { Copy-Item -LiteralPath $o -Destination $k -Force; "key restored sha=$(sha $k)"; break }
    if (-not (Test-Path -LiteralPath $o)) { Copy-Item -LiteralPath $k -Destination $o }
    $orig = [IO.File]::ReadAllBytes($o)
    switch ($kind) {
      'wrong' { $b = New-Object byte[] 32; [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($b) }
      'truncated' { $b = $orig[0..15] }
      'empty' { $b = New-Object byte[] 0 }
    }
    [IO.File]::WriteAllBytes($k, [byte[]]$b)
    "key kind=$kind bytes=$($b.Length) sha=$(sha $k) orig=$(sha $o)"
  }
  'delete' {
    try { Remove-Item -LiteralPath $p -ErrorAction Stop; "delete file=$file result=deleted exists_after=$(Test-Path -LiteralPath $p)" }
    catch { "delete file=$file result=FAILED exists_after=$(Test-Path -LiteralPath $p) error=$($_.Exception.Message -replace '\s+', ' ')" }
  }
  'hold' { Set-Content -LiteralPath (Join-Path $d 'hold.txt') -Value $point -NoNewline; "hold=$point" }
  'nohold' { Remove-Item -LiteralPath (Join-Path $d 'hold.txt') -ErrorAction SilentlyContinue; 'hold removed' }
}
