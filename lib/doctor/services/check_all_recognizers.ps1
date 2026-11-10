Write-Host "=== SAPI 5 RECOGNIZERS (System.Speech) ==="
Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Speech\Recognizers\Tokens" -ErrorAction SilentlyContinue | ForEach-Object {
    $name = (Get-ItemProperty -Path $_.PSPath)."(default)"
    $attr = Get-ItemProperty -Path "$($_.PSPath)\Attributes" -ErrorAction SilentlyContinue
    Write-Host "Key: $($_.PSChildName) | Name: $name | Language: $($attr.Language)"
}

Write-Host "`n=== ONECORE RECOGNIZERS (Windows 10/11 WinRT / Windows.Media.SpeechRecognition) ==="
Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Speech_OneCore\Recognizers\Tokens" -ErrorAction SilentlyContinue | ForEach-Object {
    $name = (Get-ItemProperty -Path $_.PSPath)."(default)"
    $attr = Get-ItemProperty -Path "$($_.PSPath)\Attributes" -ErrorAction SilentlyContinue
    Write-Host "Key: $($_.PSChildName) | Name: $name | Language: $($attr.Language)"
}
