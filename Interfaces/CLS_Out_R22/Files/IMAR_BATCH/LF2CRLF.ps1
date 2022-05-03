param($FilePath,$DestFile)

(Get-Content -Raw -Path $FilePath) |% {$_.replace("`n", "`r`n")} | Set-Content -NoNewLine -Path $DestFile
