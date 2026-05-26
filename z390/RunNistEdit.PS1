param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Nistdir,
    [Parameter(Mandatory = $true, Position = 1)]
    [string]$z390dir,
    [Parameter(Mandatory = $false, Position = 2)]
    [string]$LogFile = 'z390\#full_log.txt'
)

$content = Get-Content -LiteralPath $Nistdir\$LogFile -Raw -Encoding UTF8
$content = $content.Replace($Nistdir, "<z390development/nistcobol85>")
$content = $content.Replace($z390dir, "<z390development/z390>")
$content = [regex]::Replace($content, 'IO=\d+', 'IO=***')
$content = [regex]::Replace($content, 'FID= *\d+ ERR=', 'FID=*** ERR=')
Set-Content -LiteralPath $Nistdir\$LogFile -Value $content -Encoding UTF8 -NoNewline
