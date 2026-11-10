Add-Type -AssemblyName System.Speech

Write-Host "=== TEST ONECORE RECOGNIZER TOKEN LOADING ==="
try {
    # Check if we can construct SpeechRecognitionEngine with OneCore token ID
    $engine = New-Object System.Speech.Recognition.SpeechRecognitionEngine("MS-16393-110-WINMO-DNN")
    Write-Host "SUCCESS: OneCore en-IN DNN Loaded: $($engine.RecognizerInfo.Name)"
    $engine.Dispose()
} catch {
    Write-Host "Cannot load OneCore directly via token: $($_.Exception.Message)"
}
