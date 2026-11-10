Add-Type -AssemblyName System.Speech

Write-Host "=== INSTALLED SPEECH RECOGNIZERS ==="
$recognizers = [System.Speech.Recognition.SpeechRecognitionEngine]::InstalledRecognizers()
if ($recognizers.Count -eq 0) {
    Write-Host "No recognizers installed!"
} else {
    foreach ($r in $recognizers) {
        Write-Host "Culture: $($r.Culture.Name) ($($r.Culture.DisplayName))"
        Write-Host "Name:    $($r.Name)"
        Write-Host "Id:      $($r.Id)"
        Write-Host "Desc:    $($r.Description)"
        Write-Host "----------------------------------"
    }
}

Write-Host "`n=== SYSTEM DEFAULT CULTURE ==="
Write-Host "CurrentCulture:       $([System.Globalization.CultureInfo]::CurrentCulture.Name)"
Write-Host "CurrentUICulture:     $([System.Globalization.CultureInfo]::CurrentUICulture.Name)"
Write-Host "InstalledUICulture:   $([System.Globalization.CultureInfo]::InstalledUICulture.Name)"

Write-Host "`n=== DEFAULT SPEECH ENGINE TEST ==="
try {
    $engine = New-Object System.Speech.Recognition.SpeechRecognitionEngine
    Write-Host "Default Engine Recognizer: $($engine.RecognizerInfo.Name) ($($engine.RecognizerInfo.Culture.Name))"
    $engine.Dispose()
} catch {
    Write-Host "Error initializing default engine: $($_.Exception.Message)"
}
