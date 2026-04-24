$txtFile = "D:\temp\tfs_identities.txt"
$csvFile = "D:\temp\tfs_identities.csv"

$txtDir = Split-Path -Path $txtFile -Parent
$csvDir = Split-Path -Path $csvFile -Parent

if ($txtDir -and -not (Test-Path -LiteralPath $txtDir)) {
    New-Item -ItemType Directory -Path $txtDir -Force | Out-Null
}

if ($csvDir -and -not (Test-Path -LiteralPath $csvDir)) {
    New-Item -ItemType Directory -Path $csvDir -Force | Out-Null
}

cmd /c ('"./TFSConfig.exe" Identities > "{0}"' -f $txtFile)

# 读取并解析
$lines = Get-Content $txtFile

$result = foreach ($line in $lines) {
    $parts = $line -split '\s{2,}'
    if ($parts.Count -ge 3 -and $parts[1] -match '^(True|False)$' -and $parts[2] -match '^(True|False)$') {
        [PSCustomObject]@{
            Account = $parts[0].Trim()
            ExistsInWindows = $parts[1].Trim()
            Matched         = $parts[2].Trim()
        }
    }
}

# 导出 CSV
$result | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8

Write-Host "CSV generated: $csvFile"